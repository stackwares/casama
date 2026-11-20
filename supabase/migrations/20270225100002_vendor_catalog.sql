alter table public.vendor_limits add column balance_warn_below numeric not null default 5 check (balance_warn_below >= 0);
alter table public.vendor_limits add column billing_url text;
alter table public.vendor_limits add column impact text;
insert into public.vendor_limits (vendor,label,kind,unit,limit_value,period) values
 ('openrouter','OpenRouter','balance','USD',null,'prepaid'),
 ('deepseek','DeepSeek','balance','USD',null,'prepaid'),
 ('google_maps','Google Maps','quota','tiles',3200,'day'),
 ('maptiler','MapTiler','quota','requests',null,'billing_period'),
 ('here','HERE','quota','tiles',30000,'month'),
 ('twilio','Twilio','balance','USD',null,'prepaid'),
 ('namecom','Name.com','balance','USD',null,'prepaid'),
 ('composio','Composio','quota','requests',null,'month'),
 ('cloudflare','Cloudflare','quota','USD',null,'month'),
 ('parallel','Parallel','quota','searches',null,'prepaid'),
 ('zeptomail','ZeptoMail','quota','emails',null,'prepaid'),
 ('resend','Resend','quota','emails',3000,'month'),
 ('serper','Serper','quota','queries',null,'prepaid'),
 ('gemini','Gemini','quota','USD',null,'month'),
 ('unsplash','Unsplash','quota','requests',null,'day'),
 ('contabo','Contabo VPS','renewal','USD',11,'billing_period'),
 ('apple','Apple Developer','renewal','USD',99,'billing_period'),
 ('domains','Domains','renewal','USD',null,'billing_period')
on conflict (vendor) do nothing;
-- Unknown plan quotas and renewal dates deliberately remain unset until confirmed in Admin.

create table public.vendor_alerts (
  dedupe_key text primary key,
  vendor text references public.vendor_limits(vendor) on delete cascade,
  subject text not null,
  body text not null,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  lease_until timestamptz
);
alter table public.vendor_alerts enable row level security;
select public.allow_worker('public.vendor_alerts');
revoke all on public.vendor_alerts from anon, authenticated;

update public.vendor_limits set billing_url = case vendor
 when 'openrouter' then 'https://openrouter.ai/settings/credits'
 when 'deepseek' then 'https://platform.deepseek.com/usage'
 when 'google_maps' then 'https://console.cloud.google.com/apis/api/tile.googleapis.com/quotas'
 when 'maptiler' then 'https://cloud.maptiler.com/account/'
 when 'twilio' then 'https://console.twilio.com/us1/billing/overview'
 when 'resend' then 'https://resend.com/overview'
 when 'zeptomail' then 'https://zeptomail.zoho.com/'
 when 'serper' then 'https://serper.dev/dashboard'
 when 'composio' then 'https://platform.composio.dev/'
 when 'cloudflare' then 'https://dash.cloudflare.com/'
 else null end,
 impact = case
 when vendor in ('google_maps','maptiler','here') then 'Map cards try the next configured map source, then OpenStreetMap.'
 when vendor in ('parallel','serper','deepseek') then 'Web searches try the next configured search provider.'
 when vendor='zeptomail' then 'App email may fail over to Resend. Count covers app sends only; Supabase Auth SMTP sends are excluded.'
 when vendor='resend' then 'Newsletter delivery and backup app email can stop.'
 when vendor='openrouter' then 'Cloud model requests using server credits can stop.'
 else 'Review the provider account to prevent interruption.' end;
insert into public.vendor_limits(vendor,label,kind,unit,limit_value,period,billing_url,impact)
values ('resend_daily','Resend daily','quota','emails',100,'day','https://resend.com/overview','Daily email delivery allowance can stop newsletter and backup app mail.')
on conflict do nothing;
create table public.vendor_observations (
 vendor text primary key references public.vendor_limits(vendor) on delete cascade,
 observed_at timestamptz not null,
 used numeric check (used >= 0),
 remaining numeric check (remaining >= 0),
 limit_value numeric check (limit_value > 0),
 resets_at timestamptz
);
alter table public.vendor_observations enable row level security;
select public.allow_worker('public.vendor_observations');
revoke all on public.vendor_observations from anon, authenticated;
insert into public.vendor_limits(vendor,label,kind,unit,limit_value,period,billing_url,impact)
values ('openrouter_daily','OpenRouter daily server key','quota','USD',50,'day','https://openrouter.ai/settings/keys','Server model requests can fail when the daily key allowance runs out.'),
 ('google_maps_month','Google Maps monthly','quota','tiles',100000,'month','https://console.cloud.google.com/apis/api/tile.googleapis.com/quotas','Map cards try other configured sources when the included quota is depleted.')
on conflict do nothing;
-- Match the cloud account's existing low-credit warning: roughly one daily key cap of runway.
update public.vendor_limits set balance_warn_below=50 where vendor='openrouter';
