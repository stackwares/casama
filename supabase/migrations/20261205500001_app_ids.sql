-- Store product ids follow the final app id com.kasama.app (iOS and Android).
update public.plans
   set store_product_ids = jsonb_set(store_product_ids, '{app_store}',
         to_jsonb(replace(store_product_ids->>'app_store', 'dev.kasama.', 'com.kasama.')))
 where store_product_ids->>'app_store' like 'dev.kasama.%';

update public.credit_packs
   set store_product_ids = jsonb_set(store_product_ids, '{app_store}',
         to_jsonb(replace(store_product_ids->>'app_store', 'dev.kasama.', 'com.kasama.')))
 where store_product_ids->>'app_store' like 'dev.kasama.%';
