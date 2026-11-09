# CLI

`kasama` talks to any Kasama server. Add `--json` to any command for scripting.

| Command | What it does |
| --- | --- |
| `kasama config --api-url <url>` | Save the server address |
| `kasama signup`, `login`, `logout`, `whoami` | Accounts |
| `kasama org create / list / use`, `kasama invite` | Workspaces and members |
| `kasama credential add / list / test` | Model and provider keys (stored in Vault, never shown again) |
| `kasama bot create / list / update` | Bots, models, autonomy and budgets |
| `kasama chat <bot> [message]` | Chat; streams tool calls and output |
| `kasama runs list / show / cancel` | Run history and timelines |
| `kasama memory list / search / delete` | What a bot remembers |
| `kasama computer ...` | Files, checkpoints and terminals on bot computers |
| `kasama usage` | Cost and tokens by bot |
| `kasama account export / delete` | Your data (ZIP) and account deletion |
| `kasama selfhost init / up / down / status / logs / upgrade / backup / restore` | Run your own server |

Run `kasama help <command>` for every option.
