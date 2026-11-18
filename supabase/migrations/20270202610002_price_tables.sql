-- Models and prices as admin settings (D-373, docs/REMOTE-CONTENT-PLAN.md #11, #12).
--
-- cost_tables: overrides for the voice, Gemini Live, computer and media prices in code. Empty means
--   every price comes from code, as before. The server checks it on save and again on load.
-- domain_tlds: the endings on sale. Null means CASAMA_DOMAINS_TLDS, else the list in code.
-- domain_cap_*: purchase caps per workspace (docs/SITES-AND-DOMAINS-PLAN.md §7.11), the same
--   numbers the code had.
alter table public.billing_settings
  add column if not exists cost_tables jsonb not null default '{}'::jsonb
    check (jsonb_typeof(cost_tables) = 'object'),
  add column if not exists domain_tlds text[]
    check (domain_tlds is null or cardinality(domain_tlds) between 1 and 100),
  add column if not exists domain_cap_first_month int not null default 3
    check (domain_cap_first_month between 0 and 1000),
  add column if not exists domain_cap_per_month int not null default 10
    check (domain_cap_per_month between 0 and 1000);
