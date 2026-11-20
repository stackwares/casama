-- Bot email, next round (BOT-EMAIL-NEXT-PLAN §2, D-451): smaller mailboxes and less daily
-- sending, before anyone relies on the first numbers. Unlike the first migration this overwrites
-- the two keys on every plan (weekly plans included): production still holds the defaults, so no
-- Admin edit is lost. Addresses and mail to new people stay as they are.
update public.plans set limits = limits || '{"mail_sent_day": 20, "mail_storage_mb": 100}'::jsonb
where code = 'free';
update public.plans set limits = limits || '{"mail_sent_day": 50, "mail_storage_mb": 500}'::jsonb
where code in ('plus', 'plus_yearly', 'plus_weekly');
update public.plans set limits = limits || '{"mail_sent_day": 150, "mail_storage_mb": 1024}'::jsonb
where code in ('pro', 'pro_yearly', 'pro_weekly');
update public.plans set limits = limits || '{"mail_sent_day": 300, "mail_storage_mb": 2048}'::jsonb
where code in ('max', 'max_yearly', 'max_weekly');

update public.entitlements e
   set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides), updated_at = now()
 where e.plan_code <> 'selfhost';

-- "Delete mail older than…" and the original-expiry pass read by age per address.
create index if not exists mail_messages_raw_age_idx on public.mail_messages (created_at)
  where raw_key is not null;

-- Storage that counts what is stored (§3.1): `size` becomes the original plus the separately
-- stored files; `raw_size` is the original's share, taken off when the original expires (§3.2).
alter table public.mail_messages add column raw_size integer not null default 0;
update public.mail_messages set raw_size = size where raw_key is not null;
update public.mail_messages m
   set size = m.raw_size + coalesce((select sum((f ->> 'size')::bigint)::int
                                       from jsonb_array_elements(m.files) f
                                      where f ->> 'key' is not null), 0)
 where m.direction = 'in';

-- Deleted by a person (§3.3). Most deleted mail goes at once; a sent mail younger than a day, or
-- any mail younger than an hour in a thread, stays as an empty row until the purge takes it, so
-- the daily caps and the reply-loop guard still count it.
alter table public.mail_messages add column deleted_at timestamptz;
