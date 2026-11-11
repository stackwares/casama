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
- Point Supabase Auth's sign-up hook at `https://<apiHost>/hooks/auth/before-user-created` to use
  the sign-up allowlist and abuse controls.
- More on operating it: [Operations](../../../docs-site/self-hosting/operations.md).
- Check the chart: `scripts/check-helm.sh` (runs `helm lint` and `helm template` in Docker).
