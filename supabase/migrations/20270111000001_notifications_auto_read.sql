-- A request answered anywhere (the chat, the inbox, the CLI, a connected app) or expired is no
-- longer news: its notifications are marked read, so badges don't count what is already done.

create or replace function public.read_request_notifications(p_kind text, p_key text, p_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.notifications set read_at = now()
  where kind = p_kind and payload ->> p_key = p_id::text and read_at is null;
$$;
revoke all on function public.read_request_notifications(text, text, uuid) from public, anon, authenticated;

create or replace function public.read_notifications_when_answered()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status <> 'pending' then
    case tg_table_name
      when 'approvals' then perform public.read_request_notifications('approval_request', 'approval_id', new.id);
      when 'takeover_requests' then perform public.read_request_notifications('takeover', 'takeover_id', new.id);
      when 'secret_requests' then perform public.read_request_notifications('secret', 'secret_request_id', new.id);
      else null;
    end case;
  end if;
  return new;
end;
$$;
revoke all on function public.read_notifications_when_answered() from public, anon, authenticated;

drop trigger if exists read_notifications_when_answered on public.approvals;
create trigger read_notifications_when_answered after update of status on public.approvals
  for each row execute function public.read_notifications_when_answered();
drop trigger if exists read_notifications_when_answered on public.takeover_requests;
create trigger read_notifications_when_answered after update of status on public.takeover_requests
  for each row execute function public.read_notifications_when_answered();
drop trigger if exists read_notifications_when_answered on public.secret_requests;
create trigger read_notifications_when_answered after update of status on public.secret_requests
  for each row execute function public.read_notifications_when_answered();

-- Requests already answered before this migration.
update public.notifications n set read_at = now()
where n.read_at is null and n.kind = 'approval_request'
  and exists (select 1 from public.approvals a where a.id::text = n.payload ->> 'approval_id' and a.status <> 'pending');
update public.notifications n set read_at = now()
where n.read_at is null and n.kind = 'secret'
  and exists (select 1 from public.secret_requests s where s.id::text = n.payload ->> 'secret_request_id' and s.status <> 'pending');
