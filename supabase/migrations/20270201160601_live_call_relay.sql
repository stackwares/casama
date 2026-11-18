-- Billing audit 2026-11-17 (D-333): live calls paid from credits go through the server.
--
-- The app talked to Gemini Live directly and reported the call's token counts itself, so a
-- modified app could under-report and pay only the listening-rate floor. A billable call's
-- connect_url now points at the server's relay (/v1/voice/live/<call>/relay), which holds the
-- Gemini token, passes frames both ways unchanged and counts Gemini's own usageMetadata. The app
-- gets a relay secret instead of the Gemini token, so it can't go around the relay.
--
-- One row per relayed call: the secret's SHA-256, the provider's address and token (sealed with
-- the workspace's content key), and the usage the relay has seen. Server only.

create table if not exists public.live_call_relays (
  live_call_id uuid primary key references public.live_calls (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  secret_hash text not null,
  provider_url text not null,
  provider_token jsonb not null,
  usage jsonb not null default '{"input_audio_tokens":0,"input_text_tokens":0,"output_audio_tokens":0,"output_text_tokens":0}'::jsonb,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index if not exists live_call_relays_org_idx on public.live_call_relays (org_id);
alter table public.live_call_relays enable row level security;
revoke all on public.live_call_relays from anon, authenticated;
select public.allow_worker('public.live_call_relays');
