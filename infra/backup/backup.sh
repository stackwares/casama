#!/usr/bin/env bash
# Casama scheduled backups (D-197).
#
#   casama-backup schedule   run every day at BACKUP_TIME (UTC), forever (the container default)
#   casama-backup now        one backup, then exit (manual runs and tests)
#   casama-backup list       list the backups in the bucket
#
# Each backup is a folder <prefix>/<UTC timestamp>/ holding postgres.dump (pg_dump custom format),
# objects.tar.gz (computer archives, when BACKUP_OBJECTS=true) and env (only when encrypted).
# With BACKUP_AGE_RECIPIENTS every file is encrypted with age (".age"); the .env holds every key of
# the installation, so it is never uploaded in plain text.
#
# Settings (environment):
#   PGHOST, PGUSER, PGPASSWORD, PGDATABASE  the database (compose sets them)
#   BACKUP_S3_BUCKET            bucket name; empty = keep backups only in the local volume
#   BACKUP_S3_ENDPOINT          https://<account>.r2.cloudflarestorage.com for R2; empty for AWS
#   BACKUP_S3_REGION            auto for R2 (default), the bucket's region for AWS
#   BACKUP_S3_ACCESS_KEY_ID, BACKUP_S3_SECRET_ACCESS_KEY
#   BACKUP_S3_PREFIX            folder in the bucket (default casama)
#   BACKUP_TIME                 HH:MM in UTC (default 03:30)
#   BACKUP_KEEP_DAYS            remove backups older than this (default 30)
#   BACKUP_AGE_RECIPIENTS       comma-separated age (age1…) or ssh public keys
#   BACKUP_OBJECTS              true to include computer archives (/objects)
#   BACKUP_PING_URL             optional URL called after each success (healthchecks.io and similar),
#                               with /fail appended after a failure
set -euo pipefail

: "${PGHOST:=db}" "${PGUSER:=postgres}" "${PGDATABASE:=postgres}"
export PGHOST PGUSER PGDATABASE
BACKUP_TIME=${BACKUP_TIME:-03:30}
KEEP_DAYS=${BACKUP_KEEP_DAYS:-30}
PREFIX=${BACKUP_S3_PREFIX:-casama}
LOCAL=/backups
log() { printf '%s backup: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

# Sets DEST (rclone path) and the rclone settings in this shell; returns 1 without a bucket.
DEST=""
remote() {
  [[ -n "${BACKUP_S3_BUCKET:-}" ]] || return 1
  export RCLONE_CONFIG_DEST_TYPE=s3
  export RCLONE_CONFIG_DEST_PROVIDER=${BACKUP_S3_PROVIDER:-$([[ "${BACKUP_S3_ENDPOINT:-}" == *r2.cloudflarestorage.com* ]] && echo Cloudflare || echo Other)}
  export RCLONE_CONFIG_DEST_ACCESS_KEY_ID=${BACKUP_S3_ACCESS_KEY_ID:?BACKUP_S3_ACCESS_KEY_ID is required}
  export RCLONE_CONFIG_DEST_SECRET_ACCESS_KEY=${BACKUP_S3_SECRET_ACCESS_KEY:?BACKUP_S3_SECRET_ACCESS_KEY is required}
  export RCLONE_CONFIG_DEST_REGION=${BACKUP_S3_REGION:-auto}
  export RCLONE_CONFIG_DEST_ENDPOINT=${BACKUP_S3_ENDPOINT:-}
  export RCLONE_CONFIG_DEST_NO_CHECK_BUCKET=true
  DEST="dest:$BACKUP_S3_BUCKET/$PREFIX"
}

# Fills ENC with age's -r arguments, one pair per recipient.
ENC=()
recipients() {
  local list=() r
  ENC=()
  IFS=',' read -r -a list <<<"${BACKUP_AGE_RECIPIENTS:-}"
  for r in ${list[@]+"${list[@]}"}; do
    r=$(echo "$r" | xargs)
    [[ -n "$r" ]] && ENC+=(-r "$r")
  done
  return 0
}

ping_status() { [[ -n "${BACKUP_PING_URL:-}" ]] && curl -fsS -m 10 "$BACKUP_PING_URL$1" >/dev/null 2>&1 || true; }

run_once() {
  local stamp dir f
  stamp=$(date -u +%Y-%m-%dT%H-%M-%SZ)
  dir="$LOCAL/$stamp"
  mkdir -p "$dir"
  recipients

  log "dumping database $PGDATABASE on $PGHOST"
  pg_dump -Fc --no-owner -f "$dir/postgres.dump" "$PGDATABASE" || { rm -rf "$dir"; log "pg_dump failed"; return 1; }
  if [[ "${BACKUP_OBJECTS:-false}" == true && -d /objects ]]; then
    log "archiving computer archives"
    tar czf "$dir/objects.tar.gz" -C /objects . || { rm -rf "$dir"; log "archiving computer archives failed"; return 1; }
  fi
  if [[ ${#ENC[@]} -gt 0 ]]; then
    [[ -f /env ]] && cp /env "$dir/env"
    for f in "$dir"/*; do
      # A failed encryption stops the backup: nothing unencrypted is ever uploaded.
      if ! age "${ENC[@]}" -o "$f.age" "$f"; then
        rm -rf "$dir"
        log "encryption failed; check BACKUP_AGE_RECIPIENTS"
        return 1
      fi
      rm -f "$f"
    done
  elif [[ -f /env ]]; then
    log "not uploading .env: set BACKUP_AGE_RECIPIENTS to include it (encrypted)"
  fi
  (cd "$dir" && sha256sum -- * >SHA256SUMS) || { log "checksums failed"; return 1; }

  if remote; then
    log "uploading to $DEST/$stamp"
    rclone copy "$dir" "$DEST/$stamp" || { log "upload failed (kept locally in $dir)"; return 1; }
    log "removing backups older than $KEEP_DAYS days"
    rclone delete --min-age "${KEEP_DAYS}d" "$DEST" || log "retention cleanup failed (kept everything)"
    rclone rmdirs --leave-root "$DEST" >/dev/null 2>&1 || true
    rm -rf "$dir"
  else
    log "no bucket set: kept in the local volume ($dir)"
  fi
  find "$LOCAL" -mindepth 1 -maxdepth 1 -type d -mtime "+$KEEP_DAYS" -exec rm -rf {} + 2>/dev/null || true
  date -u +%Y-%m-%dT%H:%M:%SZ >"$LOCAL/last-success"
  log "done ($stamp)"
}

seconds_until() { # HH:MM UTC
  local now target
  now=$(date -u +%s)
  target=$(date -u -d "$(date -u +%Y-%m-%d) $1" +%s)
  ((target <= now)) && target=$((target + 86400))
  echo $((target - now))
}

case "${1:-schedule}" in
  now)
    run_once || exit 1
    ;;
  list)
    remote || { ls -1 "$LOCAL"; exit 0; }
    rclone lsf --dirs-only "$DEST"
    ;;
  schedule)
    log "daily at $BACKUP_TIME UTC; keeping $KEEP_DAYS days$([[ -n "${BACKUP_S3_BUCKET:-}" ]] && echo " in s3://$BACKUP_S3_BUCKET/$PREFIX" || echo " locally (no bucket set)")"
    while true; do
      sleep "$(seconds_until "$BACKUP_TIME")"
      if run_once; then ping_status ""; else log "backup FAILED"; ping_status "/fail"; fi
    done
    ;;
  *)
    echo "usage: casama-backup [schedule|now|list]" >&2
    exit 2
    ;;
esac
