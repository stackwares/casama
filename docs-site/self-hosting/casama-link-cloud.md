# Cloud computers and credits (Casama Link)

Run your own Casama server, but let Casama Cloud host the bots' computers or pay for the model
calls. A Casama Link key from a Casama Cloud workspace gives your server both, billed to that
workspace's credits.

This is the paid half of Casama Link. The free half, an address your phone can reach plus
notifications, is on [Use your server on your phone](/self-hosting/remote-access). See the
[Casama Link overview](/guide/casama-link) for how the two fit together.

## How it works

- A workspace owner or admin creates a Casama Link key in Casama Cloud, named after your server.
- Your server uses that key to create computers on Casama Cloud and to call models through it.
- Computer time and model calls show on the cloud workspace's bill under your server's name, and
  are paid from its credits.

Everything else (your bots, chats, memory, files and data) stays on your server.

## 1. Create a key in Casama Cloud

You need to be an owner or admin of the cloud workspace.

1. In the Casama Cloud app, open **Settings → Billing**.
2. Open **Charges by server, Casama Link servers and keys**.
3. Under **Casama Link**, choose **New Casama Link Key**.
4. Enter a **Server name**, such as `home-server`, and choose **Create**.
5. Copy the key. It starts with `kcc_` and is shown only once.

A key from the app can use both computers and models. Through the API you can pick what a key may
do with `scopes` on `POST /v1/orgs/{id}/link/keys`:

| Scope           | Lets the server                                  | Spends credits |
| --------------- | ------------------------------------------------ | -------------- |
| `computers`     | Create and use computers on Casama Cloud         | Yes            |
| `models`        | Call models through Casama Cloud                 | Yes            |
| `remote_access` | Hold a `casama.link` address                     | No             |
| `push`          | Send notifications to the store apps             | No             |

A key made by linking (`casama selfhost remote on`, or **Use on Your Phone** in the app) has only
`remote_access` and `push`.

## 2. Configure your server

Add both values to `infra/compose/.env`:

```sh
CASAMA_CLOUD_URL=https://api.casama.ai
CASAMA_CLOUD_KEY=kcc_...
```

Then run `casama selfhost up`. The API and worker now offer a computer provider named
`casama-cloud`.

::: tip One key per server
A server holds one `CASAMA_CLOUD_KEY`. To use cloud computers or credits and remote access
together, create the key through the API with all four scopes, set it in `.env`, then run
`casama selfhost remote on`, which keeps a key that can already hold an address. Linking again
replaces the key with one that can't spend credits.
:::

## 3. Use cloud computers

Create a computer with the provider `casama-cloud` through the API:

```http
POST /v1/computers
Content-Type: application/json

{ "org_id": "<workspace id>", "name": "Cloud computer", "kind": "team", "provider": "casama-cloud" }
```

The computer runs on Casama Cloud, and bots use it like any other computer: shell, files, browser,
sleep and wake. If the server has no `CASAMA_CLOUD_KEY`, the request fails with `link_cloud_off`.
If the key lacks the `computers` scope, Casama Cloud refuses with `computers_unavailable`. See
[API](/develop/api) and [Computers](/guide/computers).

## 4. Use model credits

Add an OpenRouter model key that points at Casama Cloud, with the Casama Link key as the API key:

```sh
casama credential add --provider openrouter --label "Casama Cloud" \
  --base-url https://api.casama.ai/link/v1/models \
  --key kcc_...
```

Then pick that key and a model in a bot's settings. Casama Cloud passes the calls to its own model
provider (OpenRouter by default) and bills the cost that provider reports. One call can ask for at
most 32,768 output tokens (more is cut to that), and it needs enough credits for its prompt and
that output. A streamed call you stop early is billed for its prompt and what came out, reasoning
included.

## Billing

| What                | How it's billed                                              |
| ------------------- | ------------------------------------------------------------ |
| Cloud computer time | Per hour, from create or wake until sleep or delete          |
| Model calls         | The provider's reported cost, with Casama Cloud's markup     |

Usage appears on the cloud workspace's **Billing** screen with your server's name, and is deducted
from its credits. When the credits run out, new computers, wake-ups, commands and model calls are
refused with `out_of_credits` until credits are added. Model calls also stop for the day when the
workspace reaches its daily limit for model credits. See [Usage, budgets and plans](/guide/usage).

Cloud computers follow the cloud workspace's plan, counted together with its own hosted computers:
how many computers it can have and run at once (`plan_limit`), its computer hours for the month
(`computer_hours_exceeded`), and its computer size (a bigger size asked for is cut to the plan's).
When the workspace runs out of credits or computer hours, Casama Cloud puts its running computers
to sleep itself, and the next wake-up restores them from that sleep.

## Revoke a key

1. In Casama Cloud, open **Settings → Billing**, then **Charges by server, Casama Link servers and
   keys**.
2. Under **Casama Link**, choose the delete icon next to the server.
3. Confirm **Revoke**.

That server stops using cloud computers and credits right away. If the key also held an address,
the address is removed too.

## Limits

- Live view and terminals for cloud computers aren't available through Casama Link. Bots can still
  use the computer.
- The app has no option to pick the `casama-cloud` provider when creating a computer. Use the API.
- The app's model key form shows **Base URL** only for an OpenAI-compatible server, so add the
  OpenRouter key with the CLI or the API.
- A cloud computer belongs to the cloud workspace that first created it. Other cloud workspaces
  can't use it.

## Related

- [Casama Link overview](/guide/casama-link)
- [Use your server on your phone](/self-hosting/remote-access)
- [Computer providers](/self-hosting/computers#casama-link-computers)
- [Configuration](/self-hosting/configuration#casama-link)
- [Usage, budgets and plans](/guide/usage)
- [CLI](/develop/cli)
