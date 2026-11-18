-- Casama for Chrome, Phase 1 (D-323; docs/CHROME-EXTENSION-PLAN.md §10).
--
-- 1. Pictures and files a person sends from the browser are kept in chat_media, so asking about
--    a screenshot doesn't wake the bot's computer. Message attachments stay out of the Library
--    (in_library false); things saved with "Save to Library" go in it, made for the person who
--    saved them.
alter table public.chat_media add column if not exists uploaded_by uuid references auth.users (id) on delete set null;
alter table public.chat_media add column if not exists in_library boolean not null default true;

create or replace function public.creations_from_media() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_for uuid;
begin
  if not new.in_library then
    return new;
  end if;
  select coalesce(new.uploaded_by, cv.created_by, r.created_by) into v_for
  from (select 1) one
  left join public.conversations cv on cv.id = new.conversation_id
  left join public.runs r on r.id = new.run_id;
  insert into public.creations (org_id, bot_id, made_for, conversation_id, run_id, kind, title,
                                media_id, mime, size, width, height, duration_s, created_at)
  values (new.org_id, (select id from public.bots where id = new.bot_id), v_for,
          (select id from public.conversations where id = new.conversation_id),
          (select id from public.runs where id = new.run_id),
          public.creation_kind(new.content_type),
          left(coalesce(nullif(regexp_replace(coalesce(new.name, ''), '\.[A-Za-z0-9]+$', ''), ''),
               case public.creation_kind(new.content_type) when 'video' then 'Video'
                    when 'audio' then 'Sound' else 'Picture' end), 200),
          new.id, new.content_type, new.size, new.width, new.height, new.duration_s, new.created_at)
  on conflict (media_id) do nothing;
  return new;
end $$;

-- 2. The extension is a push target of its own (FCM web tokens; data-only messages it draws
--    itself, with Approve and Deny buttons).
alter table public.devices drop constraint if exists devices_platform_check;
alter table public.devices add constraint devices_platform_check
  check (platform in ('ios', 'android', 'web', 'macos', 'windows', 'linux', 'chrome'));
