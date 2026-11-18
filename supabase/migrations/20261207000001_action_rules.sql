-- Action rules (SPEC: Post-v1 roadmap → Action rules; D-115): per-action autonomy for a bot or the
-- whole workspace, by tool, tool group or category, optionally limited to a target (recipient
-- domain, recipients, amount). The most specific rule wins; ask or hand off wins ties; autonomy
-- applies when nothing matches. People manage rules; bots have no way to change them.

create table public.action_rules (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete cascade,
  match_kind text not null check (match_kind in ('tool', 'group', 'category')),
  match_value text not null check (char_length(match_value) between 1 and 200),
  -- {domains?: text[], recipients?: text[], max_amount?: number}
  target jsonb,
  rule text not null check (rule in ('allow', 'allow_within_limits', 'ask', 'hand_off')),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  check (match_kind <> 'category' or match_value in ('send', 'pay', 'delete', 'publish', 'share', 'sign_in')),
  check (rule <> 'allow_within_limits' or target is not null)
);
create index action_rules_bot_idx on public.action_rules (org_id, bot_id);
alter table public.action_rules enable row level security;
create policy action_rules_select on public.action_rules for select to authenticated
  using (public.is_member(org_id) and (bot_id is null or public.can_access_bot(bot_id)));
-- Workspace rules by admins; a bot's rules by the people who manage it.
create policy action_rules_write on public.action_rules for all to authenticated
  using ((bot_id is null and public.has_role(org_id, 'admin')) or (bot_id is not null and public.can_manage_bot(bot_id)))
  with check ((bot_id is null and public.has_role(org_id, 'admin')) or (bot_id is not null and public.can_manage_bot(bot_id) and exists (select 1 from public.bots b where b.id = bot_id and b.org_id = action_rules.org_id)));
-- The worker reads them; no tool a bot can call writes them (bots can't change their own rules).
select public.allow_worker('public.action_rules');

-- "Always allow this tool" ticks become rules.
insert into public.action_rules (org_id, bot_id, match_kind, match_value, rule, created_by)
select org_id, bot_id, 'tool', tool_name, 'allow', granted_by from public.tool_grants;

create or replace function public.decide_approval(p_approval_id uuid, p_decision text, p_always_allow boolean default false)
returns public.approvals
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v public.approvals;
begin
  if p_decision not in ('approved', 'denied') then
    raise exception 'bad_decision' using errcode = '22023';
  end if;
  select * into v from public.approvals where id = p_approval_id for update;
  if not found or not public.can_access_bot(v.bot_id) then
    raise exception 'approval_not_found' using errcode = 'P0002';
  end if;
  if v.status <> 'pending' then
    raise exception 'approval_already_decided' using errcode = '55000';
  end if;
  if v.expires_at < now() then
    update public.approvals set status = 'expired' where id = v.id returning * into v;
    return v;
  end if;
  update public.approvals
     set status = p_decision, always_allow = (p_decision = 'approved' and p_always_allow),
         decided_by = (select auth.uid()), decided_at = now()
   where id = v.id returning * into v;
  if v.always_allow then
    insert into public.action_rules (org_id, bot_id, match_kind, match_value, rule, created_by)
    select v.org_id, v.bot_id, 'tool', v.tool_name, 'allow', (select auth.uid())
    where not exists (select 1 from public.action_rules r where r.bot_id = v.bot_id and r.match_kind = 'tool'
                      and r.match_value = v.tool_name and r.target is null);
  end if;
  return v;
end;
$$;
