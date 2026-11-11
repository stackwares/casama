-- Google and Apple put a person's name in user metadata (full_name, name, or given and family),
-- not in display_name. Profiles used to keep only display_name, so those accounts showed the
-- bit before the @. Apple's system sheet sends the name only on the first authorization, and
-- only to the app, which then saves it onto the user. This fills the profile from that metadata
-- when the profile still has the automatic email fallback, and leaves a name someone set as it is.

create or replace function public.profile_display_name(meta jsonb, email text)
returns text
language sql
immutable
set search_path = ''
as $$
  select left(coalesce(
    nullif(btrim(meta ->> 'display_name'), ''),
    nullif(btrim(meta ->> 'full_name'), ''),
    nullif(btrim(meta ->> 'name'), ''),
    nullif(btrim(concat_ws(' ', nullif(btrim(meta ->> 'given_name'), ''), nullif(btrim(meta ->> 'family_name'), ''))), ''),
    nullif(split_part(coalesce(email, ''), '@', 1), ''),
    ''
  ), 120);
$$;
revoke all on function public.profile_display_name(jsonb, text) from public, anon, authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, public.profile_display_name(new.raw_user_meta_data, new.email::text))
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- After the first Apple sign-in the app writes the name onto the user. Copy it onto the profile
-- while the profile is still the email fallback.
create or replace function public.sync_profile_name_from_auth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chosen text;
  fallback text;
begin
  chosen := public.profile_display_name(new.raw_user_meta_data, new.email::text);
  fallback := split_part(coalesce(new.email::text, ''), '@', 1);
  update public.profiles
  set display_name = chosen
  where user_id = new.id
    and display_name is not distinct from fallback
    and chosen is distinct from display_name;
  return new;
end;
$$;
revoke all on function public.sync_profile_name_from_auth() from public, anon, authenticated;

drop trigger if exists on_auth_user_name on auth.users;
create trigger on_auth_user_name
after update of raw_user_meta_data on auth.users
for each row execute function public.sync_profile_name_from_auth();

-- Accounts that already signed in with Google (or Apple on the web) keep the email fallback.
update public.profiles p
set display_name = chosen.name
from auth.users u
cross join lateral (select public.profile_display_name(u.raw_user_meta_data, u.email::text) as name) chosen
where u.id = p.user_id
  and p.display_name is not distinct from split_part(coalesce(u.email::text, ''), '@', 1)
  and chosen.name is distinct from p.display_name;
