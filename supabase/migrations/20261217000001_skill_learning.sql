-- Self-improving skills (SPEC: Post-v1 roadmap → Self-improving skills; D-126): a short digest of
-- every finished run (what was asked, tools and skills used, how it ended), skill proposals the
-- owner accepts or dismisses, and skill history.
create table public.run_digests (
  run_id uuid primary key references public.runs (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  task text not null,
  tools text[] not null default '{}',
  skills text[] not null default '{}',
  status text not null check (status in ('completed', 'failed', 'cancelled')),
  corrected boolean not null default false,
  correction text,
  embedding extensions.vector(1536),
  tsv tsvector generated always as (to_tsvector('simple', task)) stored,
  created_at timestamptz not null default now()
);
create index run_digests_bot_idx on public.run_digests (bot_id, created_at desc);

create table public.skill_proposals (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  kind text not null check (kind in ('new', 'edit')),
  skill_id uuid references public.skills (id) on delete cascade,
  name text not null check (name ~ '^[a-z0-9][a-z0-9_-]{0,62}$'),
  description text not null check (char_length(description) between 1 and 300),
  body_md text not null check (char_length(body_md) <= 50000),
  previous_body_md text,
  tools text[] not null default '{}',
  reason text not null default '',
  source_run_ids uuid[] not null default '{}',
  status text not null default 'pending' check (status in ('pending', 'accepted', 'dismissed', 'applied')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users (id) on delete set null
);
create index skill_proposals_pending_idx on public.skill_proposals (org_id, created_at desc) where status = 'pending';

create table public.skill_revisions (
  id uuid primary key default gen_random_uuid(),
  skill_id uuid not null references public.skills (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  description text not null,
  body_md text not null,
  changed_by_bot uuid,
  created_at timestamptz not null default now()
);
create index skill_revisions_skill_idx on public.skill_revisions (skill_id, created_at desc);

-- Every change to a skill's text keeps the version it replaced.
create function public.skill_revisions_keep() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if old.body_md is distinct from new.body_md or old.description is distinct from new.description then
    insert into public.skill_revisions (skill_id, org_id, description, body_md, changed_by_bot)
    values (old.id, old.org_id, old.description, old.body_md, new.updated_by_bot);
  end if;
  return new;
end $$;
create trigger skills_keep_revision before update on public.skills for each row execute function public.skill_revisions_keep();

alter table public.run_digests enable row level security;
alter table public.skill_proposals enable row level security;
alter table public.skill_revisions enable row level security;
create policy run_digests_select on public.run_digests for select to authenticated using (public.can_access_bot(bot_id));
create policy skill_proposals_select on public.skill_proposals for select to authenticated using (public.can_access_bot(bot_id));
create policy skill_revisions_select on public.skill_revisions for select to authenticated using (
  exists (select 1 from public.skills s where s.id = skill_id));
select public.allow_worker('public.run_digests');
select public.allow_worker('public.skill_proposals');
select public.allow_worker('public.skill_revisions');
