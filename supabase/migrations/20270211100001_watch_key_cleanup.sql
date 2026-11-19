-- Watch and widget keys go with the membership (D-410 audit).
--
-- A watch key (and a widget key) belongs to one person in one workspace. Until now it outlived the
-- membership: while the person was out it answered 401, and when they were invited back it worked
-- again by itself, with no sign-in and no notice, possibly on a watch they no longer have. Leaving a
-- workspace, being removed from it or deleting the account now deletes that person's keys there.
-- They sign their watch and widgets in again after rejoining.
create or replace function public.memberships_drop_device_keys() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.watch_keys where org_id = old.org_id and user_id = old.user_id;
  delete from public.widget_keys where org_id = old.org_id and user_id = old.user_id;
  return null;
end $$;
revoke execute on function public.memberships_drop_device_keys() from public, anon, authenticated;

drop trigger if exists memberships_drop_device_keys on public.memberships;
create trigger memberships_drop_device_keys after delete on public.memberships
  for each row execute function public.memberships_drop_device_keys();

-- A watch key the server doesn't know is looked up among the codes waiting to be allowed (a watch
-- showing a code asks every few seconds): by fingerprint, among unclaimed ones.
create index if not exists watch_key_requests_key_hash_idx
  on public.watch_key_requests (key_hash) where claimed_at is null;
