-- What this server paid its providers for each usage row (D-395), so the platform admin can
-- see the margin. cost_usd stays what the workspace is charged: on the server's keys that is
-- this cost × the markup in billing_settings.
--
-- upstream_cost_usd: what the server's operator pays upstream for the row, provider fees
-- included (OpenRouter keeps 5.5% of credits bought). Null when the workspace's own key or
-- plan paid, or when the cost isn't per row (computers run on the server's own machines).
alter table public.usage_ledger add column upstream_cost_usd numeric(12, 6);

-- Members read their workspace's rows (usage_ledger_select). The cost behind the price is for
-- the platform admin only, so it is left out of what they may select. Any later column has to
-- be added to this grant to be readable by members.
revoke select on public.usage_ledger from anon, authenticated;
grant select (id, org_id, bot_id, run_id, kind, quantity, cost_usd, model, created_at, billable,
  billed_at, meta, source, computer_id) on public.usage_ledger to authenticated;

-- Earlier rows. Most rows on the server's keys kept the provider's price in
-- meta.provider_cost_usd, before OpenRouter's fee.
-- Model tokens: one call is two rows (in and out) that each carry the call's whole price.
with g as (
  select id, cost_usd,
    (meta ->> 'provider_cost_usd')::numeric * 1.055 as up,
    sum(cost_usd) over w as total,
    count(*) over w as n
  from public.usage_ledger
  where kind in ('tokens_in', 'tokens_out') and meta ? 'provider_cost_usd'
  window w as (partition by org_id, bot_id, run_id, model, created_at, meta)
)
update public.usage_ledger u
set upstream_cost_usd = case
  when g.total > 0 then g.up * g.cost_usd / g.total * g.n / 2.0
  else g.up / 2.0
end
from g where u.id = g.id;

-- Voice calls: a hold costs nothing yet; the call's settling row carries its price (with the
-- listening floor, so a little above Google's price for quiet calls).
update public.usage_ledger
set upstream_cost_usd = case
  when coalesce((meta ->> 'hold')::boolean, false) then 0
  else (meta ->> 'provider_cost_usd')::numeric
end
where kind = 'voice_seconds' and meta ? 'provider_cost_usd';

-- Everything else priced in meta: OpenRouter's fee on what went through OpenRouter.
update public.usage_ledger
set upstream_cost_usd = (meta ->> 'provider_cost_usd')::numeric
  * case when kind in ('tts_chars', 'stt_seconds', 'media_images', 'media_video_seconds') then 1.055 else 1 end
where kind not in ('tokens_in', 'tokens_out', 'voice_seconds', 'computer_seconds', 'stream_seconds')
  and meta ? 'provider_cost_usd';

-- Casama Link's model calls kept no price: the charge was price × fee × markup, so the cost
-- with the fee is the charge over today's markup.
update public.usage_ledger
set upstream_cost_usd = cost_usd / (select markup from public.billing_settings where id)
where kind in ('tokens_in', 'tokens_out') and billable and upstream_cost_usd is null
  and meta ->> 'source' = 'casama_link';
