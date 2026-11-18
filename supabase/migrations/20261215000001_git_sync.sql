-- Routines and skills as files (SPEC: Post-v1 roadmap → Routines and skills as files; D-124): optional
-- git sync per workspace. Changes to routines and skills mark the workspace for the worker's
-- next sync; a push to the repo (webhook) does the same.
create table public.org_git_sync (
  org_id uuid primary key references public.organizations (id) on delete cascade,
  repo text not null check (repo ~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'),
  branch text not null default 'main' check (char_length(branch) between 1 and 200),
  path text not null default '' check (char_length(path) <= 200),
  enabled boolean not null default true,
  webhook_secret_id uuid,
  -- path → {git: blob sha, hash: sha-256 of the content} at the last sync
  synced jsonb not null default '{}'::jsonb,
  last_commit text,
  dirty_at timestamptz not null default now(),
  checked_at timestamptz,
  last_synced_at timestamptz,
  last_error text,
  open_pr_url text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
alter table public.org_git_sync enable row level security;
create policy org_git_sync_select on public.org_git_sync for select to authenticated using (public.has_role(org_id, 'admin'));
select public.allow_worker('public.org_git_sync');

create function public.git_sync_mark_dirty() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.org_git_sync set dirty_at = now()
  where org_id in (select distinct org_id from changed) and enabled;
  return null;
end $$;
create trigger routines_git_sync_ins after insert on public.routines referencing new table as changed for each statement execute function public.git_sync_mark_dirty();
create trigger routines_git_sync_upd after update on public.routines referencing new table as changed for each statement execute function public.git_sync_mark_dirty();
create trigger routines_git_sync_del after delete on public.routines referencing old table as changed for each statement execute function public.git_sync_mark_dirty();
create trigger skills_git_sync_ins after insert on public.skills referencing new table as changed for each statement execute function public.git_sync_mark_dirty();
create trigger skills_git_sync_upd after update on public.skills referencing new table as changed for each statement execute function public.git_sync_mark_dirty();
create trigger skills_git_sync_del after delete on public.skills referencing old table as changed for each statement execute function public.git_sync_mark_dirty();
create trigger skill_files_git_sync_ins after insert on public.skill_files referencing new table as changed for each statement execute function public.git_sync_mark_dirty();
create trigger skill_files_git_sync_del after delete on public.skill_files referencing old table as changed for each statement execute function public.git_sync_mark_dirty();
