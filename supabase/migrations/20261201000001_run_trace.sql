-- Run tracing (SPEC: Post-v1 roadmap → Run tracing; D-107): the OpenTelemetry trace a run's spans
-- belong to, so the timeline can link to it.
alter table public.runs add column trace_id text check (trace_id ~ '^[0-9a-f]{32}$');

-- Langfuse LLM traces (when the server has Langfuse keys) can be turned off per workspace.
alter table public.organizations add column llm_tracing boolean not null default true;
