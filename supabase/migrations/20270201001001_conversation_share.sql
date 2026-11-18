-- A public read-only link to a chat (D-282): its starter or the bot's managers make one; a
-- private chat (personal device data, D-091) can't have one.
alter table public.conversations add column if not exists public_token_hash text unique;
alter table public.conversations add column if not exists shared_at timestamptz;
