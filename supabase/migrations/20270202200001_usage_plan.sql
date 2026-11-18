-- Making credits last (docs/USAGE-PLAN.md, D-355).
--
-- 1. A scan remembers what its first reads returned (message ids, event change marks, the board).
--    A scheduled scan that reads the same again ends without a model call.
-- 2. A conversation remembers which tool groups its runs loaded, so the next message starts with
--    them: no tools.load step, and the same tool list as last time, which keeps the provider's
--    prompt cache.
-- 3. Free checks in once a day (a scan and the brief) instead of twice. At the measured cost two
--    scans and a brief a day came to more than Free's monthly credits. Only where the plan still
--    has the old default, so a value set from the Admin screen is kept.

alter table public.bot_checkins add column if not exists scan_digest text;
comment on column public.bot_checkins.scan_digest is
  'Digest of what the last finished scan read first; an unchanged scheduled scan is skipped.';

alter table public.conversations add column if not exists tool_groups text[] not null default '{}';
comment on column public.conversations.tool_groups is
  'Tool groups this conversation''s runs loaded, most recent first; the next run starts with them.';

update public.plans set limits = limits || '{"min_scan_hours": 24}'::jsonb
 where code = 'free' and (limits ->> 'min_scan_hours')::numeric = 12;

update public.entitlements e
   set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides), updated_at = now()
 where e.plan_code = 'free';
