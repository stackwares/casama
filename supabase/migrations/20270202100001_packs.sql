-- Packs (docs/PLUGINS-AND-PACKS-PLAN.md): a plugin with a com.casama/ folder that brings bots,
-- skills, routines, apps and looks to a workspace. One row per installed pack; what it made is in
-- pack_items (with a hash, to tell later whether the person edited it); its files are stored so
-- diffs and removal never need the source again. A pack's tools go through the existing per-bot
-- plugin rows, which point back here.

create table public.packs (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  name text not null check (name ~ '^(?!.*(?:--|\.\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$' and char_length(name) <= 64),
  version text check (char_length(version) <= 64),
  description text not null default '' check (char_length(description) <= 2000),
  summary text not null default '' check (char_length(summary) <= 200),
  icon text not null default 'package' check (char_length(icon) <= 40),
  -- {kind: github|gallery|share|upload, owner?, repo?, path?, ref?, url?, gallery_id?}
  source jsonb not null,
  commit_sha text check (commit_sha ~ '^[0-9a-f]{40}$'),
  -- Listed in the reviewed directory at this commit.
  reviewed boolean not null default false,
  -- The checked pack as installed: the document, its items and a snapshot for diffs.
  content jsonb not null default '{}'::jsonb,
  -- The install answers, so an update fills the newer version the same way.
  inputs jsonb not null default '{}'::jsonb,
  installed_by uuid references auth.users (id) on delete set null,
  installed_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, name)
);
create index packs_org_idx on public.packs (org_id);

create table public.pack_files (
  pack_id uuid not null references public.packs (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  path text not null check (char_length(path) between 1 and 500),
  content bytea not null check (octet_length(content) <= 5000000),
  executable boolean not null default false,
  primary key (pack_id, path)
);

-- One row per thing a pack made. item_id is the pack's own id (a bot's file name, a skill's
-- folder, a look's type/id); target_id is the row it became. Removing a pack detaches what the
-- person changed (pack_id set null) and deletes the rest.
create table public.pack_items (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid references public.packs (id) on delete set null,
  org_id uuid not null references public.organizations (id) on delete cascade,
  kind text not null check (kind in ('bot', 'skill', 'routine', 'app', 'look', 'include')),
  item_id text not null check (char_length(item_id) between 1 and 200),
  target_id text check (char_length(target_id) <= 200),
  bot_id uuid references public.bots (id) on delete cascade,
  -- What the person could edit, hashed at install (packItemHash) to tell an edit later.
  content_hash text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index pack_items_pack_idx on public.pack_items (pack_id);
create index pack_items_org_idx on public.pack_items (org_id);
create unique index pack_items_target_idx on public.pack_items (pack_id, kind, item_id, coalesce(bot_id, '00000000-0000-0000-0000-000000000000'::uuid));

alter table public.plugins add column pack_id uuid references public.packs (id) on delete cascade;
create index plugins_pack_idx on public.plugins (pack_id) where pack_id is not null;

-- Share as pack: a stored pack behind a hashed token, like bot shares (D-110).
create table public.pack_shares (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  token_hash text not null unique check (char_length(token_hash) = 64),
  name text not null check (char_length(name) between 1 and 64),
  summary text not null default '' check (char_length(summary) <= 200),
  -- [{path, base64, executable}]
  files jsonb not null,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  taken_down_at timestamptz
);
create index pack_shares_org_idx on public.pack_shares (org_id);

alter table public.packs enable row level security;
alter table public.pack_files enable row level security;
alter table public.pack_items enable row level security;
alter table public.pack_shares enable row level security;
create policy packs_select on public.packs for select to authenticated using (public.is_member(org_id));
create policy pack_files_select on public.pack_files for select to authenticated using (public.is_member(org_id));
create policy pack_items_select on public.pack_items for select to authenticated using (public.is_member(org_id));
-- Shares are read through the API (signed-in viewers in any workspace); members see their own.
create policy pack_shares_select on public.pack_shares for select to authenticated using (public.is_member(org_id));
select public.allow_worker('public.packs');
select public.allow_worker('public.pack_files');
select public.allow_worker('public.pack_items');
select public.allow_worker('public.pack_shares');

-- Reports can name a shared pack (D-301): taking it down ends the link.
alter table public.content_reports drop constraint content_reports_target_kind_check;
alter table public.content_reports add constraint content_reports_target_kind_check
  check (target_kind in ('gallery_item', 'gallery_request', 'pack_share', 'bot', 'message', 'user', 'workspace'));

-- A pack can wait for an admin like any gallery item; the whole request is kept in inputs.
alter table public.gallery_approvals drop constraint gallery_approvals_item_type_check;
alter table public.gallery_approvals add constraint gallery_approvals_item_type_check
  check (item_type in ('skill', 'bot', 'routine', 'app', 'plugin', 'pack'));
