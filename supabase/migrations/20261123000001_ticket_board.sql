-- Ticket board (SPEC: Post-v1 roadmap → Ticket board; D-098).
alter table public.tasks drop constraint tasks_status_check;
update public.tasks set status = 'in_progress' where status = 'doing';
alter table public.tasks add constraint tasks_status_check
  check (status in ('todo', 'in_progress', 'in_review', 'blocked', 'done'));
alter table public.tasks add column priority text not null default 'none'
  check (priority in ('urgent', 'high', 'medium', 'low', 'none'));
alter table public.tasks add column assignee_user_id uuid references auth.users (id) on delete set null;
alter table public.tasks add column due_at timestamptz;
alter table public.tasks add column labels text[] not null default '{}';
-- Order within a column (lower first).
alter table public.tasks add column position double precision not null default 0;
-- The ticket's work thread with its bot.
alter table public.tasks add column conversation_id uuid references public.conversations (id) on delete set null;
-- The bot finishes in review instead of done.
alter table public.tasks add column review_required boolean not null default false;
create index tasks_conversation_idx on public.tasks (conversation_id) where conversation_id is not null;

create table public.task_comments (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  task_id uuid not null references public.tasks (id) on delete cascade,
  author_type text not null check (author_type in ('user', 'bot')),
  author_user_id uuid references auth.users (id) on delete set null,
  author_bot_id uuid references public.bots (id) on delete set null,
  body_md text not null check (char_length(body_md) between 1 and 20000),
  created_at timestamptz not null default now()
);
create index task_comments_task_idx on public.task_comments (task_id, created_at);
alter table public.task_comments enable row level security;
create policy task_comments_select on public.task_comments for select to authenticated
  using (public.is_member(org_id));
create policy task_comments_insert on public.task_comments for insert to authenticated
  with check (public.is_member(org_id) and author_type = 'user' and author_user_id = (select auth.uid()));
create policy task_comments_delete on public.task_comments for delete to authenticated
  using (author_user_id = (select auth.uid()) or public.has_role(org_id, 'admin'));
select public.allow_worker('public.task_comments');
