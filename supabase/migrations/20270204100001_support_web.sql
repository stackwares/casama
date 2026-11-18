-- Casama Help on the websites (D-401): questions the website assistant couldn't answer from the
-- docs, so the FAQ can grow. No identity is kept: no account, no address, no session, and the
-- API takes out anything that looks like an email, link or phone number before saving. Kept 90
-- days. Its usage counters live in public.support_usage under 'web:…' keys. Only the API uses it.
create table public.support_web_gaps (
  id bigint generated always as identity primary key,
  question text not null check (char_length(question) between 1 and 200),
  page text check (char_length(page) <= 120),
  created_at timestamptz not null default now()
);
create index support_web_gaps_created_idx on public.support_web_gaps (created_at desc);
alter table public.support_web_gaps enable row level security;
-- No policies for people. The worker's policy keeps the RLS check uniform.
select public.allow_worker('public.support_web_gaps');
