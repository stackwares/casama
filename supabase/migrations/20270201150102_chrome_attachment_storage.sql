-- D-323 (Casama for Chrome, Phase 1 review): files a person sends with a message stay out of the
-- Library, but they are still stored, so they count toward the workspace's storage like Library
-- items. Without this, attachments could pile up past the plan's storage limit.
create or replace function public.chat_media_count_storage() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'DELETE' then
    if not old.in_library then
      update public.organizations set storage_bytes = greatest(0, storage_bytes - old.size) where id = old.org_id;
    end if;
    return null;
  end if;
  if not new.in_library then
    update public.organizations set storage_bytes = storage_bytes + new.size where id = new.org_id;
  end if;
  return null;
end $$;
revoke execute on function public.chat_media_count_storage() from public, anon, authenticated;

drop trigger if exists chat_media_storage on public.chat_media;
create trigger chat_media_storage after insert or delete on public.chat_media
  for each row execute function public.chat_media_count_storage();

-- No backfill: attachments outside the Library arrived with 20270201100901 in the same release, so
-- no deployed server has any yet (and the migration can be re-applied without counting twice).
