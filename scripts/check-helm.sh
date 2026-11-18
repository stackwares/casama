#!/usr/bin/env bash
# Lints and renders the Helm chart with the official Helm image (no local helm needed).
set -euo pipefail
cd "$(dirname "$0")/.."
img=alpine/helm:3.16.4
args=(--set supabase.anonKey=a --set supabase.serviceRoleKey=s --set supabase.jwtSecret=j --set database.url=postgres://u:p@h:5432/postgres)
docker run --rm -v "$PWD/infra/helm/casama:/chart:ro" "$img" lint /chart "${args[@]}"
docker run --rm -v "$PWD/infra/helm/casama:/chart:ro" "$img" template casama /chart "${args[@]}" --set web.enabled=true --set web.image=registry.example.com/casama/web:1 > /dev/null
# Sites (D-329): the wildcard hosts render.
docker run --rm -v "$PWD/infra/helm/casama:/chart:ro" "$img" template casama /chart "${args[@]}" --set ingress.sitesZone=sites.example.com | grep -q '"\*.sites.example.com"'
# The web image isn't published, so enabling the web app without naming one must fail.
if docker run --rm -v "$PWD/infra/helm/casama:/chart:ro" "$img" template casama /chart "${args[@]}" --set web.enabled=true > /dev/null 2>&1; then
  echo "web.enabled without web.image should fail" >&2
  exit 1
fi
echo "helm chart ok"
