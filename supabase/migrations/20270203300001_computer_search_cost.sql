-- Computer time and the server's own web search get what they cost the server (D-400), so the
-- admin's margin view covers every charge. New rows are written with it; this fills earlier ones
-- at the default provider rates (COMPUTER_RATES' defaults): Docker $0.003 per vCPU-hour and
-- $0.005 per GB-hour, E2B and Daytona $0.0504 and $0.0162, Casama Cloud's computers (what a
-- self-hosted server pays Casama) $0.05 per vCPU-hour. A server that overrides
-- COMPUTER_RATES gets those overrides from now on only.
update public.usage_ledger l
set upstream_cost_usd = l.quantity / 3600.0 * (
  case c.provider when 'e2b' then 0.0504 when 'daytona' then 0.0504 when 'casama-cloud' then 0.05 else 0.003 end
    * coalesce((c.size ->> 'cpus')::numeric, 1)
  + case c.provider when 'e2b' then 0.0162 when 'daytona' then 0.0162 when 'casama-cloud' then 0 else 0.005 end
    * coalesce((c.size ->> 'memory_mb')::numeric, 1024) / 1024)
from public.computers c
where l.kind = 'computer_seconds' and l.upstream_cost_usd is null
  and c.id = l.computer_id and c.provider <> 'local';

-- Casama Link computers (no computer row here): one size step of Docker an hour.
update public.usage_ledger
set upstream_cost_usd = quantity / 3600.0 * 0.008
where kind = 'computer_seconds' and upstream_cost_usd is null
  and meta ->> 'source' = 'casama_link';

-- Earlier searches can't be told apart (the server's chain or a workspace key), so they stay
-- without a cost; searches from now on say which.
