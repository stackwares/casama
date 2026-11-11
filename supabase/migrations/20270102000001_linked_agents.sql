-- Linked agents (SPEC: Linked agents; D-143): a person links their bot with a trusted contact's
-- bot. Both approve (one invites, the other accepts) and either can revoke. On the same server a
-- link is two rows pointing at each other; across Casama servers each side keeps one row and the
-- bots talk over A2A with per-link tokens.
create table public.bot_links (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  owner_user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  status text not null default 'pending' check (status in ('pending', 'active', 'revoked')),
  invite_code_hash text,
  invite_expires_at timestamptz,
  -- The other side: a row here (same server), or a bot on another Casama server.
  peer_link_id uuid,
  peer_bot_id text,
  peer_bot_name text,
  remote_url text check (remote_url is null or remote_url ~ '^https?://'),
  -- Tokens the other side presents to us (hash), and the one we present to them (Vault).
  inbound_token_hash text unique,
  outbound_secret_id uuid,
  created_at timestamptz not null default now(),
  activated_at timestamptz,
  revoked_at timestamptz
);
create index bot_links_bot_idx on public.bot_links (bot_id);
alter table public.bot_links enable row level security;
create policy bot_links_select on public.bot_links for select to authenticated using (owner_user_id = (select auth.uid()) or public.can_manage_bot(bot_id));
select public.allow_worker('public.bot_links');

create table public.link_exchanges (
  id uuid primary key default gen_random_uuid(),
  link_id uuid not null references public.bot_links (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  direction text not null check (direction in ('out', 'in')),
  request text not null,
  response text,
  status text not null default 'working' check (status in ('working', 'answered', 'failed')),
  run_id uuid references public.runs (id) on delete set null,
  created_at timestamptz not null default now(),
  answered_at timestamptz
);
create index link_exchanges_link_idx on public.link_exchanges (link_id, created_at desc);
alter table public.link_exchanges enable row level security;
create policy link_exchanges_select on public.link_exchanges for select to authenticated using (
  exists (select 1 from public.bot_links l where l.id = link_id and (l.owner_user_id = (select auth.uid()) or public.can_manage_bot(l.bot_id))));
select public.allow_worker('public.link_exchanges');
