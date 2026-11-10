-- Audit 2026-11 (D-091): a conversation becomes private to the person who started it once their
-- personal device data (calendar, health, places…) reaches it. Only they see its messages and run
-- events from then on; anyone else who uses the bot no longer does. Deleting a conversation is for
-- its starter or the bot's managers.
alter table public.conversations add column private boolean not null default false;

create or replace function public.can_access_conversation(p_conversation uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.conversations c
    where c.id = p_conversation and public.can_access_bot(c.bot_id)
      and (not c.private or c.created_by = (select auth.uid()))
      and not exists (select 1 from public.conversation_bots cb where cb.conversation_id = c.id and not public.can_access_bot(cb.bot_id)))
$$;

drop policy conversations_select on public.conversations;
create policy conversations_select on public.conversations for select to authenticated
  using (public.can_access_bot(bot_id) and public.group_bots_visible(id) and (not private or created_by = (select auth.uid())));
drop policy conversations_delete on public.conversations;
create policy conversations_delete on public.conversations for delete to authenticated
  using (public.can_access_bot(bot_id) and (created_by = (select auth.uid()) or public.can_manage_bot(bot_id)));

create or replace function public.run_visible(p_run uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select not exists (
    select 1 from public.runs r join public.conversations c on c.id = r.conversation_id
    where r.id = p_run and c.private and c.created_by is distinct from (select auth.uid()))
$$;
grant execute on function public.run_visible(uuid) to authenticated, kasama_worker;
drop policy run_events_select on public.run_events;
create policy run_events_select on public.run_events for select to authenticated
  using (public.can_access_bot(bot_id) and public.run_visible(run_id));
-- Live run streams follow the same rule.
create or replace function public.can_access_run(p_run_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.runs r where r.id = p_run_id and public.can_access_bot(r.bot_id)) and public.run_visible(p_run_id);
$$;
