# Scheduled off-site backups (D-197): pg_dump of the Casama database, optionally the computer
# archives and the .env, encrypted with age when recipients are set, uploaded to any S3-compatible
# bucket (Cloudflare R2, AWS S3, Backblaze B2, MinIO) with rclone. Compose profile "backup".
FROM alpine:3.22
RUN apk add --no-cache bash postgresql17-client rclone age tzdata ca-certificates curl coreutils
COPY infra/backup/backup.sh /usr/local/bin/casama-backup
# Runs as root: it reads the installer's .env (mode 600, root) and the computer archives volume.
# It has no published port and talks only to the database and the bucket.
RUN chmod 755 /usr/local/bin/casama-backup && mkdir -p /backups /root/.config/rclone && touch /root/.config/rclone/rclone.conf
LABEL org.opencontainers.image.title="casama-backup" \
      org.opencontainers.image.licenses="Apache-2.0"
ENTRYPOINT ["casama-backup"]
CMD ["schedule"]
