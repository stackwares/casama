-- Local MCP servers on the user's computer (SPEC: Post-v1 roadmap → Local MCP servers; D-096).
-- Each server the desktop app registers is an integration of kind local_mcp:
-- config {device_id, computer_id, owner_user_id, server, label, summary, timeout_s}.
-- Environment values (tokens) stay on the device; nothing secret is stored here.
alter table public.integrations drop constraint integrations_kind_check;
alter table public.integrations add constraint integrations_kind_check
  check (kind in ('mcp', 'openapi', 'composio', 'pipedream', 'local_mcp'));
