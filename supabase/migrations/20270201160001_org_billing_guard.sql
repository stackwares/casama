-- Billing audit 2026-11-17. The organizations update policy lets a workspace admin change any
-- column through /rest/v1, including ones billing and abuse controls rely on:
--   created_by     the 5-workspace cap, "first free workspace" credits and trial eligibility
--   plan           the plan the server set from the subscription
--   suspended_*    abuse suspensions
--   storage_bytes  the Library storage limit
--   region         where the workspace lives
-- Only the server (or its own triggers) changes these now. Owners also could delete a workspace
-- through /rest/v1, which wiped its credit and usage history (and any debt) and made the next
-- workspace "first free" again; workspaces are deleted only by the server (account deletion).

create or replace function public.org_billing_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') and (
    new.id is distinct from old.id
    or new.created_by is distinct from old.created_by
    or new.created_at is distinct from old.created_at
    or new.plan is distinct from old.plan
    or new.region is distinct from old.region
    or new.suspended_at is distinct from old.suspended_at
    or new.suspended_reason is distinct from old.suspended_reason
    or new.storage_bytes is distinct from old.storage_bytes
  ) then
    raise exception 'this workspace setting is changed by the server' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke execute on function public.org_billing_guard() from public, anon, authenticated;

drop trigger if exists org_billing_guard on public.organizations;
create trigger org_billing_guard before update on public.organizations
for each row execute function public.org_billing_guard();

drop policy if exists organizations_delete on public.organizations;
revoke delete on public.organizations from anon, authenticated;

-- One bought credit pack credits one workspace, even if a store lists the purchase under two
-- (aliases, transfers) and both sync at once.
create unique index if not exists credit_ledger_purchase_once on public.credit_ledger (reference)
  where reason = 'purchase';
