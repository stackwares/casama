-- Generated media out of Postgres (D-288, LIBRARY-PLAN Phase 5): new pictures, videos and sounds
-- go to the object store and keep only their key here; the worker moves the old ones a batch at a
-- time. Bytes whose row is deleted (by any path, cascades included) are queued for deletion.
alter table public.chat_media alter column bytes drop not null;
alter table public.chat_media add column if not exists blob_key text;
alter table public.chat_media add constraint chat_media_has_bytes check (bytes is not null or blob_key is not null);

create table public.deleted_blobs (
  key text primary key,
  deleted_at timestamptz not null default now()
);
alter table public.deleted_blobs enable row level security;
select public.allow_worker('public.deleted_blobs');

create function public.queue_deleted_blobs() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  r jsonb := to_jsonb(old);
begin
  insert into public.deleted_blobs (key)
  select k from unnest(array[r ->> 'blob_key', r ->> 'preview_key', r ->> 'cover_key']) k
  where k is not null
  on conflict do nothing;
  return old;
end $$;
create trigger chat_media_blobs after delete on public.chat_media for each row execute function public.queue_deleted_blobs();
create trigger creations_blobs after delete on public.creations for each row execute function public.queue_deleted_blobs();
create trigger creation_versions_blobs after delete on public.creation_versions for each row execute function public.queue_deleted_blobs();
create trigger page_assets_blobs after delete on public.page_assets for each row execute function public.queue_deleted_blobs();
