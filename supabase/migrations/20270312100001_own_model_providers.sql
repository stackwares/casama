-- Your own model provider on Casama Cloud, and a switch to turn Casama's models off
-- (docs/OWN-KEYS-PLAN.md §3.1, §3.4, §6).
--
-- organizations.model_default: workspace-wide model choice ({ source: "casama" | "own",
--   credential_id?, model?, cheap_model? }). Null follows Casama's models when available.
-- routines.waiting_for_model: set when a scheduled run is skipped with own_provider_required so the
--   routine shows "Waiting for a model", notifies once, and resumes automatically when a model is
--   connected or Casama's models are turned back on.

alter table public.organizations
  add column if not exists model_default jsonb;

alter table public.routines
  add column if not exists waiting_for_model boolean not null default false;

-- Changing a bot's model policy or a workspace's plan wakes routines waiting for a model (§3.4).
create or replace function public.clear_routine_waiting_for_model_on_bot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.model_policy is distinct from old.model_policy then
    update public.routines
    set waiting_for_model = false
    where bot_id = new.id and waiting_for_model;
  end if;
  return new;
end;
$$;

drop trigger if exists bots_clear_waiting_for_model on public.bots;
create trigger bots_clear_waiting_for_model
  after update of model_policy on public.bots
  for each row execute function public.clear_routine_waiting_for_model_on_bot();

create or replace function public.clear_routine_waiting_for_model_on_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.routines
  set waiting_for_model = false
  where org_id = new.org_id and waiting_for_model;
  return new;
end;
$$;

drop trigger if exists entitlements_clear_waiting_for_model on public.entitlements;
create trigger entitlements_clear_waiting_for_model
  after insert or update on public.entitlements
  for each row execute function public.clear_routine_waiting_for_model_on_entitlement();
