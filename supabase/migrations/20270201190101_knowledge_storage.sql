-- D-334: files uploaded to a knowledge source are stored (up to 100 MB per source), so they count
-- toward the workspace's storage limit (storage_gb) like Library items and chat attachments.
create or replace function public.knowledge_uploads_count_storage() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    update public.organizations set storage_bytes = greatest(0, storage_bytes - octet_length(old.content))
     where id = old.org_id;
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    update public.organizations set storage_bytes = storage_bytes + octet_length(new.content)
     where id = new.org_id;
  end if;
  return null;
end $$;
revoke execute on function public.knowledge_uploads_count_storage() from public, anon, authenticated;

-- The uploads already kept are counted once, when the trigger is first made, so the migration can
-- be applied again without counting them twice.
do $$
begin
  if not exists (select 1 from pg_trigger
                  where tgname = 'knowledge_uploads_storage' and tgrelid = 'public.knowledge_uploads'::regclass) then
    update public.organizations o set storage_bytes = o.storage_bytes + k.bytes
      from (select org_id, sum(octet_length(content))::bigint as bytes
              from public.knowledge_uploads group by org_id) k
     where o.id = k.org_id;
    create trigger knowledge_uploads_storage after insert or delete or update of content on public.knowledge_uploads
      for each row execute function public.knowledge_uploads_count_storage();
  end if;
end $$;
