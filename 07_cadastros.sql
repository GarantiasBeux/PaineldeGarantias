-- =====================================================================
-- Garantias Beux – cadastro de peças e de clientes para a busca automática
-- (rodar UMA vez no SQL Editor, depois dos scripts 01 a 06)
-- O conteúdo das tabelas é carregado pelo próprio site (aba Cadastros).
-- =====================================================================

create extension if not exists pg_trgm;

create table if not exists public.pecas (
  cod_movere    text primary key,
  cod_fab       text,
  cod_original  text,
  descricao     text not null,
  aplicacao     text,
  marca         text,
  fornecedor    text,
  grupo         text,
  atualizado_em timestamptz not null default now()
);
create index if not exists pecas_desc_trgm on public.pecas using gin (descricao gin_trgm_ops);
create index if not exists pecas_fab_trgm  on public.pecas using gin (cod_fab gin_trgm_ops);

create table if not exists public.clientes (
  cod           text primary key,
  nome          text not null,
  fantasia      text,
  cnpj          text,
  cnpj_num      text generated always as (regexp_replace(coalesce(cnpj, ''), '\D', '', 'g')) stored,
  cidade        text,
  atualizado_em timestamptz not null default now()
);
create index if not exists clientes_nome_trgm on public.clientes using gin (nome gin_trgm_ops);
create index if not exists clientes_cnpj_idx  on public.clientes (cnpj_num);

alter table public.pecas    enable row level security;
alter table public.clientes enable row level security;

drop policy if exists pecas_ler on public.pecas;
create policy pecas_ler on public.pecas for select to authenticated using (true);
drop policy if exists pecas_admin on public.pecas;
create policy pecas_admin on public.pecas for all to authenticated
  using (public.eh_admin()) with check (public.eh_admin());

drop policy if exists clientes_ler on public.clientes;
create policy clientes_ler on public.clientes for select to authenticated using (true);
drop policy if exists clientes_admin on public.clientes;
create policy clientes_admin on public.clientes for all to authenticated
  using (public.eh_admin()) with check (public.eh_admin());

grant select, insert, update, delete on public.pecas, public.clientes to authenticated;

-- Já deixa cadastrados os clientes que vieram do site antigo de garantias
insert into public.clientes (cod, nome, cnpj)
select distinct on (cliente_cod) cliente_cod, cliente, cnpj
from public.garantias
where cliente_cod is not null and cliente_cod <> ''
order by cliente_cod, id desc
on conflict (cod) do nothing;
