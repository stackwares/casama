-- Light projects (D-295): a project is the home for one piece of work. It needs only a name and a
-- bot; planning for approval, milestones, budget and the heartbeat (D-113) are a mode switched on
-- per project (`autonomous`). What a bot makes in a project's chat, or in a run that works on it,
-- is filed under it in the Library (`creations.project_id`).

alter table public.projects
  add column autonomous boolean not null default false,
  -- Grew out of a person's own chat: seen by them and by whoever can open its chat.
  add column personal boolean not null default false;
-- Every project made before this one plans, waits for approval and runs by itself.
update public.projects set autonomous = true;

-- A light project has no goal yet; one that works by itself still needs one.
alter table public.projects drop constraint if exists projects_goal_md_check;
alter table public.projects alter column goal_md set default '';
alter table public.projects add constraint projects_goal_md_check check (char_length(goal_md) <= 20000);
alter table public.projects add constraint projects_autonomous_goal
  check (not autonomous or char_length(goal_md) >= 1);

-- Who sees a project: the workspace, unless it grew out of someone's own chat. Then the person,
-- and whoever can open its chat (private chats stay private, D-091).
create function public.can_view_project(p_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.projects p
    where p.id = p_id and public.is_member(p.org_id)
      and (not p.personal
        or p.owner_user_id = (select auth.uid())
        or (p.owner_user_id is null and public.has_role(p.org_id, 'admin'))
        or (p.conversation_id is not null and public.can_access_conversation(p.conversation_id))))
$$;
grant execute on function public.can_view_project(uuid) to authenticated, casama_worker;

drop policy projects_select on public.projects;
create policy projects_select on public.projects for select to authenticated
  using (public.can_view_project(id));
drop policy project_milestones_select on public.project_milestones;
create policy project_milestones_select on public.project_milestones for select to authenticated
  using (public.can_view_project(project_id));

-- The Library: a creation carries its project itself. Until now the only link was through the run
-- that made it, which pages never had and which is lost when the run goes.
alter table public.creations
  add column project_id uuid references public.projects (id) on delete set null;
create index creations_project_idx on public.creations (project_id, created_at desc)
  where project_id is not null;

-- Filed by itself: from the run that made it, else from the chat it was made in. A later change of
-- the run (a page learns its run after it's published) files it too, but only while it has no
-- project, so something a person took out of a project stays out.
create function public.creations_set_project() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.project_id is null
     and (tg_op = 'INSERT' or new.run_id is distinct from old.run_id) then
    select coalesce(
      (select r.project_id from public.runs r where r.id = new.run_id),
      (select c.project_id from public.conversations c where c.id = new.conversation_id))
    into new.project_id;
  end if;
  return new;
end $$;
create trigger creations_set_project before insert or update of run_id on public.creations
  for each row execute function public.creations_set_project();
revoke execute on function public.creations_set_project() from public, anon, authenticated;

-- A run in a project's chat is the project's run, so its spend and what it makes count there.
create function public.runs_set_project() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.project_id is null and new.conversation_id is not null then
    select c.project_id into new.project_id
    from public.conversations c where c.id = new.conversation_id;
  end if;
  return new;
end $$;
create trigger runs_set_project before insert on public.runs
  for each row execute function public.runs_set_project();
revoke execute on function public.runs_set_project() from public, anon, authenticated;

-- What already exists.
update public.creations c set project_id = coalesce(
  (select r.project_id from public.runs r where r.id = c.run_id),
  (select cv.project_id from public.conversations cv where cv.id = c.conversation_id))
where c.project_id is null and (c.run_id is not null or c.conversation_id is not null);

-- A person's own chat stays a topic under General when it becomes a project's chat (D-253 kept
-- project chats out; the threads D-113 opens are not personal, so they still are).
create or replace function public.is_personal_chat(c public.conversations)
returns boolean
language sql immutable set search_path = ''
as $$
  select c.personal and c.kind = 'direct' and c.created_by is not null
$$;

-- General deleted: the latest remaining chat takes its place, but never a project's chat.
create or replace function public.conversations_replace_main()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_next uuid;
begin
  if not old.is_main then
    return null;
  end if;
  select id into v_next from public.conversations c
  where c.bot_id = old.bot_id and c.created_by = old.created_by and public.is_personal_chat(c)
    and c.project_id is null
  order by coalesce(c.last_message_at, c.created_at) desc, c.id limit 1;
  if v_next is not null then
    update public.conversations set is_main = true, parent_conversation_id = null where id = v_next;
    update public.conversations set parent_conversation_id = v_next
    where bot_id = old.bot_id and created_by = old.created_by and id <> v_next
      and (parent_conversation_id is null or parent_conversation_id = old.id)
      and kind = 'direct' and channel_id is null and (project_id is null or personal);
  end if;
  return null;
end;
$$;
revoke execute on function public.conversations_replace_main() from public, anon, authenticated;
