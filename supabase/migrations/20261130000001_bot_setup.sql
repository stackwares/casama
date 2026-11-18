-- Setup interview (SPEC: Post-v1 roadmap → Setup and starter bots; D-105). A new bot interviews
-- its person in a setup conversation, then proposes its instructions, memories, routines and
-- connections for approval. Existing bots count as set up.
alter table public.bots add column setup_status text not null default 'done'
  check (setup_status in ('pending', 'done', 'skipped'));
alter table public.bots alter column setup_status set default 'pending';
alter table public.conversations add column purpose text not null default 'chat'
  check (purpose in ('chat', 'setup'));
