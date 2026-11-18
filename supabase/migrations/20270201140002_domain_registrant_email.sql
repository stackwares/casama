-- Domains (D-329, docs/SITES-AND-DOMAINS-PLAN.md §7.10): when a workspace that bought a domain is
-- deleted, the registrant gets one email, and the registrant may not be a Casama account. An
-- outbox row may therefore name its one recipient in data->>'to' instead of a workspace or user.
alter table public.email_outbox drop constraint if exists email_outbox_check;
alter table public.email_outbox add constraint email_outbox_check
  check (org_id is not null or user_id is not null or (data ? 'to'));
