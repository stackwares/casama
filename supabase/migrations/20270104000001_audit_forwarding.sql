-- Audit-log forwarding (SPEC: Ops extras; D-146, enterprise): stream audit_log rows to a signed
-- webhook, an OTLP logs endpoint or S3-compatible storage, at least once, from a cursor.
create table public.audit_forwarders (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  kind text not null check (kind in ('webhook', 'otlp', 's3')),
  -- webhook: {url}; otlp: {url}; s3: {endpoint?, region, bucket, prefix?}
  config jsonb not null default '{}'::jsonb,
  -- webhook: signing secret; otlp: headers JSON; s3: {access_key_id, secret_access_key} JSON
  vault_secret_id uuid,
  enabled boolean not null default true,
  -- The last row sent (rows are ordered by created_at, then id).
  cursor_at timestamptz,
  cursor_id uuid,
  sent_rows bigint not null default 0,
  last_sent_at timestamptz,
  last_error text,
  created_at timestamptz not null default now()
);
create index audit_forwarders_org_idx on public.audit_forwarders (org_id);
alter table public.audit_forwarders enable row level security;
create policy audit_forwarders_select on public.audit_forwarders for select to authenticated using (public.has_role(org_id, 'admin'));
select public.allow_worker('public.audit_forwarders');
create index if not exists audit_log_org_created_idx on public.audit_log (org_id, created_at, id);
