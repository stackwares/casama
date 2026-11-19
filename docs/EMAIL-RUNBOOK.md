# Email runbook (Casama Cloud)

App mail goes through **ZeptoMail** from `hello@notify.casama.ai` (D-318). **Resend** is the backup,
with the same domain verified there (D-433).

| Mail | Main | Backup |
| --- | --- | --- |
| Casama's own emails (invites, account emails, support replies, waitlist, alerts from the worker) | ZeptoMail SMTP | Resend, **automatic**: the server tries Resend whenever ZeptoMail fails (`EMAIL_BACKUP_RESEND_API_KEY`) and logs `email: main sender failed, sending through the Resend backup` |
| Supabase Auth (sign-in links, confirmations, password resets) | ZeptoMail SMTP | Resend SMTP, **by hand**: Auth takes one SMTP server, so switch it as below |

Keys, all in Vaultwarden ("Keys & Signing"):

- ZeptoMail: "Casama · ZeptoMail SMTP (agent casama, notify.casama.ai)"
- Resend backup: "Casama · Resend API key (app mail backup, notify.casama.ai)". It can only send,
  and only from notify.casama.ai. It works for the API and for SMTP (`smtp.resend.com`, user `resend`).

## Signs ZeptoMail is down

- People say sign-in emails don't arrive, or the API log shows the backup line above.
- ZeptoMail dashboard (cpaas.zoho.com → Email → Subscription): no credits left, or the account is
  blocked.
- status.zoho.com reports a ZeptoMail outage.

First check credits. Buying one ($2.50 for 10,000 emails) fixes it in a minute, with no switch.

## Switch Auth to Resend (needs Oliver's yes: it changes production)

On the VPS (`ssh casama-vps`):

```sh
cd /opt/casama/infra/compose
cp .env /root/.env.bak-$(date +%Y%m%d-%H%M%S)-auth-to-resend
# Edit .env: SMTP_HOST=smtp.resend.com, SMTP_PORT=587, SMTP_USER=resend,
# SMTP_PASS=<the Resend backup key> (copy it into the file from the vault, never into a chat).
docker compose up -d --no-deps auth
docker compose restart kong   # always after recreating auth, or auth.casama.ai answers 502
```

Then send yourself a sign-in link (a real address such as `hello+test@casama.ai`) and check it
arrives. Only `auth` and `kong` change; the API and worker keep ZeptoMail with Resend behind it
until they are next recreated.

The backup is on Casama's own Resend account (admin@casama.ai, login in Vaultwarden). Its free plan
allows **100 emails a day and 3,000 a month**. For an outage longer than a day, upgrade that plan.

## Switch back

Restore the backup file (or put the ZeptoMail values back), then run the same two `docker compose`
commands. Check a sign-in link again.
