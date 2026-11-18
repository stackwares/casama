-- Store product ids follow the final app id ai.casama.app (iOS and Android).
update public.plans
   set store_product_ids = jsonb_set(store_product_ids, '{app_store}',
         to_jsonb(replace(store_product_ids->>'app_store', 'dev.casama.', 'ai.casama.')))
 where store_product_ids->>'app_store' like 'dev.casama.%';

update public.credit_packs
   set store_product_ids = jsonb_set(store_product_ids, '{app_store}',
         to_jsonb(replace(store_product_ids->>'app_store', 'dev.casama.', 'ai.casama.')))
 where store_product_ids->>'app_store' like 'dev.casama.%';
