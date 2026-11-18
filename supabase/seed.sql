-- Local development seed (`supabase start` and `supabase db reset` only; never production or
-- self-host). The default plan ships in migrations.

-- The worker connects as its least-privilege role (D-095), as in production. Locally that role
-- gets a fixed dev password, which .env.example's WORKER_DATABASE_URL uses: the local `postgres`
-- role isn't a superuser, so it can't use the dbos schema the worker owns.
alter role casama_worker login password 'casama_worker_dev';
