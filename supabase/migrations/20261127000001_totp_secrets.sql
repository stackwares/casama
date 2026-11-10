-- Sign-in codes for bots (SPEC: Post-v1 roadmap → Sign-in codes for bots; D-102). A totp secret
-- holds a two-step seed; bots write {{totp:NAME}} and get the current code only at execution time.
alter table public.secrets add column kind text not null default 'value' check (kind in ('value', 'totp'));
alter table public.secret_requests add column kind text not null default 'value' check (kind in ('value', 'totp'));
