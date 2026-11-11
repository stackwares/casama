# FAQ

## General

### How is Casama different from a chat assistant?

A chat assistant answers while you watch. A Casama bot keeps its own memory and computer, works on
schedules and triggers when you're not there, uses your tools through connections, and asks you
before risky steps. You can run it yourself, on any model.

### Is it free?

Self-hosting is free, with no paywall or limits; you pay only your model provider and your server.
Casama Cloud, the hosted service, has plans and credits.

### Which models can I use?

Any model you have a key for: OpenAI, Anthropic, Google, xAI, OpenRouter, or any OpenAI-compatible
endpoint (Ollama, vLLM, LM Studio and others). You can also sign in with a ChatGPT plan. Each bot
picks its own model, with fallbacks. See [Bots and models](/guide/bots).

### Can I run it fully offline or with local models?

You can run the server on your own network and use a local model through an OpenAI-compatible
endpoint. Bots that browse the web or use cloud apps still need internet access for those tasks.

## Privacy and safety

### Who can see my data?

On a self-hosted server, only people with access to your server. Every table uses row-level
security, so one workspace can't read another's data. Message content can be encrypted at rest.
Telemetry is off unless the server owner turns it on. See [Privacy and security](/guide/privacy).

### Does the model see my passwords and API keys?

No. Secrets live in a vault and are filled in at the moment a tool uses them, inside the computer or
the request. They're redacted from logs and never put into the model's input.

### Can a bot do something I didn't want?

Every action has a risk level, and the bot's autonomy level decides which actions need your approval
first. Action rules can allow an action (optionally within limits, such as recipients at one domain
or a maximum amount), always ask, or hand it to you to finish. You can also set budgets and stop a
run at any time. Destructive commands take a checkpoint first, so you can roll the computer back. See [Autonomy and approvals](/guide/autonomy).

### What stops a bot's computer from reaching my network?

Computers reach the internet only through an egress proxy that blocks private and cloud-metadata
addresses, so a bot's computer can't reach your home or office network. See
[Computer providers](/self-hosting/computers).

## Self-hosting

### What do I need to self-host?

A Linux server (or a Mac, for a trial) with Docker, and a domain if other people will connect. See [Self-hosting](/self-hosting/) for sizing.

### How do I upgrade?

Re-run `./install.sh`, or `casama selfhost upgrade`. Your settings and data are kept. See
[Operations](/self-hosting/operations).

### Can I use Casama Cloud computers from my own server?

Yes, with [Cloud Connect](/guide/cloud-connect).

## Building on Casama

### Is there an API?

Yes. Everything the apps do goes through a documented HTTP API. See [HTTP API](/develop/api) and the
[API reference](/api/).

### Can I extend what bots can do?

Yes: connect MCP servers, write [plugins](/develop/plugins) (skills plus tool servers), share
[bot templates](/develop/bot-templates), or call other agents over [A2A](/develop/a2a).

### How do I contribute?

Read the [contributing guide](https://github.com/stackwares/casama/blob/main/CONTRIBUTING.md). Bug
reports, docs fixes and code are all welcome.
