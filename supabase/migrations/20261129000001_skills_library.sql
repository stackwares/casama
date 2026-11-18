-- Skills library (SPEC: Post-v1 roadmap → Skills library; D-104). Skills follow the open Agent
-- Skills format: SKILL.md (front matter + instructions) plus optional files, synced to
-- ~/skills/<name>/ on the computer when the skill loads.

-- Where a skill came from: written here, the bundled catalog, a GitHub folder (pinned to a
-- commit), or a bot (skills.create).
alter table public.skills add column source text not null default 'manual'
  check (source in ('manual', 'catalog', 'github', 'bot'));
-- catalog: {id}; github: {repo, path, ref, commit}
alter table public.skills add column source_ref jsonb not null default '{}'::jsonb;
alter table public.skills add column category text check (char_length(category) <= 40);
alter table public.skills add column updated_at timestamptz not null default now();
alter table public.skills add column updated_by_bot uuid references public.bots (id) on delete set null;

-- A skill's extra files (scripts, templates, references). Small by design: 1 MB a file, 5 MB a
-- skill, enforced by the API; they're copied to the computer, never run by the server.
create table public.skill_files (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  skill_id uuid not null references public.skills (id) on delete cascade,
  path text not null check (path ~ '^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$' and path !~ '(^|/)\.\.(/|$)' and char_length(path) <= 300),
  content bytea not null check (octet_length(content) <= 1048576),
  executable boolean not null default false,
  created_at timestamptz not null default now(),
  unique (skill_id, path)
);
create index skill_files_skill_idx on public.skill_files (skill_id);
alter table public.skill_files enable row level security;
create policy skill_files_select on public.skill_files for select to authenticated
  using (exists (select 1 from public.skills s where s.id = skill_id
                 and public.is_member(s.org_id) and (s.bot_id is null or public.can_access_bot(s.bot_id))));
create policy skill_files_write on public.skill_files for all to authenticated
  using (exists (select 1 from public.skills s where s.id = skill_id
                 and ((s.bot_id is null and public.has_role(s.org_id, 'admin')) or (s.bot_id is not null and public.can_manage_bot(s.bot_id)))))
  with check (exists (select 1 from public.skills s where s.id = skill_id and s.org_id = skill_files.org_id
                 and ((s.bot_id is null and public.has_role(s.org_id, 'admin')) or (s.bot_id is not null and public.can_manage_bot(s.bot_id)))));
select public.allow_worker('public.skill_files');
