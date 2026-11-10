-- Encryption at rest (SPEC: Encryption at rest; D-136). Off by default. When a workspace turns it
-- on, the server seals message content, run event payloads, memories, conversation summaries,
-- ticket details and comments, page content and knowledge passages with the workspace's data key
-- (AES-256-GCM) before writing; existing rows are sealed by the worker in the background.

alter table public.organizations add column content_encryption text not null default 'off'
  check (content_encryption in ('off', 'encrypting', 'on', 'decrypting'));

-- The workspace's data key, wrapped by the server key or AWS KMS. Deleting the workspace deletes it,
-- which makes its sealed rows unreadable. Rotation rewraps it; rows are not rewritten.
create table public.org_keys (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null unique references public.organizations (id) on delete cascade,
  wrapped_key text not null,
  wrapper text not null,
  created_at timestamptz not null default now(),
  rotated_at timestamptz
);
alter table public.org_keys enable row level security;
-- No policies: only the API and the worker read keys.
select public.allow_worker('public.org_keys');

-- Every server process reloads its key ring when keys or modes change.
create or replace function public.org_keys_changed() returns trigger language plpgsql as $$
begin
  perform pg_notify('kasama_org_keys', coalesce(new.org_id, old.org_id)::text);
  return null;
end;
$$;
create trigger org_keys_changed after insert or update or delete on public.org_keys
for each row execute function public.org_keys_changed();
create or replace function public.org_encryption_changed() returns trigger language plpgsql as $$
begin
  if new.content_encryption is distinct from old.content_encryption then
    perform pg_notify('kasama_org_keys', new.id::text);
  end if;
  return null;
end;
$$;
create trigger org_encryption_changed after update of content_encryption on public.organizations
for each row execute function public.org_encryption_changed();

-- Sealed text is longer than its plaintext: the length limits apply to plaintext only.
alter table public.memories drop constraint memories_content_check;
alter table public.memories add constraint memories_content_check
  check (char_length(content) between 1 and 8000 or (content like 'enc:v1:%' and char_length(content) <= 12000));
alter table public.task_comments drop constraint task_comments_body_md_check;
alter table public.task_comments add constraint task_comments_body_md_check
  check (char_length(body_md) between 1 and 20000 or (body_md like 'enc:v1:%' and char_length(body_md) <= 28000));
alter table public.pages drop constraint pages_html_check;
alter table public.pages add constraint pages_html_check
  check (octet_length(html) <= 2000000 or (html like 'enc:v1:%' and octet_length(html) <= 2800000));
alter table public.pages drop constraint pages_data_check;
alter table public.pages add constraint pages_data_check
  check (octet_length(data::text) <= 1000000 or (data ? '$enc' and octet_length(data::text) <= 1400000));
alter table public.knowledge_chunks drop constraint knowledge_chunks_text_check;
alter table public.knowledge_chunks add constraint knowledge_chunks_text_check
  check (char_length(text) between 1 and 8000 or (text like 'enc:v1:%' and char_length(text) <= 12000));

-- Realtime carries only ids for sealed events; the app fetches them from the API.
create or replace function public.run_events_broadcast()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_sealed boolean := jsonb_typeof(new.payload) = 'object' and new.payload ? '$enc';
  v_msg jsonb := jsonb_build_object(
    'v', 1, 'run_id', new.run_id, 'seq', new.seq, 'ts', to_char(new.created_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'bot_id', new.bot_id, 'type', new.type);
begin
  v_msg := case when v_sealed then v_msg || '{"sealed": true}'::jsonb else v_msg || jsonb_build_object('payload', new.payload) end;
  perform realtime.send(v_msg, 'run_event', 'run:' || new.run_id::text, true);
  perform realtime.send(v_msg, 'run_event', 'bot:' || new.bot_id::text, true);
  perform pg_notify('kasama_run_events', new.run_id::text || ':' || new.seq::text);
  return null;
end;
$$;

-- Only the API changes the mode (it creates the key first); app sessions can't.
create or replace function public.org_encryption_guard() returns trigger language plpgsql as $$
begin
  if new.content_encryption is distinct from old.content_encryption and current_user in ('authenticated', 'anon') then
    raise exception 'content_encryption is changed through the API' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger org_encryption_guard before update of content_encryption on public.organizations
for each row execute function public.org_encryption_guard();
