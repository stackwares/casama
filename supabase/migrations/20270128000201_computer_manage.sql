-- Managing a computer (D-240): a sleep timer per computer, usage per computer, and the reset in
-- progress so the app can show its steps and offer to undo it.

-- Minutes without activity before the computer sleeps. Null: the default (5 minutes).
alter table public.computers
  add column idle_sleep_minutes smallint check (idle_sleep_minutes in (5, 15, 30, 60));

-- The last long action on the computer (a reset), e.g.
-- {"kind": "reset_system", "step": "saving", "checkpoint_id": null, "started_at": "...", "finished_at": null}.
-- Steps: saving, wiping, restarting, done, failed.
alter table public.computers add column operation jsonb;

-- Computer-seconds per computer (older rows have none).
alter table public.usage_ledger
  add column computer_id uuid references public.computers (id) on delete set null;
create index usage_ledger_computer_time_idx on public.usage_ledger (computer_id, created_at)
  where computer_id is not null;

-- A computer's history reads the audit log by target.
create index if not exists audit_log_target_time_idx on public.audit_log (target_id, created_at desc)
  where target_id is not null;
