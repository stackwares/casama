# Casama Helm chart

Runs Casama's API, worker, sandbox supervisor (computers as pods) and optionally the web app on
Kubernetes. Supabase (Postgres, Auth, Realtime) runs separately: Supabase Cloud or the
Supabase Helm chart.

```sh
helm install casama infra/helm/casama -n casama --create-namespace \
  --set publicUrl=https://casama.example.com \
  --set supabase.url=https://xyz.supabase.co \
  --set supabase.anonKey=... --set supabase.serviceRoleKey=... --set supabase.jwtSecret=... \
  --set database.url=postgres://postgres:...@db.xyz.supabase.co:5432/postgres \
  --set ingress.apiHost=casama.example.com --set ingress.pagesHost=pages.casama.example.com
```

- Migrations run as a pre-install and pre-upgrade Job (the server image carries them).
- Tokens are generated once and kept across upgrades; bring your own with `existingSecret`.
- Computers run as pods in `computers.namespace` (set `computers.runtimeClass` to gVisor or Kata
  if you have them). The supervisor can only touch pods there.
- The web app (`web.enabled`) is off by default because its image isn't published: build
  `client/Dockerfile.web`, push it to your registry and set `web.image` to it. Without it, people
  use the Casama apps and point them at `publicUrl`.
- Point Supabase Auth's sign-up hook at `https://<apiHost>/hooks/auth/before-user-created` to use
  the sign-up allowlist and abuse controls.
- Sites (D-329): set `ingress.sitesZone` to a domain used only for sites, with a wildcard
  certificate for it in `ingress.tls`. Every name under it goes to the pages port. To let people
  connect their own domains, the ingress must also pass hosts it doesn't know to the pages
  service with the `Host` header intact, and make certificates for them: cert-manager with
  Cloudflare for SaaS (set `CASAMA_SITES_CF_ZONE_ID` and `CASAMA_SITES_CF_API_TOKEN` with
  `extraEnv`), or a controller with on-demand TLS whose ask URL is the API service's
  `/internal/tls-ask` (set `CASAMA_SITES_OWN_EDGE=true`). Never expose `/internal` publicly. See
  [Sites and domains](../../../docs-site/self-hosting/configuration.md#sites-and-domains).
- More on operating it: [Operations](../../../docs-site/self-hosting/operations.md).
- Check the chart: `scripts/check-helm.sh` (runs `helm lint` and `helm template` in Docker).
