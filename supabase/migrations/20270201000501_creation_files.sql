-- The Library, Phase 3 (D-276): files a reply links to are kept off the bot's computer, so they
-- open while it sleeps or after it's reset. One creation per file (bot, computer, path); handing
-- the same file over again makes a new version, and the last five versions are kept.
create unique index creations_file_idx on public.creations (bot_id, computer_id, origin_path)
  where blob_key is not null;

create table public.creation_versions (
  creation_id uuid not null references public.creations (id) on delete cascade,
  version int not null,
  org_id uuid not null references public.organizations (id) on delete cascade,
  blob_key text not null,
  size bigint not null check (size >= 0),
  created_at timestamptz not null default now(),
  primary key (creation_id, version)
);
alter table public.creation_versions enable row level security;
create policy creation_versions_select on public.creation_versions for select to authenticated
  using (public.can_view_creation(creation_id));
select public.allow_worker('public.creation_versions');

-- Storage caps per plan (LIBRARY-PLAN §9): 1 / 10 / 50 / 200 GB. Self-hosted has none.
update public.plans set limits = limits || jsonb_build_object('storage_gb',
  case when code like 'plus%' then 10 when code like 'pro%' then 50 when code like 'max%' then 200 else 1 end)
where code <> 'selfhost';
