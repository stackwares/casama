-- Gallery v2 (D-315): usage counts, installed versions and updates, workspace controls, the
-- requests board, submissions, contributor rewards and the monthly picks email.
-- The API and the worker write these tables; clients read only their own workspace's rows.

-- Who uses each gallery item, aggregate only: a keyed hash per person and item, never a user id
-- or a workspace id. item_key is "<type>/<id>" (an extra catalog's ids are "<source>:<id>").
create table public.gallery_installs (
  item_key text not null check (char_length(item_key) between 3 and 140),
  user_hash text not null check (char_length(user_hash) = 64),
  first_at timestamptz not null default now(),
  last_used_at timestamptz not null default now(),
  primary key (item_key, user_hash)
);
create index gallery_installs_first_idx on public.gallery_installs (first_at);
create index gallery_installs_used_idx on public.gallery_installs (last_used_at);
alter table public.gallery_installs enable row level security;
select public.allow_worker('public.gallery_installs');

-- The hourly rollup of gallery_installs and the runs that used each item.
create table public.gallery_item_stats (
  item_key text primary key check (char_length(item_key) between 3 and 140),
  installers integer not null default 0,
  installers_7d integer not null default 0,
  active_14d integer not null default 0,
  runs_ok integer not null default 0,
  runs_total integer not null default 0,
  updated_at timestamptz not null default now()
);
alter table public.gallery_item_stats enable row level security;
select public.allow_worker('public.gallery_item_stats');

-- What a workspace added from the gallery and at which version, so it can see updates. One row
-- per thing made (a skill on a bot, a routine, a bot, an app connection, a plugin).
create table public.gallery_links (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  target_kind text not null check (target_kind in ('skill', 'bot', 'routine', 'app', 'plugin')),
  target_id text not null check (char_length(target_id) between 1 and 200),
  item_key text not null check (char_length(item_key) between 3 and 140),
  version integer not null default 1 check (version >= 1),
  -- What the installed version could touch, to tell an update that asks for more.
  access jsonb not null default '{}'::jsonb,
  -- Install answers, so an update fills the newer version the same way.
  inputs jsonb not null default '{}'::jsonb,
  installed_by uuid references auth.users (id) on delete set null,
  installed_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (org_id, target_kind, target_id)
);
create index gallery_links_item_idx on public.gallery_links (item_key);
create index gallery_links_org_idx on public.gallery_links (org_id, item_key);
alter table public.gallery_links enable row level security;
create policy gallery_links_select on public.gallery_links for select to authenticated
  using (public.is_member(org_id));
select public.allow_worker('public.gallery_links');

-- A workspace's gallery rules: open (default), approval, or allowlist; plus block and allow lists.
create table public.gallery_policies (
  org_id uuid primary key references public.organizations (id) on delete cascade,
  policy jsonb not null,
  updated_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.gallery_policies enable row level security;
create policy gallery_policies_select on public.gallery_policies for select to authenticated
  using (public.is_member(org_id));
select public.allow_worker('public.gallery_policies');

-- Gallery items a member asked to add where the workspace wants an admin to approve first.
create table public.gallery_approvals (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  requested_by uuid references auth.users (id) on delete set null,
  item_type text not null check (item_type in ('skill', 'bot', 'routine', 'app', 'plugin')),
  item_id text not null check (char_length(item_id) between 1 and 100),
  name text not null check (char_length(name) <= 120),
  inputs jsonb not null default '{}'::jsonb,
  bot_id uuid references public.bots (id) on delete set null,
  reason text not null check (char_length(reason) <= 200),
  status text not null default 'pending' check (status in ('pending', 'approved', 'denied', 'failed')),
  error text check (char_length(error) <= 500),
  decided_by uuid references auth.users (id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create index gallery_approvals_org_idx on public.gallery_approvals (org_id, status, created_at desc);
-- One waiting request per person and item.
create unique index gallery_approvals_once on public.gallery_approvals (org_id, requested_by, item_type, item_id)
  where status = 'pending';
alter table public.gallery_approvals enable row level security;
create policy gallery_approvals_select on public.gallery_approvals for select to authenticated
  using (requested_by = auth.uid() or public.has_role(org_id, 'admin'));
select public.allow_worker('public.gallery_approvals');

-- The requests board: what people want the gallery to have.
create table public.gallery_requests (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('theme', 'scheme', 'wallpaper', 'skill', 'app', 'bot', 'routine', 'plugin')),
  title text not null check (char_length(title) between 4 and 80),
  details text not null default '' check (char_length(details) <= 500),
  created_by uuid references auth.users (id) on delete set null,
  status text not null default 'open' check (status in ('open', 'planned', 'done', 'declined')),
  done_item_key text check (char_length(done_item_key) <= 140),
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);
create index gallery_requests_new_idx on public.gallery_requests (created_at desc) where not hidden;
create index gallery_requests_creator_idx on public.gallery_requests (created_by, created_at desc);
alter table public.gallery_requests enable row level security;
select public.allow_worker('public.gallery_requests');

create table public.gallery_request_votes (
  request_id uuid not null references public.gallery_requests (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (request_id, user_id)
);
create index gallery_request_votes_user_idx on public.gallery_request_votes (user_id);
alter table public.gallery_request_votes enable row level security;
select public.allow_worker('public.gallery_request_votes');

-- Items people submitted from the app; each one opens a pull request on the catalog repository.
create table public.gallery_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  item_key text not null check (char_length(item_key) between 3 and 140),
  name text not null check (char_length(name) <= 120),
  bytes integer not null default 0,
  pr_url text check (char_length(pr_url) <= 500),
  pr_number integer,
  status text not null default 'open' check (status in ('open', 'merged', 'closed', 'failed')),
  status_checked_at timestamptz,
  created_at timestamptz not null default now()
);
create index gallery_submissions_user_idx on public.gallery_submissions (user_id, created_at desc);
create index gallery_submissions_item_idx on public.gallery_submissions (item_key) where status = 'merged';
alter table public.gallery_submissions enable row level security;
select public.allow_worker('public.gallery_submissions');

-- Contributor rewards: credits once per item and milestone (active users), never twice.
create table public.gallery_rewards (
  item_key text not null check (char_length(item_key) between 3 and 140),
  milestone integer not null check (milestone > 0),
  user_id uuid references auth.users (id) on delete set null,
  org_id uuid references public.organizations (id) on delete set null,
  usd numeric(10, 2) not null default 0,
  granted_at timestamptz not null default now(),
  primary key (item_key, milestone)
);
alter table public.gallery_rewards enable row level security;
select public.allow_worker('public.gallery_rewards');

-- The monthly "New for you" gallery email: opt-in, off by default.
alter table public.profiles add column if not exists gallery_digest boolean not null default false;

-- Reports: requests on the board can be reported, and the nightly gallery check files its
-- findings as reports with reason health:<check> (no reporter).
alter table public.content_reports drop constraint content_reports_target_kind_check;
alter table public.content_reports add constraint content_reports_target_kind_check
  check (target_kind in ('gallery_item', 'gallery_request', 'bot', 'message', 'user', 'workspace'));
alter table public.content_reports drop constraint content_reports_reason_check;
alter table public.content_reports add constraint content_reports_reason_check
  check (reason in ('spam', 'sexual', 'violence', 'harassment', 'illegal', 'impersonation', 'other')
         or reason ~ '^health:[a-z_]{1,40}$');
-- One open health finding per item and check.
create unique index content_reports_health_once on public.content_reports (target_kind, target_id, reason)
  where status = 'open' and reporter_id is null and reason like 'health:%';
