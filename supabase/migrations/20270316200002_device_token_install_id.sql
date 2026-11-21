-- A push or VoIP token moves to another account only from the same app install (D-474).
--
-- D-437's take_over_device_token lets the latest sign-in on a phone own its tokens: a row with
-- the same token that belongs to someone else is deleted before the insert. But anyone who knew
-- a token could register it and take it away from its owner: their pushes and call rings went to
-- the owner's phone, and the owner's own stopped. An app may now send `install_id`, a random id
-- kept for the life of the install, and a token whose row has one moves only to a row with the
-- same one. Rows from apps that don't send it keep D-437's behaviour, so a shared phone on an
-- older app still hands over.

alter table public.devices add column install_id text check (char_length(install_id) between 8 and 128);
alter table public.voip_tokens add column install_id text check (char_length(install_id) between 8 and 128);

create or replace function public.take_over_device_token()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Only for the person's own row: inserting for someone else still fails on RLS, and this
  -- mustn't remove anything on the way there. The worker (no auth.uid()) may move any token.
  if auth.uid() is not null and new.user_id is distinct from auth.uid() then
    return new;
  end if;
  -- A row that says which install it came from moves only to that same install; otherwise it
  -- stays, and the insert fails on the token's unique key.
  if tg_table_name = 'devices' then
    delete from public.devices where fcm_token = new.fcm_token and user_id <> new.user_id
      and (install_id is null or install_id = new.install_id);
  else
    delete from public.voip_tokens where token = new.token and user_id <> new.user_id
      and (install_id is null or install_id = new.install_id);
  end if;
  return new;
end;
$$;

revoke all on function public.take_over_device_token() from public, anon, authenticated;
