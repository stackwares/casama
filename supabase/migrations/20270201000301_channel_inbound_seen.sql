-- Chat apps deliver a webhook again when the first delivery was slow or failed (Slack retries
-- after 3 s). Each message's provider id is kept for a week, so a repeat starts no second run
-- (D-270). Server only.
create table public.channel_inbound_seen (
  channel_id uuid not null references public.channels (id) on delete cascade,
  message_id text not null check (char_length(message_id) between 1 and 300),
  seen_at timestamptz not null default now(),
  primary key (channel_id, message_id)
);
create index channel_inbound_seen_at_idx on public.channel_inbound_seen (seen_at);
alter table public.channel_inbound_seen enable row level security;
select public.allow_worker('public.channel_inbound_seen');
