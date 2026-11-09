# Cloud Connect

A self-hosted server can use Kasama Cloud computers and model credits, billed to a cloud workspace.

1. In Kasama Cloud: Settings → Billing → Cloud Connect → New key.
2. On your server: set `KASAMA_CLOUD_URL` and `KASAMA_CLOUD_KEY` and restart.
3. Create computers with provider `kasama-cloud`. For model credits, add an OpenRouter credential
   with base URL `<cloud>/connect/v1/models` and the Cloud Connect key.

Usage shows on the cloud workspace's bill, labelled with your server's name.
