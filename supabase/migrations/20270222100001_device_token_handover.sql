-- A phone's push and VoIP tokens follow whoever signed in on it last (D-437).
--
-- Both tables key on the token. When someone signed out and another account signed in on the
-- same phone, the app's upsert hit the old account's row, which RLS hides from the new account,
-- so it failed: the new account never got pushes or call rings on that phone, and the old one
-- kept getting them there. Before the insert, a token registered by someone else now leaves
-- them, so the upsert inserts a fresh row for the person signing in. Shipped apps need no change.

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
  if tg_table_name = 'devices' then
    delete from public.devices where fcm_token = new.fcm_token and user_id <> new.user_id;
  else
    delete from public.voip_tokens where token = new.token and user_id <> new.user_id;
  end if;
  return new;
end;
$$;

revoke all on function public.take_over_device_token() from public, anon, authenticated;

create trigger devices_take_over_token
  before insert on public.devices
  for each row execute function public.take_over_device_token();

create trigger voip_tokens_take_over_token
  before insert on public.voip_tokens
  for each row execute function public.take_over_device_token();
