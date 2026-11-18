-- Cloud Connect is part of Casama Link now (D-296, renamed 2026-11-15). Its two tables were made by
-- 20261115000001_billing.sql, which production has run, so they are renamed here rather than in place.
-- The Casama Link migrations after this one use the new names.

alter table public.cloud_connect_keys rename to link_keys;
alter table public.cloud_connect_computers rename to link_computers;

-- Constraint renames take their indexes along (primary and unique keys).
alter table public.link_keys rename constraint cloud_connect_keys_pkey to link_keys_pkey;
alter table public.link_keys rename constraint cloud_connect_keys_key_hash_key to link_keys_key_hash_key;
alter table public.link_keys rename constraint cloud_connect_keys_org_id_fkey to link_keys_org_id_fkey;
alter table public.link_keys rename constraint cloud_connect_keys_created_by_fkey to link_keys_created_by_fkey;
alter table public.link_keys
  rename constraint cloud_connect_keys_instance_name_check to link_keys_instance_name_check;
alter table public.link_computers rename constraint cloud_connect_computers_pkey to link_computers_pkey;
alter table public.link_computers
  rename constraint cloud_connect_computers_org_id_fkey to link_computers_org_id_fkey;
alter table public.link_computers
  rename constraint cloud_connect_computers_key_id_fkey to link_computers_key_id_fkey;

alter index public.cloud_connect_keys_org_idx rename to link_keys_org_idx;
alter index public.cloud_connect_computers_org_idx rename to link_computers_org_idx;

alter policy cloud_connect_keys_select on public.link_keys rename to link_keys_select;
alter policy cloud_connect_computers_select on public.link_computers rename to link_computers_select;

-- Usage that came through a key is tagged by source; the code now writes and reads 'casama_link'.
update public.usage_ledger
  set meta = jsonb_set(meta, '{source}', '"casama_link"')
  where meta->>'source' = 'cloud_connect';
