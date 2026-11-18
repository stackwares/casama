-- Projects (SPEC: Post-v1 roadmap → Projects; D-113). A goal with a plan, milestones, tickets,
-- budget and deadline. The lead bot plans, the owner approves, then the project heartbeat runs
-- sessions until the goal is met, the budget or deadline is reached, or someone pauses it.

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  slug text not null check (slug ~ '^[a-z0-9][a-z0-9-]{0,62}$'),
  title text not null check (char_length(title) between 1 and 200),
  goal_md text not null check (char_length(goal_md) between 1 and 20000),
  done_criteria_md text not null default '' check (char_length(done_criteria_md) <= 10000),
  status text not null default 'planning'
    check (status in ('planning', 'active', 'paused', 'blocked', 'done', 'cancelled')),
  -- draft: no plan yet; proposed: waiting for the owner; approved: work can run
  plan_status text not null default 'draft' check (plan_status in ('draft', 'proposed', 'approved')),
  status_reason text,
  lead_bot_id uuid not null references public.bots (id) on delete restrict,
  owner_user_id uuid references auth.users (id) on delete set null,
  conversation_id uuid references public.conversations (id) on delete set null,
  budget_usd numeric(10, 2) check (budget_usd is null or budget_usd > 0),
  deadline_at timestamptz,
  plan_md text not null default '',
  version integer not null default 1,
  sessions integer not null default 0,
  last_session_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, slug)
);
create index projects_active_idx on public.projects (status) where status = 'active';

create table public.project_milestones (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  project_id uuid not null references public.projects (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  position integer not null,
  requires_signoff boolean not null default false,
  status text not null default 'open' check (status in ('open', 'awaiting_signoff', 'done')),
  signed_off_by uuid references auth.users (id) on delete set null,
  signed_off_at timestamptz,
  unique (project_id, position)
);

alter table public.tasks add column project_id uuid references public.projects (id) on delete set null;
alter table public.tasks add column parent_task_id uuid references public.tasks (id) on delete set null;
alter table public.tasks add column milestone_id uuid references public.project_milestones (id) on delete set null;
create index tasks_project_idx on public.tasks (project_id, status);
alter table public.runs add column project_id uuid references public.projects (id) on delete set null;
create index runs_project_idx on public.runs (project_id, status);
alter table public.conversations add column project_id uuid references public.projects (id) on delete set null;
alter table public.routines add column project_id uuid references public.projects (id) on delete set null;

alter table public.projects enable row level security;
alter table public.project_milestones enable row level security;
-- Members see their workspace's projects; changes go through the API and the bots' tools.
create policy projects_select on public.projects for select to authenticated using (public.is_member(org_id));
create policy project_milestones_select on public.project_milestones for select to authenticated using (public.is_member(org_id));
select public.allow_worker('public.projects');
select public.allow_worker('public.project_milestones');
