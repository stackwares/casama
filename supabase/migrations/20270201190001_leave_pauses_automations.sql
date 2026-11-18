-- D-334: leaving a workspace stops that person's automations there. When a membership goes (they
-- leave, an admin removes them, or their account is deleted), the routines they made in that
-- workspace are switched off and their watchers paused. Nothing is deleted, so turning them back on
-- after rejoining restores them. The worker also skips any routine or watcher whose creator is no
-- longer a member when it would fire (apps/server/src/worker/routines.ts, packages/agent/src/watchers.ts).
create or replace function public.memberships_pause_automations() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  -- A workspace being deleted takes its routines and watchers with it.
  if not exists (select 1 from public.organizations where id = old.org_id) then
    return null;
  end if;
  update public.routines set enabled = false
   where org_id = old.org_id and created_by = old.user_id and enabled;
  update public.watchers set status = 'paused'
   where org_id = old.org_id and created_by = old.user_id and status = 'active';
  return null;
end $$;
revoke execute on function public.memberships_pause_automations() from public, anon, authenticated;

drop trigger if exists memberships_pause_automations on public.memberships;
create trigger memberships_pause_automations after delete on public.memberships
  for each row execute function public.memberships_pause_automations();
