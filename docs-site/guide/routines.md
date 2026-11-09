# Routines and webhooks

- **Schedules**: cron in a timezone, e.g. every weekday at 09:00 America/Chicago.
- **Webhooks**: GitHub (signed with the repository's secret) or custom (HMAC `x-kasama-signature:
  sha256=<hex>` of the body). Each delivery starts a run with the payload.
- Results can notify you in the app.
