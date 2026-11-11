# Quick start

Get a Kasama server running, sign in, and give your first bot a task. With Docker already installed,
this takes about 15 minutes, most of it building images.

## 1. Start a server

You need a machine with Docker. For a trial on your own computer:

```sh
git clone https://github.com/stackwares/kasama && cd kasama
./install.sh --local
```

For a server other people reach over the internet, point a domain at the machine first, then:

```sh
./install.sh --domain kasama.example.com
```

The installer checks Docker, generates every secret, builds and starts the stack, and waits until
it's healthy. It prints the address when it's done. See [Self-hosting](/self-hosting/) for
requirements, every option and production advice.

::: tip Prefer not to use a terminal?
The desktop app can run a server on the computer it's installed on: on the sign-in screen, choose
**More options** → **Run Kasama on this computer**.
:::

## 2. Install a client

- **Apps**: iOS, Android, macOS, Windows, Linux and the web.
- **CLI**: `brew install stackwares/tap/kasama`, or download a binary from the
  [releases page](https://github.com/stackwares/kasama/releases). See [CLI](/develop/cli).

## 3. Sign in to your server

**In the app:**

1. Tap **Sign in or create account**.
2. Tap **More options**, then the **Server** button, and enter your server's address (for example
   `https://kasama.example.com`, or the address `--local` printed).
3. Tap **Continue with email** → **Use a password instead** → **New here? Create an account**, and
   enter an email and password.

The first account on a server becomes its owner.

::: info Email links, Google and Apple
Signing in with an emailed link needs the server to send email, and Google and Apple sign-in need
them set up on the server. A new server has neither, so start with a password. See
[Configuration](/self-hosting/configuration).
:::

**With the CLI:**

```sh
kasama config --api-url https://kasama.example.com
kasama signup --email you@example.com
```

## 4. Meet your first bot

The first time you sign in, the app opens a welcome chat. It creates a workspace and a personal bot
for you, then asks what you'd like help with first. Along the way it asks for a model:

- **Continue with ChatGPT** to use a ChatGPT plan you already pay for,
- **Add a model key** for OpenRouter, OpenAI, Anthropic, Google, xAI or another provider, or
- **Use a local model**, for example one served by Ollama.

Answer the questions (or skip them) and the bot suggests a first task. Prefer to set things up
yourself? Choose **Set up manually**.

With the CLI:

```sh
kasama org create "My team" && kasama org use my-team
kasama credential add --provider openrouter      # prompts for the key
kasama bot create Ada --credential <id>
kasama chat Ada "Research the top three open-source vector databases and write a comparison to report.md"
```

::: tip No API key?
Run a model locally with Ollama and add it as an OpenAI-compatible endpoint, using an address the
server can reach (on a self-hosted server, the Ollama machine's network address rather than
`localhost`, allowed with `OUTBOUND_ALLOW_CIDRS`; see [Configuration](/self-hosting/configuration)):
`kasama credential add --provider openai_compatible --base-url http://192.168.1.20:11434/v1`.
:::

## 5. Give it real work

Try a task that needs its computer:

> Find the five most-starred Rust web frameworks on GitHub, compare their latest releases, and save
> a table to `frameworks.md`.

Open the bot's computer to watch it work. When it wants to do something risky, an approval appears
in the chat and as a notification.

## Next steps

- Connect your tools: [Apps and connections](/guide/connections)
- Put it on a schedule: [Routines and triggers](/guide/routines)
- Decide what it may do on its own: [Autonomy and approvals](/guide/autonomy)
- Invite your team: [Workspaces and teams](/guide/workspaces)
- Use it from your coding tool: [Connect AI apps](/guide/mcp)
