# Coolify

Coolify runs Docker Compose stacks with the Docker socket, so it can host the full stack, computers
included.

1. On the Coolify server, run `./install.sh --no-start --domain your.domain` once from a checkout to
   generate `infra/compose/.env` (or copy its keys by hand).
2. In Coolify: New resource → Docker Compose → this repository, compose file
   `infra/compose/docker-compose.yml`, and paste the variables from `infra/compose/.env`.
3. Let Coolify's proxy route your domain to the `caddy` service on port 80 and set `CASAMA_SITE=:80`
   (Coolify terminates TLS), or remove `caddy` and route `/v1`, `/hooks`, `/connect` to `api:8787` and
   `/auth/v1`, `/rest/v1`, `/realtime/v1` to `kong:8000`.
4. Build the computer image once on the server:
   `docker compose -f infra/compose/docker-compose.yml --profile images build computer-headless`.
