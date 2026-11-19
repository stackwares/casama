# Quick start

Get a Casama server running, sign in, and give your first bot a task. With Docker already installed,
this takes about 15 minutes, most of it building images.

Don't want to run a server? Sign up for [Casama Cloud](https://casama.ai) in the app or at
[app.casama.ai](https://app.casama.ai), and skip to [step 5](#_5-meet-your-first-bot).

## 1. Start a server

You need a machine with Docker. For a trial on your own computer:

```sh
git clone https://github.com/stackwares/casama && cd casama
./install.sh --local
```

For a server other people reach over the internet, point a domain at the machine first, then:

```sh
./install.sh --domain casama.example.com
```

The installer checks Docker, generates every secret, builds and starts the stack, and waits until
it's healthy. It prints the address when it's done. Add `--pull` to download the published images
instead of building them. See [Self-hosting](/self-hosting/) for
requirements, every option and production advice.

::: tip Prefer not to use a terminal?
The desktop app on macOS and Linux can run a server on the computer it's installed on: start
Docker Desktop, then on the sign-in screen choose **More Options** → **Run Casama on This
Computer**. It needs about 10 GB of free disk.
:::

::: tip Want to use it from your phone?
A server installed with `--local` answers only on that computer. [Casama Link](/self-hosting/remote-access)
gives it an address your phone can reach from anywhere, with no domain and no open ports, for
free. Set it up after step 3.
:::

## 2. Install a client

- **Apps**: iOS, iPadOS, Android, macOS, Windows, Linux and the web. On a Mac, get the app from
  [casama.ai/download](https://casama.ai/download) rather than the Mac App Store if you want bots
  to use your Mac or to run a server on it; see
  [which Mac app to get](/faq#should-i-get-the-mac-app-from-the-website-or-the-mac-app-store).
- **CLI**: `brew install stackwares/tap/casama`, or download a binary from the
  [releases page](https://github.com/stackwares/casama/releases). See [CLI](/develop/cli).

## 3. Sign in to your server

**In the app:**

1. Tap **Let's Go**.
2. Tap **More Options**, then the button that shows the current server (**Server:** followed by an
   address). Enter your server's address (for example `https://casama.example.com`, or the address
   `--local` printed) and tap **Connect**.
3. Tap **Continue with Email** → **Use a Password Instead** → **New here? Create an account**, and
   enter an email and password.

The first account on a server becomes its owner.

::: info Email links, Google and Apple
Signing in with an emailed link needs the server to send email, and Google and Apple sign-in need
them set up on the server. A new server has neither, so start with a password. See
[Configuration](/self-hosting/configuration).
:::

**With the CLI:**

```sh
casama config --api-url https://casama.example.com
casama signup --email you@example.com
```

## 4. Add a model

Bots need a model. On Casama Cloud they already have one. On your own server, open **Settings** →
**Model keys** and pick one of these:

- **Continue with ChatGPT** to use a ChatGPT plan you already pay for. This needs the desktop app,
  or `casama credential chatgpt` in the CLI.
- **Add Key** for OpenRouter, OpenAI, Anthropic, Google or xAI.
- **Add Key** → **OpenAI-compatible server** for a local model served by Ollama, LM Studio or vLLM.
  Use an address the server can reach: on a self-hosted server, that's the model machine's network
  address rather than `localhost`, allowed with `OUTBOUND_ALLOW_CIDRS`
  (see [Configuration](/self-hosting/configuration)). Calls to a local model cost nothing.

With the CLI:

```sh
casama credential add --provider openrouter      # prompts for the key
casama credential chatgpt                        # or sign in with a ChatGPT plan
casama credential add --provider openai_compatible --base-url http://192.168.1.20:11434/v1
```

## 5. Meet your first bot

The first time you sign in, the app asks **What should bots call you?**, then makes a workspace
named after you and a personal bot called Casama, and opens its chat. This is the bot's
**General** conversation, where quick questions, briefs and its suggestions land. The chat starts
empty, with tiles to **Connect your apps** and a few starter requests you can tap. Prefer to set
things up yourself? Choose **Set Up Manually** while the workspace is being made.

Your first bot has check-ins on: each morning it sends a brief, and during the day it looks for
things it could help with and offers them as suggestions you accept or dismiss. See
[Routines and triggers](/guide/routines#check-ins).

With the CLI:

```sh
casama org create "My team" && casama org use my-team
casama credential list                           # find your key's id
casama bot create Anna --credential <id>
casama chat Anna "Research the top three open-source vector databases and write a comparison to report.md"
```

## 6. Give it real work

Try a task that needs its computer:

> Find the five most-starred Rust web frameworks on GitHub, compare their latest releases, and save
> a table to `frameworks.md`.

Open the bot's computer to watch it work. When it wants to do something risky, an approval appears
in the chat and as a notification. What it makes, such as the table above, reports, pictures and
sites, is kept in the [Library](/guide/library).

## Next steps

- Connect your tools: [Apps and connections](/guide/connections)
- Put it on a schedule: [Routines and triggers](/guide/routines)
- Decide what it may do on its own: [Autonomy and approvals](/guide/autonomy)
- Invite your team: [Workspaces and teams](/guide/workspaces)
- Reach it from Slack, Teams, Telegram and more: [Chat apps](/guide/chat-apps)
- Use it from your coding tool: [Connect AI apps](/guide/mcp)
