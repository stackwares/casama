-- Welcome chat (SPEC: Post-v1 roadmap → Welcome chat; D-129): a new person's first chat with
-- their personal bot. The scripted steps keep their state on the conversation.
alter table public.conversations drop constraint conversations_purpose_check;
alter table public.conversations add constraint conversations_purpose_check check (purpose in ('chat', 'setup', 'welcome'));
-- {step, focus[], other, scope, learned[]}; null outside the welcome chat
alter table public.conversations add column welcome jsonb;
