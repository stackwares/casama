-- Team computer layout (SPEC: Ops extras; D-148): each bot works in its own folder on the team
-- computer (workspace/bots/<team_folder>, next to workspace/shared), and at most max_desktops bots
-- use the team computer's desktop at the same time (leases that expire unless renewed).
alter table public.computers add column max_desktops smallint not null default 1 check (max_desktops between 1 and 10);

alter table public.bots add column team_folder text check (team_folder ~ '^[a-z0-9][a-z0-9-]{0,47}$');
create unique index bots_team_folder_idx on public.bots (org_id, team_folder) where team_folder is not null;

create table public.computer_desktop_leases (
  computer_id uuid not null references public.computers (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  run_id uuid,
  expires_at timestamptz not null,
  primary key (computer_id, bot_id)
);
alter table public.computer_desktop_leases enable row level security;
create policy computer_desktop_leases_select on public.computer_desktop_leases for select to authenticated using (public.is_member(org_id));
select public.allow_worker('public.computer_desktop_leases');
