# Coding agents

A bot can hand a coding task to a dedicated coding agent (Claude Code, Codex or Cursor) and report
back with a summary, the files that changed and, for cloud agents, a pull request link. Use it when
a task is real software work, like fixing a bug across a repository, and you'd rather a coding
agent do it than the bot's general tools.

## Where the agent runs

You choose where by asking the bot ("use Claude Code on my computer to..."). There are three
places:

| Where | What it uses | Keys and sign-ins | Agents |
| --- | --- | --- | --- |
| Your computer | Your own machine through the [desktop app](/guide/companion) | Your own sign-ins; no keys are passed | Claude Code, Codex, Cursor |
| The bot's computer | The bot's sandboxed [computer](/guide/computers) | An API key from a named secret | Claude Code, Codex, Cursor |
| Cloud | Cursor's cloud agents, working on a GitHub repository | `CURSOR_API_KEY` secret | Cursor |

## Use a coding agent on your computer

The agent works in your shared folders with your own sign-ins, and the on-screen overlay shows it
working.

1. Install the agent's command-line tool on your computer: `claude`, `codex` or `cursor-agent`.
2. In the desktop app, open **Settings → Advanced → Use this computer for bots**, allow the bot
   under **Bots allowed**, and share the project folder under **Shared folders**.
3. Under **Coding agents**, check that your agent is listed. If you see "Coding agents run as
   commands, so they need Run commands turned on", tap **Turn on**.
4. Ask the bot, for example: "Use Claude Code on my computer to fix the failing tests in
   `~/code/app`."

The app looks for the agents on your `PATH` and in the usual install folders, such as
`/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin` and `~/.npm-global/bin`.

## Use a coding agent on the bot's computer

The first time, the bot installs the agent's command-line tool on its computer. It passes the API
key only to that one command, and the key is redacted from output like every secret.

1. Open **Settings → Advanced → Secrets** and add a secret the bot can use, named for the agent:

   | Agent | Secret name |
   | --- | --- |
   | Claude Code | `ANTHROPIC_API_KEY` |
   | Codex | `OPENAI_API_KEY` |
   | Cursor | `CURSOR_API_KEY` |

2. Ask the bot, for example: "Clone `https://github.com/example/app` and have Codex add input
   validation to the signup form."

If the secret is missing, the bot is told which one to add.

## Use a Cursor cloud agent

Cursor's cloud agents work on a GitHub repository in Cursor's cloud and can open a pull request
when they finish.

1. Add a secret named `CURSOR_API_KEY` in **Settings → Advanced → Secrets**.
2. Ask the bot with the repository URL, for example: "Have a Cursor cloud agent fix issue 42 in
   `https://github.com/example/app` and open a pull request."

## What you get back

The agent's output streams into the run's timeline while it works. When it's done, the bot gets:

- the agent's summary (its final result when it reports one, otherwise the end of its output),
- the changed files from `git diff --stat`,
- the branch it worked on, if one was named,
- for cloud agents, the pull request link.

Cancelling the run stops the agent, including a cloud agent.

## Options the bot can set

| Option | Meaning |
| --- | --- |
| Folder | The project folder. On your computer it must be inside a shared folder. |
| Branch | A branch to work on. It's created if it doesn't exist. |
| Repository | Cloud only: the GitHub repository URL. Required for cloud agents. |
| Open a pull request | Cloud only: open a pull request when done. |
| Timeout | 1 to 120 minutes. Defaults to 30 minutes on a computer and 60 minutes in the cloud. |

## Approvals and safety

Handing off a coding task is a medium-risk action, and high risk when it may open a pull request,
so it follows your bot's [autonomy](/guide/autonomy) and approval settings.

How much each agent may do on its own depends on where it runs:

- On your computer, Claude Code runs with `--permission-mode acceptEdits`, so it can edit files
  without asking. Codex runs with `--full-auto` and Cursor with `--force`. Your shared folders and
  the desktop app's **Run commands** permission still apply, and high-risk actions on your computer
  always ask.
- On the bot's computer, Claude Code runs with `--dangerously-skip-permissions`, since the computer
  is a sandbox.

## Limits

- Cloud agents are Cursor only. Other agents can be added when they publish an API to start a task.
- Codex on the bot's computer needs an `OPENAI_API_KEY`; signing in with a ChatGPT plan there isn't
  supported yet.
- Only cloud agents open pull requests. On a computer, the agent works on a branch, and you or the
  bot push it.
- Cursor's cloud agent support was built from Cursor's public documentation and tested against a
  stand-in service, not yet against Cursor itself.

## Related

- [Your own computer](/guide/companion)
- [Computers](/guide/computers)
- [Autonomy and approvals](/guide/autonomy)
- [Projects and the ticket board](/guide/projects)
