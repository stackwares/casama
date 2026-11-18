-- Help & support (D-298): what each person, address and the whole server used of the free support
-- assistant today, so its limits hold across restarts and deploys. Keys: 'u:<user id>',
-- 'ip:<hashed address>' and 'all'. Only the API reads and writes it.
create table public.support_usage (
  key text not null check (char_length(key) <= 80),
  day date not null default current_date,
  messages integer not null default 0,
  tickets integer not null default 0,
  usd numeric(12, 6) not null default 0,
  -- Requests that weren't about Casama; enough of them in a day pause the assistant for that person.
  strikes integer not null default 0,
  blocked_until timestamptz,
  updated_at timestamptz not null default now(),
  primary key (key, day)
);
create index support_usage_day_idx on public.support_usage (day);
alter table public.support_usage enable row level security;
-- No policies for people: only the API uses it. The worker's policy keeps the RLS check uniform.
select public.allow_worker('public.support_usage');
