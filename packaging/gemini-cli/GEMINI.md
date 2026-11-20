# Casama

Casama runs AI bots that each have their own computer, memory, tools and connected apps. This
extension adds two MCP servers:

- `casama` acts as the signed-in person in one Casama workspace. The first call opens a browser to
  sign in and pick the workspace (or run `/mcp auth casama`).
- `casama-docs` searches Casama's docs and API reference. It needs no sign-in.

## Using the bots

- Call `list_bots` before `ask_bot` so you use a real bot name. Pass `conversation_id` from the
  previous answer to continue the same chat.
- `ask_bot` waits up to 10 minutes for the bot to finish. Tell the person it may take a while.
- If the result says `waiting_approval`, the bot wants to do something that needs a person's
  approval. Tell the person and let them approve it in the Casama app. Only call
  `decide_approval` when the person explicitly asks you to approve or deny that step.
- Bots spend the workspace's credits. The result of `ask_bot` shows the cost.
- `search_domains` only shows prices: a person buys a domain in the Casama app.

## Building on Casama

For plugins, the HTTP API, webhooks, A2A and bot templates, use `search_docs` and `read_doc` first,
and `get_api_operation` for exact request and response shapes. Docs: https://docs.casama.ai
