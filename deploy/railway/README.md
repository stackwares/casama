# Railway

1. Create a project from this repository twice (two services), both using `deploy/railway/railway.json`
   (set the service's config path to it).
2. Service **api**: `MODE=api`, `PORT=8787`, generate a public domain.
   Service **worker**: `MODE=worker`, `API_INTERNAL_URL=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:8787`.
3. Shared variables: see [deploy/README.md](../README.md) (Supabase settings, `INTERNAL_TOKEN`,
   optional Cloud Connect).
