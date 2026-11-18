-- Pages that take input (D-279, changing D-119 for pages that opt in): a page published with
-- collect = true may send form responses to its own origin. Responses are stored here, readable by
-- the page's person and the bot's managers, and can start a routine.
alter table public.pages add column if not exists collects boolean not null default false;
alter table public.pages add column if not exists submit_routine_id uuid references public.routines (id) on delete set null;

create table public.page_submissions (
  id uuid primary key default gen_random_uuid(),
  page_id uuid not null references public.pages (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  -- The signed-in viewer who sent it; null from a public link.
  submitted_by uuid references auth.users (id) on delete set null,
  data jsonb not null check (octet_length(data::text) <= 65536),
  created_at timestamptz not null default now()
);
create index page_submissions_page_idx on public.page_submissions (page_id, created_at desc);
alter table public.page_submissions enable row level security;
create policy page_submissions_select on public.page_submissions for select to authenticated using (
  exists (select 1 from public.pages p where p.id = page_id
          and (p.created_by = (select auth.uid()) or public.can_manage_bot(p.bot_id))));
select public.allow_worker('public.page_submissions');
