-- D-225: the bot list updates live on every device. A change to a workspace's bots (added, renamed,
-- archived, moved, deleted, or a status change while it works) broadcasts one small message on
-- the workspace's private topic; open apps refetch their list. The message names no bot, so a
-- member never learns about a private bot they can't see: the refetch goes through RLS as usual.

create or replace function public.realtime_topic_allowed(p_topic text)
returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_kind text := split_part(p_topic, ':', 1);
  v_id text := split_part(p_topic, ':', 2);
begin
  if v_id !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return false;
  end if;
  if v_kind = 'run' then return public.can_access_run(v_id::uuid); end if;
  if v_kind = 'bot' then return public.can_access_bot(v_id::uuid); end if;
  if v_kind = 'user' then return v_id::uuid = (select auth.uid()); end if;
  if v_kind = 'org' then return public.is_member(v_id::uuid); end if;
  return false;
end;
$$;

create or replace function public.broadcast_bots_changed()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  -- A write that changes nothing stays quiet.
  if tg_op = 'UPDATE' and new is not distinct from old then
    return null;
  end if;
  perform realtime.send(jsonb_build_object('kind', 'bots'), 'bots_changed', 'org:' || coalesce(new.org_id, old.org_id)::text, true);
  -- A bot moved to another workspace changes both lists.
  if tg_op = 'UPDATE' and new.org_id is distinct from old.org_id then
    perform realtime.send(jsonb_build_object('kind', 'bots'), 'bots_changed', 'org:' || old.org_id::text, true);
  end if;
  return null;
end;
$$;

drop trigger if exists bots_broadcast_changed on public.bots;
create trigger bots_broadcast_changed
  after insert or update or delete on public.bots
  for each row execute function public.broadcast_bots_changed();

revoke execute on function public.broadcast_bots_changed() from public, anon, authenticated;
