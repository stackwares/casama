#!/usr/bin/env bash
# Lints and renders the Helm chart with the official Helm image (no local helm needed).
set -euo pipefail
cd "$(dirname "$0")/.."
img=alpine/helm:3.16.4
args=(--set supabase.anonKey=a --set supabase.serviceRoleKey=s --set supabase.jwtSecret=j --set database.url=postgres://u:p@h:5432/postgres)
docker run --rm -v "$PWD/infra/helm/kasama:/chart:ro" "$img" lint /chart "${args[@]}"
docker run --rm -v "$PWD/infra/helm/kasama:/chart:ro" "$img" template kasama /chart "${args[@]}" --set web.enabled=true > /dev/null
echo "helm chart ok"
