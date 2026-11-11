# CLI

`kasama` is the command-line client for Kasama. It talks to any Kasama server: sign in, manage
workspaces, model keys and bots, chat with a bot and watch it work, reach into its computer,
move routines and skills as files, and run your own server. Every command can print JSON for
scripts.

## Install

### Homebrew (macOS and Linux)

```sh
brew install stackwares/tap/kasama
```

### Release binaries

Each CLI release on [GitHub](https://github.com/stackwares/kasama/releases) (tagged `cli-v<version>`)
has a native binary for each platform, with a SHA-256 checksum file next to it:

| Platform | File |
| --- | --- |
| macOS, Apple silicon | `kasama-<version>-darwin-arm64.tar.gz` |
| macOS, Intel | `kasama-<version>-darwin-x64.tar.gz` |
| Linux, x64 | `kasama-<version>-linux-x64.tar.gz` |
| Linux, ARM64 | `kasama-<version>-linux-arm64.tar.gz` |
| Windows, x64 | `kasama-<version>-windows-x64.zip` |

```sh
v=0.8.0
curl -LO "https://github.com/stackwares/kasama/releases/download/cli-v$v/kasama-$v-linux-x64.tar.gz"
curl -LO "https://github.com/stackwares/kasama/releases/download/cli-v$v/kasama-$v-linux-x64.tar.gz.sha256"
shasum -a 256 -c "kasama-$v-linux-x64.tar.gz.sha256"
tar xzf "kasama-$v-linux-x64.tar.gz"
sudo mv kasama /usr/local/bin/
kasama --version
```

The binary is self-contained: no Dart runtime needed.

### From source

With the [Dart SDK](https://dart.dev/get-dart) 3.13 or later and a clone of the repository:

```sh
cd dart && dart pub get && cd cli
dart compile exe bin/kasama.dart -o kasama
```

## Connect and sign in

Point the CLI at your server once, then log in:

```sh
kasama config --api-url https://kasama.example.com
kasama login --email ana@example.com
```

`login` asks for your password (or reads `KASAMA_PASSWORD`). If your account has two-step sign-in,
it asks for the code from your authenticator app (or takes `--code`, or `KASAMA_2FA_CODE`). With
`--magic-link`, it emails you a one-time code instead of using a password.

Most commands work in one workspace. Set a default so you don't have to pass `--org` every time:

```sh
kasama org list
kasama org use acme
```

### Where settings live

| File | What's in it |
| --- | --- |
| `~/.config/kasama/config.json` | `api_url` and the default `org` |
| `~/.config/kasama/session.json` | Your session (access and refresh tokens), readable only by you |

On Windows the folder is `%APPDATA%\kasama`. Set `KASAMA_CONFIG_DIR` to use another folder, for
example one per server. The CLI refreshes the session itself; `kasama logout` deletes it.

The API address comes from, in order: `--api`, `KASAMA_API_URL`, the saved `api_url`, and finally
`http://localhost:8787`.

## Global options

| Option | Meaning |
| --- | --- |
| `--api <url>` | API base URL for this command |
| `--json` | Print JSON instead of text (see [Scripting](#scripting-with-json)) |
| `--version` | Print the CLI's version |
| `-h`, `--help` | Help for any command, also `kasama help <command>` |

Put global options before the command: `kasama --json bot list`.

Many commands take `--org` (`-o`): a workspace slug or id. Without it they use the default from
`kasama org use`. Bots can be named by id or by name (not case-sensitive).

## Commands

### Account and sign-in

| Command | What it does |
| --- | --- |
| `kasama config [--api-url <url>]` | Show the API address and config folder; with `--api-url`, save the address |
| `kasama signup --email <email> [--password <pw>]` | Create an account. If the server sends a confirmation email, confirm it, then log in. |
| `kasama login --email <email> [--password <pw>] [--code <code>] [--magic-link]` | Log in |
| `kasama logout` | Forget the stored session |
| `kasama whoami` | Your email and your workspaces with your role in each |
| `kasama account export [--out <file.zip>]` | Download everything you can see as a ZIP of JSON files (default `kasama-export-<date>.zip`) |
| `kasama account delete [--confirm <email>]` | Delete your account and the workspaces you solely own, after a grace period. Asks you to type your email unless you pass `--confirm`. |

`--email` can also come from `KASAMA_EMAIL`, and `--password` from `KASAMA_PASSWORD`.

### Workspaces: `org` and `invite`

| Command | What it does |
| --- | --- |
| `kasama org list` | Your workspaces: slug, name and role |
| `kasama org create <name> [--slug <slug>]` | Create a workspace; you become its owner |
| `kasama org use <slug or id>` | Set the default workspace for other commands |
| `kasama org invite <email> --org <slug> [--role member\|admin]` | Invite someone (role defaults to `member`) |
| `kasama invite accept <token>` | Join a workspace with an invite token |

When the server has no email provider, `org invite` prints the `kasama invite accept <token>` line
to send to the person yourself.

### Model keys: `credential`

Model keys are stored in the server's vault and never shown again. `key` is an alias for
`credential`.

| Command | What it does |
| --- | --- |
| `kasama credential add --provider <id> [--label <name>] [--key <key>] [--base-url <url>]` | Add a key. Prompts for it (or reads `KASAMA_MODEL_KEY`) when `--key` is missing. `--label` defaults to `Default`. |
| `kasama credential list` | Keys in the workspace: id, provider, label, last 4 characters and test status |
| `kasama credential test <id> [--model <model>]` | Check a key with a one-token call. Exits 1 if it fails. |
| `kasama credential chatgpt [--reconnect <id>] [--no-browser]` | Connect your ChatGPT plan in the browser so your bots can run on it |
| `kasama credential remove <id>` | Delete a key (a ChatGPT sign-in is revoked first) |

`add`, `list` and `chatgpt` take `--org`. `--provider` is one of: `openai`, `anthropic`, `google`,
`xai`, `openrouter`, `openai_compatible`, `fal`, `brave_search`, `tavily`, `deepgram`, `elevenlabs`,
`cartesia`, `fish_audio`, `chatgpt`, `treg`, `google_maps`, `mapbox`. For `openai_compatible`, pass
`--base-url` (for example `http://localhost:11434/v1`); the key is optional. Connect `chatgpt` with
`credential chatgpt`, not `credential add`.

```sh
kasama credential add --provider openrouter --label Main
kasama credential test 3f2a9c1e-7b6d-4e5f-8a9b-0c1d2e3f4a5b
```

### Bots: `bot`

| Command | What it does |
| --- | --- |
| `kasama bot list` | Bots you can use: id, name, status, primary model and visibility |
| `kasama bot create <name> --credential <id> [options]` | Create a bot |

Options for `bot create`:

| Option | Meaning |
| --- | --- |
| `-k`, `--credential <id>` | Model key for the bot's models (required) |
| `-m`, `--model <model>` | Primary model. Defaults to the server's default for the key's provider. |
| `--fallback <model>` | A fallback model on the same key; repeat for more, in order |
| `--cheap-model <model>` | Model for memory and summaries (default: the primary) |
| `--persona <text>` | Instructions, or `@file.md` to read them from a file |
| `--autonomy <level>` | `ask_always`, `ask_risky` (default) or `autonomous` |
| `--private` | Only you can see and use the bot |
| `--run-budget <usd>` | Most a single run may spend |
| `--daily-budget <usd>` | Most the bot may spend in a day |

```sh
kasama bot create "Invoicer" --credential 3f2a9c1e-7b6d-4e5f-8a9b-0c1d2e3f4a5b \
  --persona @invoicer.md --daily-budget 2
```

### Chat: `chat`

```sh
kasama chat <bot> [message] [--conversation <id>]
```

With a message, `chat` sends it, streams the run and exits. Without one, it starts an interactive
chat; an empty line, `/exit` or `/quit` ends it. Each call starts a new conversation and prints
its id; pass `-c <id>` (`--conversation`) to continue one.

The reply goes to stdout. Tool steps (`→ tool`, `✓ result`, `✗ error`), memories, skills and the
cost summary go to stderr, so you can pipe the answer alone:

```sh
kasama chat Invoicer "List overdue invoices as CSV" > overdue.csv
```

Press Ctrl+C once to cancel the run, twice to quit.

### Runs: `runs`

| Command | What it does |
| --- | --- |
| `kasama runs watch <run id> [--after <seq>]` | Stream a run's events until it ends, starting after `seq` (default 0) |
| `kasama runs cancel <run id>` | Cancel a run and the helper runs it started |

`runs watch` catches up on events you missed, then follows live, and reconnects by itself if the
connection drops.

### Memory: `memory`

| Command | What it does |
| --- | --- |
| `kasama memory list <bot> [--search <words>]` | A bot's memories, pinned ones first (marked `*`). `-s` is short for `--search`. |

### Usage: `usage`

| Command | What it does |
| --- | --- |
| `kasama usage [--period day\|month]` | Cost and tokens by bot since the start of the day or month (default `month`) |

### Computers: `computer`

Every `computer` command except `status` acts on one computer: `--computer <id>` (`-c`), or the
workspace's team computer when you leave it out. They all take `--org`.

| Command | What it does |
| --- | --- |
| `kasama computer status` | Computers in the workspace: id, name, state, profile and last activity |
| `kasama computer start` | Start the computer, or wake it from sleep |
| `kasama computer stop` | Save its files to storage and put it to sleep |
| `kasama computer shell` | Open an interactive terminal in it; type `exit` to leave |
| `kasama computer files ls [path]` | List a folder |
| `kasama computer files get <path> [-O <local file>]` | Download a file to stdout, or to a file with `-O` (`--output`) |
| `kasama computer files put <local file> <path>` | Upload a file |
| `kasama computer files rm <path>` | Delete a file |
| `kasama computer checkpoints` | Undo points, newest first |
| `kasama computer restore <checkpoint id>` | Go back to a checkpoint. This replaces the computer's files. |

```sh
kasama computer files put ./report.csv data/report.csv
kasama computer files get data/summary.md -O summary.md
```

See [Computers](/guide/computers) for what a bot's computer is.

### Routines and skills as files: `files`

| Command | What it does |
| --- | --- |
| `kasama files export <folder>` | Write the workspace's routines and skills to a folder |
| `kasama files import <folder> [--dry-run]` | Create and update routines and skills from a folder. Exits 1 if any file had an error. |

Both are for workspace admins. `import` skips files and folders whose names start with `.` (so
`.git` is safe), never deletes anything, and prints `+` for created, `~` for updated and `!` for
errors. See [Routines and skills as files](/develop/workspace-files) for the format.

```sh
kasama files export ./kasama-files
# edit, commit, review...
kasama files import ./kasama-files --dry-run
kasama files import ./kasama-files
```

### Self-hosting: `selfhost`

`selfhost` wraps the repository's `install.sh` and Docker Compose. Run it from a clone of the
repository, or point at one with `--dir <path>` (or `KASAMA_SELFHOST_DIR`). `--dir` goes right after
`selfhost`: `kasama selfhost --dir /srv/kasama status`.

| Command | What it does |
| --- | --- |
| `kasama selfhost init [--domain <domain> \| --local] [--http-port <port>] [--with-desktop] [--monitoring]` | Generate secrets, build images and start the stack (runs `install.sh`) |
| `kasama selfhost up` | Start the stack |
| `kasama selfhost down` | Stop the stack; data is kept |
| `kasama selfhost status` | Services and their health (`docker compose ps`) |
| `kasama selfhost logs [service...] [-f]` | The last 200 log lines (default services: `api` and `worker`); `-f` follows |
| `kasama selfhost upgrade` | `git pull --ff-only` in the checkout, then rebuild and restart; keeps `.env` and data |
| `kasama selfhost backup [options]` | Back up the database, computer archives and `.env` to a timestamped folder |
| `kasama selfhost restore <backup folder> [--identity <key file>]` | Restore a backup. This replaces the current data. |

`init` options: `--domain` (public domain with automatic HTTPS), `--local` (this machine only, plain
HTTP), `--http-port` (default 80), `--with-desktop` (also build the desktop computer image),
`--monitoring` (Prometheus and Grafana).

`backup` options:

| Option | Meaning |
| --- | --- |
| `--out <folder>` | Where backups go (default `kasama-backups`) |
| `--encrypt` | Encrypt every file with [age](https://age-encryption.org) |
| `--recipient <key>` | An age public key (`age1...`) or SSH public key to encrypt to; repeat for more. Also read from `KASAMA_BACKUP_RECIPIENTS` (comma-separated). |
| `--keep <n>` | Keep only the newest `n` backups in `--out` |
| `--keep-days <n>` | Remove backups older than `n` days. With `--keep` too, a backup goes only when it's outside both. |

An encrypted backup needs `--identity` (your age identity file) to restore. See
[Operations](/self-hosting/operations) for backup schedules and upgrades.

## Scripting with JSON

With `--json`, a command prints its result as JSON on stdout, usually the API's own response body:

```sh
kasama --json bot list | jq -r '.items[] | select(.status == "idle") | .name'
```

- `chat` and `runs watch` print one run event envelope per line (JSON Lines), the same shape as the
  [HTTP API's events](/develop/api#the-event-envelope):

  ```sh
  kasama --json chat Invoicer "Summarize this week" |
    jq -rj 'select(.type == "message.delta") | .payload.text'
  ```

- Errors go to stderr as `{"error": "<code>", "message": "..."}`. The code is the API's problem code
  when there is one (`bot_not_found`, `forbidden`, ...), or one of the CLI's own: `not_logged_in`,
  `org_required`, `org_not_found`, `auth_failed`, `two_step_failed`, `network_error`.
- Prompts (password, two-step code) read environment variables first, so scripts never wait on
  input: `KASAMA_EMAIL`, `KASAMA_PASSWORD`, `KASAMA_2FA_CODE`, `KASAMA_MODEL_KEY`.

### Environment variables

| Variable | Used for |
| --- | --- |
| `KASAMA_API_URL` | API address, when `--api` isn't given |
| `KASAMA_CONFIG_DIR` | Config folder instead of `~/.config/kasama` |
| `KASAMA_EMAIL` | `--email` for `login` and `signup` |
| `KASAMA_PASSWORD` | Password for `login` and `signup` |
| `KASAMA_2FA_CODE` | Two-step sign-in code for `login` |
| `KASAMA_MODEL_KEY` | Key for `credential add` |
| `KASAMA_SELFHOST_DIR` | Checkout for `selfhost` |
| `KASAMA_BACKUP_RECIPIENTS` | age recipients for `selfhost backup --encrypt` |

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success |
| 1 | An error (printed to stderr), a run that failed (`chat`, `runs watch`), a failing key (`credential test`), or files with errors (`files import`) |
| 64 | Wrong usage: a missing argument or unknown option |
| 130 | You pressed Ctrl+C twice during a run |

`selfhost` commands exit with the code of the program they ran (`docker`, `git`, `install.sh`).

## Related

- [HTTP API](/develop/api): what the CLI calls
- [Dart SDK](/develop/sdk): the library the CLI is built on
- [Routines and skills as files](/develop/workspace-files)
- [Self-hosting](/self-hosting/)
- [Computers](/guide/computers)
