-- About you follow-ups (D-169).

-- --------------------------------------------------------------------------- per-person keys
-- About you belongs to a person, not a workspace, so it can't use a workspace key (D-136). Each
-- person gets their own data key, wrapped like workspace keys, while they belong to a workspace
-- that encrypts; the worker's sweep seals their About you with it, and opens it again and drops the
-- key when they no longer do. Account purge deletes the user, which deletes the key.
create table public.user_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  wrapped_key text not null,
  wrapper text not null,
  created_at timestamptz not null default now(),
  rotated_at timestamptz
);
alter table public.user_keys enable row level security;
-- No policies: only the API and the worker read keys.
select public.allow_worker('public.user_keys');

create or replace function public.user_keys_changed() returns trigger language plpgsql as $$
begin
  perform pg_notify('casama_org_keys', coalesce(new.user_id, old.user_id)::text);
  return null;
end;
$$;
create trigger user_keys_changed after insert or update or delete on public.user_keys
for each row execute function public.user_keys_changed();

-- Whether a person's About you should be sealed: they belong to a workspace that encrypts.
create or replace function public.user_seals_profile(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m join public.organizations o on o.id = m.org_id
    where m.user_id = p_user and o.content_encryption in ('encrypting', 'on'));
$$;
revoke execute on function public.user_seals_profile(uuid) from public, anon, authenticated;
grant execute on function public.user_seals_profile(uuid) to casama_worker;

-- Sealed text is longer than its plaintext: the length limits apply to plaintext only.
alter table public.user_about drop constraint user_about_about_check;
alter table public.user_about add constraint user_about_about_check
  check (char_length(about) <= 1500 or (about like 'enc:v1:%' and char_length(about) <= 9000));
alter table public.user_about drop constraint user_about_reply_style_check;
alter table public.user_about add constraint user_about_reply_style_check
  check (char_length(reply_style) <= 600 or (reply_style like 'enc:v1:%' and char_length(reply_style) <= 4000));
alter table public.user_facts drop constraint user_facts_content_check;
alter table public.user_facts add constraint user_facts_content_check
  check (char_length(content) between 1 and 500 or (content like 'enc:v1:%' and char_length(content) <= 3000));

-- --------------------------------------------------------------------------- existing people
-- People who signed up before the welcome chat asked for a name get one card asking it; answering
-- or dismissing it records this, on every device.
alter table public.user_about add column name_asked_at timestamptz;
-- Everyone who already went through the new welcome question (or set a name) is done.
insert into public.user_about (user_id, name_asked_at)
  select p.user_id, now() from public.profiles p where nullif(btrim(p.preferred_name), '') is not null
  on conflict (user_id) do update set name_asked_at = coalesce(public.user_about.name_asked_at, now());

-- Personal bots made by the welcome chat had the person's first name written into their
-- instructions; the name now comes from About you on every run.
update public.bots b
set persona_md = regexp_replace(b.persona_md, '^You are (.+?), .+?''s personal assistant\.', 'You are \1, this person''s personal assistant.')
where b.persona_md ~ '^You are .+?, .+?''s personal assistant\.'
  and b.persona_md !~ '^You are .+?, this person''s personal assistant\.'
  and exists (select 1 from public.conversations c where c.bot_id = b.id and c.welcome is not null);
