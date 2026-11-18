# CLI

`casama` is the command-line client for Casama. It talks to any Casama server: sign in, manage
workspaces and their people, model keys and bots, chat with a bot and watch it work, read and
manage conversations, approvals, routines, tasks, watchers, memory, skills, plugins, apps, secrets,
knowledge, channels, projects, the Library and billing, reach into a bot's computer, move routines
and skills as files, and run your own server. Every command can print JSON for scripts.

## Install

### Homebrew (macOS and Linux)

```sh
brew install stackwares/tap/casama
```

### Release binaries

Each CLI release on [GitHub](https://github.com/stackwares/casama/releases) (tagged `cli-v<version>`)
has a native binary for each platform, with a SHA-256 checksum file next to it:

| Platform | File |
| --- | --- |
| macOS, Apple silicon | `casama-<version>-darwin-arm64.tar.gz` |
| macOS, Intel | `casama-<version>-darwin-x64.tar.gz` |
| Linux, x64 | `casama-<version>-linux-x64.tar.gz` |
| Linux, ARM64 | `casama-<version>-linux-arm64.tar.gz` |
| Windows, x64 | `casama-<version>-windows-x64.zip` |

```sh
v=0.1.3
curl -LO "https://github.com/stackwares/casama/releases/download/cli-v$v/casama-$v-linux-x64.tar.gz"
curl -LO "https://github.com/stackwares/casama/releases/download/cli-v$v/casama-$v-linux-x64.tar.gz.sha256"
shasum -a 256 -c "casama-$v-linux-x64.tar.gz.sha256"
tar xzf "casama-$v-linux-x64.tar.gz"
sudo mv casama /usr/local/bin/
casama --version
```

The binary is self-contained: no Dart runtime needed.

### From source

With the [Dart SDK](https://dart.dev/get-dart) 3.13 or later and a clone of the repository:

```sh
cd dart && dart pub get && cd cli
dart compile exe bin/casama.dart -o casama
```

## Connect and sign in

The CLI talks to Casama Cloud (`https://api.casama.ai`) until you point it somewhere else. For
your own server, save its address once, then log in:

```sh
casama config --api-url https://casama.example.com
casama login --email ana@example.com
```

`login` asks for your password (or reads `CASAMA_PASSWORD`). If your account has two-step sign-in,
it asks for the code from your authenticator app (or takes `--code`, or `CASAMA_2FA_CODE`). With
`--magic-link`, it emails you a one-time code and asks you to type it in, instead of using a
password. In a script, sign in with a code in two runs: `casama login -e <email> --magic-link
</dev/null` sends the email and stops (there's no code on its input), then `casama login -e <email>
--magic-code <code>` signs in without sending another.

Most commands work in one workspace. Set a default so you don't have to pass `--org` every time:

```sh
casama org list
casama org use acme
```

### Where settings live

| File | What's in it |
| --- | --- |
| `~/.config/casama/config.json` | The saved `api_url` and the default `org` |
| `~/.config/casama/session.json` | Your session (access and refresh tokens), readable only by you |

On Windows the folder is `%APPDATA%\casama`. Set `CASAMA_CONFIG_DIR` to use another folder, for
example one per server. The CLI refreshes the session itself; `casama logout` deletes it.

The API address comes from, in order: `--api`, `CASAMA_API_URL`, the saved `api_url`, and finally
`https://api.casama.ai` (Casama Cloud). `casama config` shows the one in use.

## Global options

| Option | Meaning |
| --- | --- |
| `--api <url>` | API base URL for this command |
| `--json` | Print JSON instead of text (see [Scripting](#scripting-with-json)) |
| `--version` | Print the CLI's version |
| `-h`, `--help` | Help for any command, also `casama help <command>` |

Put global options before the command: `casama --json bot list`.

Many commands take `--org` (`-o`): a workspace slug or id. Without it they use the default from
`casama org use`. Bots can be named by id or by name (not case-sensitive).

Commands that delete, revoke, reset or spend money only say what they would do unless you pass
`--yes` (`-y`). With `--json` they print `{"would": ..., "confirm": "--yes"}`. Long text options
(`--persona`, `--instructions`, `--notes` and the like) accept `@file` to read the text from a file.

## Commands

### Account and sign-in

| Command | What it does |
| --- | --- |
| `casama config [--api-url <url>]` | Show the API address and config folder; with `--api-url`, save the address |
| `casama signup --email <email> [--password <pw>]` | Create an account. If the server sends a confirmation email, confirm it, then log in. |
| `casama login --email <email> [--password <pw>] [--code <code>] [--magic-link] [--magic-code <code>]` | Log in. `-e` is short for `--email`. `--code` is the two-step sign-in code; `--magic-code` is the emailed one-time code. |
| `casama logout` | Forget the stored session |
| `casama whoami` | Your email and your workspaces with your role in each |
| `casama pair` | Show a QR code that signs a phone in as you, on the server this CLI points at. It works once, for five minutes. Don't share it: whoever scans it is signed in as you. |
| `casama account export [-o <file.zip>]` | Download everything you can see as a ZIP of JSON files (default `casama-export-<date>.zip`) |
| `casama account delete [--confirm <email>]` | Delete your account and the workspaces you solely own, after a grace period. Asks you to type your email unless you pass `--confirm`. |

`--email` can also come from `CASAMA_EMAIL`, and `--password` from `CASAMA_PASSWORD`.

`pair` works with any server, Casama Cloud included. If the server only answers on your own computer
or network, `pair` says so: a phone somewhere else needs
[remote access](#self-hosting-selfhost) first (`casama selfhost remote on`).

### Workspaces: `org` and `invite`

| Command | What it does |
| --- | --- |
| `casama org list` | Your workspaces: slug, name and role |
| `casama org create <name> [--slug <slug>]` | Create a workspace; you become its owner |
| `casama org use <slug or id>` | Set the default workspace for other commands |
| `casama org invite <email> [--org <slug>] [--role member\|admin]` | Invite someone to the default workspace, or `--org` (role defaults to `member`) |
| `casama invite accept <token>` | Join a workspace with an invite token |
| `casama org members` | The people in the workspace and their roles |
| `casama org invites` | Pending email invites |
| `casama org invite-resend <invite id>` | Send a pending invite email again |
| `casama org invite-revoke <invite id> [--yes]` | Cancel a pending invite |
| `casama org invite-batch <file> [--role member\|admin]` | Invite many people from a file of email addresses |
| `casama org invite-links` | Invite links people can join with |
| `casama org invite-link-create [--role member\|admin] [--expires-in-days <n>] [--max-uses <n>] [--[no-]requires-approval]` | Make an invite link |
| `casama org invite-link-delete <link id> [--yes]` | Turn an invite link off |
| `casama org requests` | People waiting to join through a link that needs approval |
| `casama org request <request id> approve\|deny` | Approve or deny a join request |
| `casama org rename <new name>` | Change the workspace name |
| `casama org settings [key=value ...]` | Show the workspace settings, or change some |
| `casama org mcp-keys` | Keys other tools use to reach the workspace over MCP |
| `casama org mcp-key-create <name>` | Make an MCP key. The key is shown once. |
| `casama org mcp-key-delete <key id> [--yes]` | Revoke an MCP key; tools using it stop working |
| `casama org git-sync` | Show the Git sync of the workspace files |
| `casama org git-sync-set <repo> [--branch <b>] [--path <p>] [--[no-]enabled]` | Set or change the Git repository the workspace files sync with |
| `casama org git-sync-run` | Sync with Git now |
| `casama org git-sync-off [--yes]` | Remove the Git sync setup |
| `casama org encryption` | Show the workspace's encryption status. Key changes are API-only. |

All the `org` commands except `list`, `create` and `use` take `--org`. When the server has no
email provider, `org invite` prints the `casama invite accept <token>` line to send to the person
yourself.

### Model keys: `credential`

Model keys are stored in the server's vault and never shown again. `key` is an alias for
`credential`.

| Command | What it does |
| --- | --- |
| `casama credential add --provider <id> [--label <name>] [--key <key>] [--base-url <url>]` | Add a key. Prompts for it (or reads `CASAMA_MODEL_KEY`) when `--key` is missing. `--label` defaults to `Default`. |
| `casama credential list` | Keys in the workspace: id, provider, label, last 4 characters and test status. A ChatGPT plan shows its account and status instead. |
| `casama credential test <id> [--model <model>]` | Check a key with a one-token call. Exits 1 if it fails. |
| `casama credential chatgpt [--reconnect <id>] [--no-browser]` | Connect your ChatGPT plan in the browser so your bots can run on it instead of an API key. Only you can use the plan. `--no-browser` only prints the link. |
| `casama credential remove <id>` | Delete a key (a ChatGPT sign-in is revoked first) |

`add`, `list` and `chatgpt` take `--org`. `--provider` is one of: `openai`, `anthropic`, `google`,
`xai`, `openrouter`, `openai_compatible`, `brave_search`, `tavily`, `parallel`, `serper`,
`chatgpt`, `treg`, `google_maps`, `mapbox`. For `openai_compatible`, pass
`--base-url` (for example `http://localhost:11434/v1`); the key is optional. Connect `chatgpt` with
`credential chatgpt`, not `credential add`.

```sh
casama credential add --provider openrouter --label Main
casama credential test 3f2a9c1e-7b6d-4e5f-8a9b-0c1d2e3f4a5b
```

### Bots: `bot`

| Command | What it does |
| --- | --- |
| `casama bot list` | Bots you can use: id, name, status, primary model and visibility |
| `casama bot create <name> --credential <id> [options]` | Create a bot |
| `casama bot show <bot>` | A bot's model, autonomy, budget, visibility and persona |
| `casama bot export <bot> [--out <file>] [--memories]` | The bot as a shareable file. It has no keys, and memories only with `--memories`. Prints it unless `--out` is given. |
| `casama bot import <file> --credential <id> [--model <model>] [--no-memories] [--no-routines]` | Create a bot from a file made by `bot export`. Memories and routines come along unless you turn them off. |
| `casama bot share <bot> [--memories] [--expires-in-days <n>]` | Make a link that lets someone else add a copy of the bot. It works for 30 days by default (1 to 365). |
| `casama bot checkins <bot> [--on\|--off] [--brief-time HH:MM] [--every <hours>] [--daily-cap <usd>]` | Show the bot's proactive check-ins, or change them: the daily brief time, how often to scan (1 to 24 hours) and the most to spend per day (up to 100) |
| `casama bot starters <bot>` | The suggested first messages for the bot's empty chat |

Options for `bot create`:

| Option | Meaning |
| --- | --- |
| `-k`, `--credential <id>` | Model key for the bot's models (required) |
| `-m`, `--model <model>` | Primary model. Defaults to the server's default for the key's provider, or, when there is none (a ChatGPT plan, a custom endpoint), the first model the key lists. |
| `--fallback <model>` | A fallback model on the same key; repeat for more, in order |
| `--cheap-model <model>` | A cheaper model for summaries, memory and check-ins. Without it, summaries and memory use the provider's small model (falling back to the primary) and check-ins use the primary. |
| `--persona <text>` | Instructions, or `@file.md` to read them from a file |
| `--autonomy <level>` | `ask_always`, `ask_risky` (default) or `autonomous` |
| `--private` | Only you can see and use the bot |
| `--run-budget <usd>` | Most a single run may spend |
| `--daily-budget <usd>` | Most the bot may spend in a day |

```sh
casama bot create "Invoicer" --credential 3f2a9c1e-7b6d-4e5f-8a9b-0c1d2e3f4a5b \
  --persona @invoicer.md --daily-budget 2
```

### Chat: `chat`

```sh
casama chat <bot> [message] [--conversation <id>]
```

With a message, `chat` sends it, streams the run and exits. Without one, it starts an interactive
chat; an empty line, `/exit` or `/quit` ends it. Each call starts a new conversation and prints
its id; pass `-c <id>` (`--conversation`) to continue one.

The reply goes to stdout. Tool steps (`→ tool`, `✓ result`, `✗ error`), memories, skills and the
cost summary go to stderr, so you can pipe the answer alone:

```sh
casama chat Invoicer "List overdue invoices as CSV" > overdue.csv
```

In a terminal, press Ctrl+C once to cancel the run, twice to quit. (On Windows, Ctrl+C quits the
CLI without cancelling the run; use `casama runs cancel`.)

### Conversations: `chats`

| Command | What it does |
| --- | --- |
| `casama chats list <bot>` | A bot's conversations, newest first |
| `casama chats show <conversation id> [--limit <n>]` | Print a conversation: who, when and what was said. `-n` is short for `--limit`: only the latest `n` messages. |
| `casama chats export <conversation id> [--format markdown\|json] [--out <file>]` | Download a conversation (default Markdown). Prints it unless `--out` is given. |
| `casama chats rename <conversation id> <title>` | Give a conversation a new title |
| `casama chats share <conversation id> [--stop]` | Make a public read-only link; `--stop` makes the link stop working |
| `casama chats message-edit <conversation id> <message id> <text \| @file>` | Edit a sent message. The conversation forks there and the bot answers again. |
| `casama chats branch <conversation id> --from <message id>` | Switch to the branch that holds a message (made by editing a message) |
| `casama chats message-delete <conversation id> <message id> --yes` | Delete one message |
| `casama chats delete <conversation id> --yes` | Delete a conversation |
| `casama chats clear <bot> --yes` | Delete all of a bot's conversations |

`list` and `clear` take `--org`.

```sh
casama chats list Invoicer
casama chats export 8d1e... --out invoices.md
```

### Runs: `runs`

| Command | What it does |
| --- | --- |
| `casama runs watch <run id> [--after <seq>]` | Stream a run's events until it ends, starting after `seq` (default 0) |
| `casama runs cancel <run id>` | Cancel a run and the helper runs it started |
| `casama runs show <run id>` | One run: status, bot, timings and cost |
| `casama runs usage <run id>` | What a run used and what it cost |

`runs watch` catches up on events you missed, then follows live, and reconnects by itself if the
connection drops.

### Approvals: `approvals`

| Command | What it does |
| --- | --- |
| `casama approvals list [--status pending\|approved\|denied\|expired]` | Approvals bots are asking for (default `pending`) |
| `casama approvals approve <approval id> [--always]` | Allow what a bot is asking to do; `--always` also allows that tool from now on |
| `casama approvals deny <approval id>` | Refuse it |

### Routines: `routines`

| Command | What it does |
| --- | --- |
| `casama routines list [--bot <bot>]` | Routines in the workspace, or one bot's |
| `casama routines show <routine id>` | One routine: schedule, state and instructions |
| `casama routines create <bot> --name <name> --schedule <cron> --instructions <text\|@file> [options]` | Make a routine for a bot |
| `casama routines edit <routine id> [options]` | Change a routine. Only the options you pass change. |
| `casama routines run <routine id> [--watch]` | Run a routine now; `-w` streams the run until it ends |
| `casama routines delete <routine id> --yes` | Delete a routine |

Options for `routines create` and `routines edit`:

| Option | Meaning |
| --- | --- |
| `--name <name>` | Routine name |
| `--schedule <cron>` | Cron schedule, like `"0 9 * * 1-5"` (weekdays at 9) |
| `--at <time>` | Run once at this time instead, like `2026-12-31T09:00:00Z` |
| `--instructions <text>` | What the bot should do, or `@file` |
| `--timezone <zone>` | IANA zone, like `Europe/Berlin` |
| `--ends-at <date>` | Stop after this date |
| `--max-runs <n>` | Stop after this many runs |
| `--notify`, `--no-notify` | Notify you when it finishes |
| `--enable`, `--disable` | `edit` only: turn the routine on or off |

```sh
casama routines create Invoicer --name "Overdue check" --schedule "0 9 * * 1-5" \
  --instructions @overdue.md --timezone Europe/Berlin
```

### Tasks: `tasks`

| Command | What it does |
| --- | --- |
| `casama tasks list [--status <status>] [--bot <bot>] [--all]` | Tasks in the workspace. Done tasks are hidden unless you pass `--all`. `-s` is short for `--status`. |
| `casama tasks add <title> [options]` | Add a task |
| `casama tasks edit <id> [options]` | Change a task. Only the options you pass change. |
| `casama tasks done <id>` | Mark a task done |
| `casama tasks comment <id> <text>` | Add a comment |
| `casama tasks comments <id>` | Show a task's comments |
| `casama tasks delete <id> --yes` | Delete a task and its comments |

Options for `tasks add` and `tasks edit`:

| Option | Meaning |
| --- | --- |
| `--title <title>` | `edit` only: new title |
| `--bot <bot>` | Give the task to this bot (name or id) |
| `--due <date>` | Due date, like `2026-12-01` |
| `--notes <text>` | Details, or `@file` |
| `--status <status>` | `todo` (default for `add`), `in_progress`, `in_review`, `blocked` or `done` |
| `--priority <level>` | `urgent`, `high`, `medium`, `low` or `none` |
| `--label <label>` | `add` only: a label; repeat for more |
| `--done` | `edit` only: mark it done |

### Watchers: `watchers`

A watcher checks a page and wakes a bot when it changes.

| Command | What it does |
| --- | --- |
| `casama watchers list <bot>` | A bot's watchers |
| `casama watchers add <bot> <url> [options]` | Watch a page |
| `casama watchers edit <id> --pause\|--resume` | Stop checking for now, or start again |
| `casama watchers delete <id> --yes` | Stop and delete a watcher |

Options for `watchers add`:

| Option | Meaning |
| --- | --- |
| `--name <name>` | A name for the watcher (default: the address) |
| `--anchor <text>` | Compare from this text on (a label just before the part that matters) |
| `--chars <n>` | How many characters after the anchor to compare |
| `--condition <words>` | What counts as a change worth waking the bot for, in words |
| `--every <minutes>` | Check every this many minutes |
| `--where server\|mine` | `server` reads public pages; `mine` reads signed-in pages in your own browser |

```sh
casama watchers add Shopper https://example.com/shoes --condition "price drops" --every 60
```

### Memory: `memory`

| Command | What it does |
| --- | --- |
| `casama memory list <bot> [--search <words>]` | A bot's memories, pinned ones first (marked `*`). `-s` is short for `--search`. |
| `casama memory edit <bot> <memory id> [--content <text\|@file>] [--pin\|--unpin]` | Change a memory's text or pin it so it is always remembered |
| `casama memory delete <bot> <memory id> --yes` | Make a bot forget one memory |
| `casama memory import <bot> <file or -> [--dry-run]` | Save memories from the answer another assistant gave to `import-prompt`; `-` reads standard input. `--dry-run` shows what would be saved and saves nothing. |
| `casama memory import-prompt` | Print a prompt to paste into another assistant (ChatGPT, Claude) so it lists what it knows about you |

### Usage: `usage`

| Command | What it does |
| --- | --- |
| `casama usage [--period day\|month]` | Cost and tokens by bot since the start of the day or month (default `month`). Computer time no bot ran shows as its own line. |

### Computers: `computer`

Every `computer` command except `status` acts on one computer: `--computer <id>` (`-c`), or the
workspace's team computer when you leave it out. They all take `--org`.

| Command | What it does |
| --- | --- |
| `casama computer status` | Computers in the workspace: id, name, state, profile and last activity |
| `casama computer start` | Start the computer, or wake it from sleep |
| `casama computer stop` | Save its files to storage and put it to sleep |
| `casama computer shell` | Open an interactive terminal in it; type `exit` to leave |
| `casama computer files ls [path]` | List a folder |
| `casama computer files get <path> [-O <local file>]` | Download a file to stdout, or to a file with `-O` (`--output`) |
| `casama computer files put <local file> <path>` | Upload a file |
| `casama computer files rm <path>` | Delete a file |
| `casama computer checkpoints` | Undo points, newest first |
| `casama computer restore <checkpoint id>` | Go back to a checkpoint. This replaces the computer's files. |
| `casama computer checkpoint [--label <name>]` | Make an undo point now (default label `Saved from the CLI`) |
| `casama computer restart` | Sleep and start again. Files are kept. |
| `casama computer reset [--erase] [--no-checkpoint] [--yes]` | Reset to a fresh system, keeping your files. `--erase` also empties the home folder, like a new computer. A restore point is saved first unless `--no-checkpoint`. |
| `casama computer update [--force] [--yes]` | Restart on the newer system now. Files are kept; open windows and programs close. `--force` restarts even while a command is running. |
| `casama computer processes` | Programs running on the computer |
| `casama computer kill <pid>` | Stop a program by its PID (see `processes`) |
| `casama computer screenshot [-O <file>]` | Save a picture of the screen (default `screenshot.png`) |
| `casama computer vitals` | CPU, memory and disk use right now |
| `casama computer storage` | Disk space used, by category |
| `casama computer storage-clean [--yes]` | Free space by removing caches and temporary files (never `~/workspace`) |
| `casama computer history` | What happened to the computer, newest first |
| `casama computer usage` | Computer time and cost this month |

```sh
casama computer files put ./report.csv data/report.csv
casama computer files get data/summary.md -O summary.md
```

See [Computers](/guide/computers) for what a bot's computer is.

### Skills: `skills`

| Command | What it does |
| --- | --- |
| `casama skills catalog [query]` | Skills you can install; add words to search |
| `casama skills install <catalog id \| github url> [--bot <bot>] [--gallery] [--yes]` | Install a catalog skill, or a skill from a GitHub URL. `--bot` installs for one bot only; `--gallery` means the id is a gallery id. A GitHub skill shows a preview first; `--yes` installs it. |
| `casama skills stats <skill id>` | How often a skill is used and how often it works |
| `casama skills update <skill id> [--yes]` | Show a skill's pending update; `--yes` applies it |

### Plugins: `plugins`

Plugins put skills and tools from a Git repository on a bot. See [Plugins](/develop/plugins).

| Command | What it does |
| --- | --- |
| `casama plugins list --bot <bot>` | The plugins installed on a bot |
| `casama plugins preview <git url> [--commit <sha>]` | What a plugin would install and what it can reach |
| `casama plugins install <git url> --bot <bot> [--commit <sha>] [--secret NAME=VALUE] [--setting NAME=VALUE] [--device <id>] [--yes]` | Install a plugin. It shows the preview first; `--yes` installs. A bare `--secret NAME` asks for the value. `--device` runs it on your own computer. |
| `casama plugins update <plugin id> [--secret NAME=VALUE] [--setting NAME=VALUE] [--yes]` | Show what an update changes; `--yes` applies it |
| `casama plugins settings <plugin id> key=value...` | Change a plugin's settings |
| `casama plugins remove <plugin id> --yes` | Remove a plugin from its bot |

### Apps: `apps`

| Command | What it does |
| --- | --- |
| `casama apps list [--connected]` | Apps you can connect (Slack, GitHub, ...) and which are connected; `--connected` shows only your connections, with their ids |
| `casama apps connect <app id> [--method oauth\|api_key\|none\|managed] [--api-key <key>] [--no-wait] [--no-browser]` | Connect an app. Sign-in opens in your browser and the command waits up to 3 minutes for it. The method defaults to the best one the app offers; without `--api-key` it asks. |
| `casama apps test <connection id \| app id \| name>` | Check that a connection works and list its tools |
| `casama apps edit <connection> --risk <tool>=low\|medium\|high` | Change how risky a tool is, so bots ask first; repeat `--risk` for more |
| `casama apps remove <connection> --yes` | Disconnect an app |

### Secrets: `secrets`

Secrets are API keys and passwords bots can use. The CLI never shows their values.

| Command | What it does |
| --- | --- |
| `casama secrets list` | Secret names and where they may be used |
| `casama secrets add <name> --host <host> [--bot <bot>] [--kind value\|totp] [--value <secret>]` | Save a secret. `--host` is a host it may be sent to; repeat for more. `--bot` limits it to a bot (default: all); repeat for more. `--kind totp` saves a two-step seed. Without `--value` it asks, and nothing is echoed. |
| `casama secrets remove <id \| name> --yes` | Delete a secret |
| `casama secrets requests [--all]` | Secrets that bots are asking you for; `--all` includes answered and expired requests |
| `casama secrets fulfill <request id> [--value <secret>]` | Give a bot the secret it asked for. Without `--value` it asks. |
| `casama secrets decline <request id>` | Tell a bot no |

### Knowledge: `knowledge`

Knowledge sources are websites, repositories and files bots can search.

| Command | What it does |
| --- | --- |
| `casama knowledge list [--bot <bot>]` | The workspace's knowledge sources, or one bot's |
| `casama knowledge add <name> (--url <url> \| --repo <url> \| --file <file> \| --integration <id> --documents <json>) [options]` | Add a source |
| `casama knowledge sync <id>` | Read a source again now |
| `casama knowledge remove <id> --yes` | Delete a source and what was read from it |

Options for `knowledge add`:

| Option | Meaning |
| --- | --- |
| `-b`, `--bot <bot>` | Give the source to one bot only (default: the whole workspace) |
| `--url <url>` | A website to read |
| `--max-pages <n>` | Pages to read from the website |
| `--repo <url>` | A GitHub repository URL |
| `--sync-every-hours <n>` | Re-read the repository this often |
| `-f`, `--file <file>` | A file to upload; repeat for more |
| `--integration <id>` | A connection id to read from, used with `--documents` |
| `--documents <json>` | A JSON list of `{tool, args, title}`, or `@file` |

### Channels: `channels`

Channels are where a bot can be reached.

| Command | What it does |
| --- | --- |
| `casama channels list --bot <bot>` | A bot's channels |
| `casama channels add <kind> <name> --bot <bot> [--config key=value] [--secret key=value] [--allow <sender>]` | Add a channel. `<kind>` is `telegram`, `email`, `sms`, `slack`, `whatsapp`, `messenger`, `feishu`, `imessage`, `teams`, `discord`, `linear` or `jira`. Each option can repeat; a bare `--secret key` asks for the value. For Slack use `channels slack`. |
| `casama channels slack --bot <bot> [--no-browser]` | Connect a bot to Slack. It opens the Slack install page. |
| `casama channels edit <id> [--name <name>] [--allow <sender>] [--enabled\|--no-enabled]` | Rename a channel, replace the allowed senders, or turn it on or off |
| `casama channels events <id>` | Recent messages in and out of a channel |
| `casama channels remove <id> --yes` | Delete a channel |

### Projects: `projects`

A project has a goal, a plan and milestones that a lead bot works through.

| Command | What it does |
| --- | --- |
| `casama projects list` | The workspace's projects |
| `casama projects show <project id>` | One project with its plan and milestones |
| `casama projects create <name> --bot <bot> [options]` | Start a project led by a bot |
| `casama projects edit <project id> [options]` | Change a project. Only the options you pass change. |
| `casama projects approve-plan <project id>` | Approve the proposed plan so the bot starts work |
| `casama projects signoff <project id> <milestone id>` | Sign off a finished milestone |

Options for `projects create` and `projects edit`:

| Option | Meaning |
| --- | --- |
| `--title <title>` | `edit` only: new name |
| `--status <status>` | `edit` only: `active`, `paused`, `cancelled` or `done` |
| `--goal <text>` | What the project is for, or `@file` |
| `--done <text>` | When it counts as done, or `@file` |
| `--plan <markdown>` | `edit` only: the plan, or `@file` |
| `--budget <usd>` | Spending limit in USD |
| `--deadline <date>` | Due date, like `2026-12-31` |
| `--autonomous`, `--no-autonomous` | Let the bot keep working without asking |

### Library: `library`

The Library holds the files and pages your bots made.

| Command | What it does |
| --- | --- |
| `casama library list [options]` | Files and pages bots made |
| `casama library show <id>` | Details of one file or page |
| `casama library download <id> [--out <path>]` | Save a file or page to this computer. `-O` is short for `--out`: a file or folder (default: the item's name, in the current folder). |
| `casama library duplicate <id>` | Make a copy |
| `casama library rename <id> <new title>` | Give it a new title |
| `casama library delete <id> --yes` | Delete it. It can be restored for 30 days, then it is gone. |
| `casama library restore <id>` | Bring back something deleted in the last 30 days (see `list --deleted`) |

Options for `library list`:

| Option | Meaning |
| --- | --- |
| `--project <id>` | Only this project |
| `--kind <kind>` | `page`, `image`, `video`, `audio`, `document` or `file` |
| `-s`, `--search <words>` | Search the titles |
| `--bot <bot>` | Only what this bot made |
| `--deleted` | Show what was deleted in the last 30 days |
| `--limit <n>` | How many, 1 to 100 |

### Billing: `billing`

| Command | What it does |
| --- | --- |
| `casama billing show` | Plan, period, seats and credits |
| `casama billing usage` | This month's billable usage and recent credit entries |
| `casama billing upgrade --plan plus\|pro\|max [--period monthly\|yearly] [--yes] [--no-browser]` | Start checkout for a plan (period defaults to `monthly`). A plan change can bill you, so without `--yes` it only says what would happen. It opens the checkout page unless `--no-browser`. |
| `casama billing portal [--no-browser]` | Open the page to manage payment methods and invoices. With `--no-browser` it only prints the link. |

```sh
casama billing upgrade --plan pro --period yearly
casama billing upgrade --plan pro --period yearly --yes
```

### Routines and skills as files: `files`

| Command | What it does |
| --- | --- |
| `casama files export <folder>` | Write the workspace's routines and skills to a folder |
| `casama files import <folder> [--dry-run]` | Create and update routines and skills from a folder. Exits 1 if any file had an error. |

Both are for workspace admins. `import` skips files and folders whose names start with `.` (so
`.git` is safe), never deletes anything, and prints `+` for created, `~` for updated and `!` for
errors. See [Routines and skills as files](/develop/workspace-files) for the format.

```sh
casama files export ./casama-files
# edit, commit, review...
casama files import ./casama-files --dry-run
casama files import ./casama-files
```

### Sites and domains: `sites` and `domains`

| Command | What it does |
| --- | --- |
| `casama sites list` | The workspace's published sites |
| `casama sites publish <page id> [--name crumb] [--indexable]` | Put a page on the web at `<name>.<sites zone>`; the page becomes public |
| `casama sites unpublish <page id>` | Take it off the web; the page goes private again |
| `casama domains list` | Domains and their states |
| `casama domains show <domain>` | Hosts, states and the DNS records to add, with what DNS shows now |
| `casama domains connect <name> [--page <page id>]` | Connect a domain you own (admins) and print the records to add |
| `casama domains check <domain>` | Check DNS and the certificate now |
| `casama domains disconnect <domain>` | Disconnect it; a bought domain stays registered |

`<domain>` is a name or an id. Buying, renewing and moving a domain away are in the app. See
[Sites and domains](/guide/sites-and-domains).

```sh
casama sites publish 3f0c... --name crumb
casama domains connect bakery.com --page 3f0c...
casama domains check bakery.com
```

### Self-hosting: `selfhost`

`selfhost` wraps the repository's `install.sh` and Docker Compose. Run it from a clone of the
repository, or point at one with `--dir <path>` (or `CASAMA_SELFHOST_DIR`). `--dir` goes right after
`selfhost`: `casama selfhost --dir /srv/casama status`. Without either, it uses the current folder. When remote
access is on, `up`, `down`, `status` and `logs` include the Casama Link connector (its service is
`connector`).

| Command | What it does |
| --- | --- |
| `casama selfhost init [--domain <domain> \| --local] [--http-port <port>] [--with-desktop] [--monitoring]` | Generate secrets, build images and start the stack (runs `install.sh`) |
| `casama selfhost up` | Start the stack |
| `casama selfhost down` | Stop the stack; data is kept |
| `casama selfhost status` | Services and their health (`docker compose ps`) |
| `casama selfhost logs [service...] [-f]` | The last 200 log lines (default services: `api` and `worker`); `-f` follows |
| `casama selfhost upgrade` | `git pull --ff-only` in the checkout, then rebuild and restart; keeps `.env` and data |
| `casama selfhost backup [options]` | Back up the database, its Vault key, computer archives, the Library's files and `.env` to a timestamped folder |
| `casama selfhost restore <backup folder> [--identity <key file>]` | Restore a backup. This replaces the current data. |
| `casama selfhost remote on [options]` | Give a server on your own computer an address your phone can reach, through Casama Link: no domain, no open ports. Approve a code in a browser; the stack restarts with the address. |
| `casama selfhost remote off [-v]` | Back to this computer only. The link and the address are kept for next time. |
| `casama selfhost remote status` | The address, whether it answers from outside and, if not, where it stops |
| `casama selfhost remote link [options]` | Link a server that has its own domain to Casama Cloud, so its notifications reach the apps from the App Store and Google Play. No address is made. |

Options for `remote on` and `remote link`:

| Option | Meaning |
| --- | --- |
| `--name <name>` | What to call this server in Casama Cloud (default: this machine's name) |
| `--relink` | Link again even when this server already has a key |
| `--no-browser` | Only print the link; don't try to open a browser |
| `-v`, `--verbose` | Show the installer's output while the server restarts |
| `--cloud <url>` | The Casama Cloud address, for a cloud you run yourself (or `CASAMA_CLOUD_URL`) |
| `--invites`, `--no-invites` | `remote on` only. Let people you invited make an account while remote access is on, or close sign-ups. Left out: closed for a new address, unchanged for one that is already on. |

`remote on` needs the stack running and your own account already on the server: remote access
closes sign-ups, and until then the first account to sign up owns the server. Create it first in
the app or with `casama signup`. See [Use your server on your phone](/self-hosting/remote-access)
for more.

`init` options: `--domain` (public domain with automatic HTTPS), `--local` (this machine only, plain
HTTP), `--http-port` (default 80), `--with-desktop` (also build the desktop computer image),
`--monitoring` (Prometheus and Grafana).

`backup` options:

| Option | Meaning |
| --- | --- |
| `--out <folder>` | Where backups go (default `casama-backups`) |
| `--encrypt` | Encrypt every file with [age](https://age-encryption.org) |
| `--recipient <key>` | An age public key (`age1...`) or SSH public key to encrypt to; repeat for more. Also read from `CASAMA_BACKUP_RECIPIENTS` (comma-separated). |
| `--keep <n>` | Keep only the newest `n` backups in `--out` |
| `--keep-days <n>` | Remove backups older than `n` days. With `--keep` too, a backup goes only when it's outside both. |

Encryption needs the `age` program installed. An encrypted backup needs `--identity` (your age
identity file) to restore. A backup without its Vault key restores, but saved secrets (model keys,
app sign-ins) have to be entered again unless the new machine already has the original key. See
[Operations](/self-hosting/operations) for backup schedules and upgrades.

### Start a project: `init`

`init` scaffolds a project for building on Casama, with an `AGENTS.md` that tells your coding
agent the format's rules and limits, how to check its work and where the docs are. It works
offline and needs no sign-in.

| Command | What it makes |
| --- | --- |
| `casama init plugin [folder]` | An [Agent Plugins 1.0](/develop/plugins) plugin: `plugin.json`, `mcp.json` with a dependency-free Node MCP server in `server/`, a skill in `skills/<name>/`, a `README.md` and a GitHub workflow that runs the plugin check |
| `casama init pack [folder]` | A [pack](/develop/packs): the plugin above plus `com.casama/` with a bot, a weekly routine and one question |
| `casama init skill [folder]` | One [skill](/guide/skills): the folder with a `SKILL.md` named after it |
| `casama init bot [folder]` | A [bot template](/develop/bot-templates), `<name>.casama-bot.json`, with a sample skill and routine |
| `casama init routine [folder]` | A [routine file](/develop/workspace-files#routine-files), `<name>.md`, for `casama files import` |

The folder defaults to the current one, and the name to the folder's name, lowercased with dashes
(`My Plugin` becomes `my-plugin`). `--name <name>` (`-n`) sets it instead: for a plugin or skill
it must already be a valid name; for a bot or routine it's the display name, and the file is named
after it. `init` never overwrites a file unless you pass `--force`; otherwise it writes nothing
and exits 1. It prints the files it wrote and what to do next.

```sh
casama init plugin acme-weather
cd acme-weather
npx @casama/plugin-check . --strict
```

Every `AGENTS.md` points at [llms.txt](https://docs.casama.ai/llms.txt), the `.md` version of
the relevant page, Casama's agent kit for Claude Code (`/plugin marketplace add
stackwares/casama`, then `/plugin install casama-dev@casama`) and the docs MCP server at
`https://api.casama.ai/mcp/docs`.

### Start from the gallery: `init --from-gallery`

`casama init --from-gallery bot/<id> [folder]` writes a gallery starter bot as a
[bot template](/develop/bot-templates) (`<id>.casama-bot.json` and an `AGENTS.md`), with every
setup question filled in with its default answer. `casama init --from-gallery plugin/<id> [folder]`
copies a reviewed gallery plugin's folder at the exact commit the gallery reviewed, from GitHub.
The folder defaults to the item's id. Like the other `init` commands it never overwrites a file
unless you pass `--force`. Find ids with `casama gallery search`.

```sh
casama init --from-gallery bot/home-organizer
casama init --from-gallery plugin/hello-casama my-plugin
```

### Packs: `packs`

[Packs](/develop/packs) bring bots, skills, routines, apps and looks to a workspace in one install.

| Command | What it does |
| --- | --- |
| `casama packs preview <github link \| folder> [--gallery <id>]` | Shows what a pack brings: bots, skills, routines, apps, looks, tools, questions, secrets and what it can reach |
| `casama packs install <github link \| folder> [--input k=v] [--secret K=v] [--setting K=v] [--skip kind:id] [--bot <id>] [--no-routines]` | Installs it. A link installs the commit its preview shows; a folder on this computer is sent as files. Answers 202 when an admin approves packs in that workspace |
| `casama packs list` | Installed packs |
| `casama packs update <pack id> [--yes] [--take kind:id]` | Shows the newer version as a diff; `--yes` applies it. What you edited stays yours unless `--take` names it |
| `casama packs remove <pack id> [--delete-bots]` | Removes it; its bots and what you edited stay unless you say otherwise |
| `casama packs export --bot <id> --name <name> --summary <line> (--out <folder> \| --share)` | Turns bots into a pack folder, or a 30-day share link. Lines that look like keys are listed; `--share` refuses them unless `--ignore-findings` |

All take `--org` like the other workspace commands.

```sh
casama packs preview https://github.com/stackwares/casama/tree/main/packs/dev-kit
casama packs install ./my-kit --input team="Platform"
```

### The gallery: `gallery`

| Command | What it does |
| --- | --- |
| `casama gallery search <words> [--type <kind>] [--limit 10]` | Searches the [gallery](https://gallery.casama.ai) for skills, apps, routines, bots, plugins, sets and looks. `--type` (`-t`) can be given more than once: `skill`, `app`, `routine`, `bot`, `plugin`, `set`, `theme`, `scheme`, `wallpaper`. Prints each match's kind and id, description and page. |
| `casama gallery mirror <folder> [--public-key <base64>] [--json-only]` | Downloads a copy of the gallery for a server without internet: every catalog file, `manifest.json`, `manifest.sig` and each item's files. |

`mirror` checks every catalog file against the SHA-256 in `manifest.json`, and each item's files
against the hash in its catalog record, before it writes anything. With a public key
(`--public-key`, or `CASAMA_GALLERY_PUBLIC_KEY`) it also checks `manifest.sig`, the catalog's
Ed25519 signature, and refuses a missing or wrong one. Without a key it says the copy isn't
signature-checked. `--json-only` skips the item files. Serve the folder over HTTP and set the
server's `GALLERY_URL` to its address (see [Configuration](/self-hosting/configuration)).

```sh
casama gallery search "summarize unread email" --type skill --type routine
casama gallery mirror ./gallery-copy --public-key "$GALLERY_PUBLIC_KEY"
```

Both commands need no sign-in. `--gallery <url>` (or `CASAMA_GALLERY_URL`) points them, and
`init --from-gallery`, at another catalog laid out the same way.

## Scripting with JSON

With `--json`, a command prints its result as JSON on stdout, usually the API's own response body:

```sh
casama --json bot list | jq -r '.items[] | select(.status == "idle") | .name'
```

- `chat` and `runs watch` print one run event envelope per line (JSON Lines), the same shape as the
  [HTTP API's events](/develop/api#the-event-envelope):

  ```sh
  casama --json chat Invoicer "Summarize this week" |
    jq -rj 'select(.type == "message.delta") | .payload.text'
  ```

- Errors go to stderr as `{"error": "<code>", "message": "..."}`. The code is the API's problem code
  when there is one (`forbidden`, `run_finished`, ...), or one of the CLI's own: `not_logged_in`,
  `org_required`, `org_not_found`, `bot_not_found`, `no_computer`, `auth_failed`,
  `two_step_failed`, `network_error`, and `http_<status>` (for example `http_502`: the server
  answered with an error that wasn't a problem body, often a proxy or a wrong address). The newer
  commands add `file_not_found` (a `@file` or file argument that isn't there), `not_found`,
  `routine_not_found`, `app_not_found`, `connection_not_found`, `secret_not_found`, `no_emails`
  (`org invite-batch` found no addresses), `bad_bot_file` (`bot import`), `connect_failed`,
  `connect_timeout` and `connect_expired` (`apps connect`). `selfhost` adds `not_a_checkout`, `backup_failed`,
  `identity_required`, `not_a_backup`, `restore_failed`, `not_running` and `no_account`, and
  `selfhost remote` passes on Casama Cloud's codes (`plan_limit`, `suspended`, `link_expired`,
  `unreachable`, ...). `init` adds `file_exists`. `gallery` and `init --from-gallery` add
  `gallery_unavailable`, `gallery_item_not_found`, `gallery_item_retired`, `manifest_invalid`,
  `hash_mismatch`, `signature_missing`, `signature_invalid`, `plugin_source` and `plugin_too_big`.
- Prompts (password, two-step code) read environment variables first, so scripts never wait on
  input: `CASAMA_EMAIL`, `CASAMA_PASSWORD`, `CASAMA_2FA_CODE`, `CASAMA_MODEL_KEY`.

### Environment variables

| Variable | Used for |
| --- | --- |
| `CASAMA_API_URL` | API address, when `--api` isn't given |
| `CASAMA_CONFIG_DIR` | Config folder instead of `~/.config/casama` |
| `CASAMA_EMAIL` | `--email` for `login` and `signup` |
| `CASAMA_PASSWORD` | Password for `login` and `signup` |
| `CASAMA_2FA_CODE` | Two-step sign-in code for `login` |
| `CASAMA_MODEL_KEY` | Key for `credential add` |
| `CASAMA_APP_KEY` | API key for `apps connect --method api_key`, when `--api-key` isn't given |
| `CASAMA_SECRET_VALUE` | Value for `secrets add` and `secrets fulfill`, when `--value` isn't given |
| `CASAMA_SELFHOST_DIR` | Checkout for `selfhost` |
| `CASAMA_BACKUP_RECIPIENTS` | age recipients for `selfhost backup --encrypt` |
| `CASAMA_CLOUD_URL` | Casama Cloud address for `selfhost remote`, when `--cloud` isn't given |
| `CASAMA_GALLERY_URL` | Gallery address for `gallery` and `init --from-gallery`, when `--gallery` isn't given |
| `CASAMA_GALLERY_PUBLIC_KEY` | Public key `gallery mirror` checks `manifest.sig` with, when `--public-key` isn't given |

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | An error (printed to stderr), a run that failed (`chat`, `runs watch`), a failing key (`credential test`), or files with errors (`files import`) |
| 64 | Wrong usage: a missing argument or unknown option |
| 130 | You pressed Ctrl+C twice during a run |

Most `selfhost` commands exit with the code of the program they ran (`docker`, `git`,
`install.sh`).

## Related

- [HTTP API](/develop/api): what the CLI calls
- [Dart SDK](/develop/sdk): the library the CLI is built on
- [Routines and skills as files](/develop/workspace-files)
- [Self-hosting](/self-hosting/)
- [Computers](/guide/computers)
