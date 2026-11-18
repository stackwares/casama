-- Production gaps (docs/GAPS-PLAN-2026-11.md): reports and blocks (D-301), account emails (D-302)
-- and the support ticket log (D-303). Only the API and the worker use these tables.

-- Reports from inside the app (gallery items, shared bots, other people's messages, people).
-- Public pages and chats keep their own creation_reports (D-281, D-282).
create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users (id) on delete set null,
  target_kind text not null check (target_kind in ('gallery_item', 'bot', 'message', 'user', 'workspace')),
  target_id text not null check (char_length(target_id) between 1 and 200),
  -- The workspace the content belongs to, when there is one (for suspending it).
  target_org_id uuid references public.organizations (id) on delete set null,
  reason text not null check (reason in ('spam', 'sexual', 'violence', 'harassment', 'illegal', 'impersonation', 'other')),
  note text check (char_length(note) <= 2000),
  -- What the reviewer saw: a short copy of the reported text, so a later edit or delete doesn't hide it.
  snapshot text check (char_length(snapshot) <= 4000),
  status text not null default 'open' check (status in ('open', 'actioned', 'dismissed')),
  reviewed_by uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
create index content_reports_open_idx on public.content_reports (status, created_at desc);
create index content_reports_target_idx on public.content_reports (target_kind, target_id);
-- One open report per person and thing.
create unique index content_reports_once on public.content_reports (reporter_id, target_kind, target_id)
  where status = 'open';
alter table public.content_reports enable row level security;
select public.allow_worker('public.content_reports');

-- People someone blocked: they can't invite the blocker to a workspace or link agents with them,
-- and their messages are hidden from the blocker in shared chats.
create table public.user_blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index user_blocks_blocked_idx on public.user_blocks (blocked_id);
alter table public.user_blocks enable row level security;
select public.allow_worker('public.user_blocks');

-- Account emails waiting to go out. Billing changes and the daily sweeps add rows; the worker
-- sends them. dedupe_key makes a retried webhook or sweep a no-op.
create table public.email_outbox (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (char_length(kind) between 1 and 60),
  -- Billing emails go to the workspace's owners and admins; personal ones to user_id.
  org_id uuid references public.organizations (id) on delete cascade,
  user_id uuid references auth.users (id) on delete cascade,
  dedupe_key text not null unique check (char_length(dedupe_key) <= 300),
  data jsonb not null default '{}'::jsonb,
  attempts integer not null default 0,
  last_error text,
  sent_at timestamptz,
  -- Skipped on purpose (no recipient, unsubscribed, email off on this server).
  skipped text,
  created_at timestamptz not null default now(),
  check (org_id is not null or user_id is not null)
);
create index email_outbox_pending_idx on public.email_outbox (created_at)
  where sent_at is null and skipped is null;
alter table public.email_outbox enable row level security;
select public.allow_worker('public.email_outbox');

-- Tips and product news by email (welcome series, nudges). Account emails ignore it.
alter table public.profiles add column if not exists email_tips boolean not null default true;

-- Messages sent to support from the app (D-298). The message itself stays in email.
create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique check (char_length(reference) <= 20),
  user_id uuid references auth.users (id) on delete set null,
  org_id uuid references public.organizations (id) on delete set null,
  topic text not null check (char_length(topic) <= 20),
  subject text not null check (char_length(subject) <= 120),
  status text not null default 'open' check (status in ('open', 'closed')),
  closed_at timestamptz,
  created_at timestamptz not null default now()
);
create index support_tickets_user_idx on public.support_tickets (user_id, created_at desc);
create index support_tickets_open_idx on public.support_tickets (status, created_at desc);
alter table public.support_tickets enable row level security;
select public.allow_worker('public.support_tickets');
