# Cloud Connect

Cloud Connect lets a self-hosted Casama server use Casama Cloud's computers and model credits,
billed to a Casama Cloud workspace. Use it when you want to run your own server but don't want to
host sandboxes or manage model provider accounts yourself.

## How it works

- You create a Cloud Connect key in a Casama Cloud workspace, named after your server.
- Your server uses that key to create computers on Casama Cloud and to call models through Casama
  Cloud.
- Computer time and model calls show on the cloud workspace's bill, labelled with your server's
  name, and are paid from its credits.

Everything else (your bots, chats, memory and data) stays on your server.

## 1. Create a key in Casama Cloud

You need to be an owner or admin of the cloud workspace.

1. In the Casama Cloud app, open **Settings → Billing**.
2. Under **Cloud Connect**, tap **New Cloud Connect key**.
3. Enter a **Server name**, such as `home-server`, and tap **Create**.
4. Copy the key. It starts with `kcc_` and is shown only once.

A key from the app can use both computers and models. Through the API you can limit a key to
`computers` or `models` (`scopes` on `POST /v1/orgs/{id}/cloud-connect/keys`).

## 2. Configure your server

Add both values to your server's `.env` and restart the API and worker:

```sh
CASAMA_CLOUD_URL=https://<Casama Cloud API address>
CASAMA_CLOUD_KEY=kcc_...
```

This adds a computer provider named `casama-cloud`.

## 3. Use cloud computers

Create a computer with the provider `casama-cloud` through the API:

```http
POST /v1/computers
Content-Type: application/json

{ "org_id": "<workspace id>", "name": "Cloud computer", "kind": "team", "provider": "casama-cloud" }
```

The computer runs on Casama Cloud, and bots use it like any other computer. If the server has no
`CASAMA_CLOUD_KEY`, the request fails with `cloud_connect_off`. See [API](/develop/api) and
[Computers](/guide/computers).

## 4. Use model credits

Add an OpenRouter model key that points at Casama Cloud, with the Cloud Connect key as the API key:

```sh
casama credential add --provider openrouter --label "Casama Cloud" \
  --base-url https://<Casama Cloud API address>/connect/v1/models \
  --key kcc_...
```

Then pick that key and a model in a bot's settings. Model calls go to Casama Cloud's upstream
provider and are billed from the provider's reported cost.

## Billing

| What | How it's billed |
| --- | --- |
| Cloud computer time | From create or wake until sleep or delete, per hour |
| Model calls | The provider's reported cost, with any Casama Cloud markup |

Usage appears on the cloud workspace's **Billing** screen under **This month**, with your server's
name, and is deducted from its credits. When the cloud workspace's credits reach zero, Cloud
Connect requests are refused until credits are added. See
[Usage, budgets and plans](/guide/usage).

## Revoke a key

1. In Casama Cloud, open **Settings → Billing**.
2. Under **Cloud Connect**, tap the delete icon next to the server.
3. Confirm **Revoke**.

That server stops using cloud computers and credits right away.

## Limits

- Live view and terminals for cloud computers aren't available through Cloud Connect yet. Bots can
  still use the computer.
- The app has no option to pick the `casama-cloud` provider when creating a computer. Use the API.
- The app's model key form shows **Base URL** only for an OpenAI-compatible server, so add the
  OpenRouter key with the CLI or API.
- A cloud computer belongs to the cloud workspace that first created it. Other cloud workspaces
  can't use it.

## Related

- [Self-hosting](/self-hosting/)
- [Self-hosting computers](/self-hosting/computers)
- [Usage, budgets and plans](/guide/usage)
- [Computers](/guide/computers)
- [CLI](/develop/cli)
