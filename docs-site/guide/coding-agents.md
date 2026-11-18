# Coding agents

A bot can hand a coding task to a dedicated coding agent (Claude Code, Codex, Cursor, Pi, T3 Code,
Kimi Code, or [one you add yourself](#add-your-own-agent)) and report back with a summary, the files that changed and, for cloud agents, a pull
request link. Use it when a task is real software work, like fixing a bug across a repository, and
you'd rather a coding agent do it than the bot's general tools.

## Where the agent runs

You choose where by asking the bot ("use Claude Code on my computer to..."). There are three
places:

| Where | What it uses | Keys and sign-ins | Agents |
| --- | --- | --- | --- |
| Your computer | Your own machine through the [desktop app](/guide/companion) | Your own sign-ins; no keys are passed | Claude Code, Codex, Cursor, Pi, T3 Code, Kimi Code, your own |
| The bot's computer | The bot's sandboxed [computer](/guide/computers) | An API key from a named secret | Claude Code, Codex, Cursor |
| Cloud | Cursor's cloud agents, working on a GitHub repository | `CURSOR_API_KEY` secret | Cursor |

## Use a coding agent on your computer

The agent works in your shared folders with your own sign-ins, and the on-screen overlay shows it
working.

1. Install the agent's command-line tool on your computer and sign in to it: `claude`, `codex`,
   `cursor-agent`, `pi`, T3 Code's `t3` or `kimi`.
2. In the desktop app, open **Settings → Advanced → Use this computer for bots**, allow the bot
   under **Bots Allowed**, and share the project folder under **Shared Folders**.
3. Under **Coding Agents**, check that your agent is listed. If you see "Coding agents run as
   commands, so they need Run commands turned on.", tap **Turn On**.
4. If the agent has **Allow** next to it, tap it once. See [New agents need one Allow](#new-agents-need-one-allow).
5. Ask the bot, for example: "Use Claude Code on my computer to fix the failing tests in
   `~/code/app`."

The app looks for the agents on your `PATH` and in the usual install folders, such as
`/opt/homebrew/bin`, `/usr/local/bin`, `~/.local/bin` and `~/.npm-global/bin`.

### T3 Code

T3 Code runs the task as a new thread in the T3 Code app, so you can watch it and step in there.
Keep T3 Code open while the bot works. The task uses the project's default model and permissions
in T3 Code. Name the folder in your request: if it isn't part of a T3 Code project yet, it's added
as one. If T3 Code stops to ask a question, the bot tells you, and you answer in that thread.

### Kimi Code

Kimi Code runs with `kimi -p <task> --output-format stream-json` and your own Kimi sign-in, on
your computer only. It edits files and runs commands without asking, like Cursor and Pi, so your
shared folders and **Run commands** are what limit it. It needs one Allow on each computer.

### New agents need one Allow

Casama's list of coding agents comes from its signed gallery ([format](/develop/gallery-format#coding-agents)), so new agents can
appear without an app update. Claude Code, Codex, Cursor, Pi and T3 Code run whenever **Run
commands** is on. Any other agent, such as Kimi Code, also needs one **Allow** on each computer
before a bot can use it there: open **Coding Agents** and tap **Allow** next to it. Until then, a
bot that asks for it is told to have you tap Allow.

## Add your own agent

If you use a coding agent Casama doesn't list, add it under **Coding Agents → Add Your Own**:

| Field | What to put |
| --- | --- |
| Name | What you and the bot call it, for example "Aider". |
| Command Name | The program, such as `aider`. Just the name, never a path. |
| Command | The full command, with `{task}` where the task goes, for example `aider --message {task} --yes`. Casama quotes the task. Every command in it starts with the command name. You can also use `{folder}`, and `{result_file}` when the agent writes its answer to a file. |
| Reading the Answer | The end of its output; a JSON line with a `result` field; a stream of JSON lines; a JSON field you name; or written to a file. |
| Time Limit | 1 to 120 minutes. Defaults to 30. |

Tap **Test** before saving. It asks the agent to reply with just the word pong on this computer
and shows what it printed, so you can check that the command and the answer setting work.

Your own agents are shown with a **Yours** label. They:

- run only on the computer you added them on, and only for you;
- can't be seen or changed by anyone else in the workspace, admins included;
- don't need Allow (you added them), but still need **Run commands** on.

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
- the changed files since it started, from `git diff --stat`, including what it committed,
- new files it created and didn't commit,
- the branch it worked on, if one was named,
- for cloud agents, the pull request link.

Cancelling the run stops the agent, including a cloud agent. On a computer, the agent's process is
killed, so it doesn't keep working after you stop the run.

## Options the bot can set

| Option | Meaning |
| --- | --- |
| Folder | The project folder. On your computer it must be inside a shared folder. |
| Branch | A branch to work on. An existing branch is checked out as it is; a missing one is created. For Codex on your computer, its changes are committed on this branch for it. |
| Repository | Cloud only: the GitHub repository URL. Required for cloud agents. |
| Open a pull request | Cloud only: open a pull request when done. |
| Timeout | 1 to 120 minutes. Defaults to 30 minutes on a computer and 60 minutes in the cloud. |

## Approvals and safety

Handing off a coding task is a medium-risk action, and high risk when it may open a pull request,
so it follows your bot's [autonomy](/guide/autonomy) and approval settings.

How much each agent may do on its own depends on where it runs:

- On your computer, Claude Code runs with `--permission-mode acceptEdits` and its own sandbox
  turned on, so it can edit files and run commands (tests, git) without asking, while the sandbox
  keeps its writes inside the project folder. Codex runs with `--sandbox workspace-write`, which
  does the same except that it keeps `.git` read-only, so Codex can't commit. When a branch is
  named, Casama commits Codex's changes on it when Codex finishes, only the files Codex changed;
  files you had already changed before it started are left as they were. Cursor runs with `--force`,
  and Pi as it is: neither keeps commands inside the project, so they can run any command with your
  user's access. Your shared folders and the desktop app's **Run commands** permission still apply,
  and high-risk actions on your computer always ask.
- On the bot's computer, Claude Code runs with `--dangerously-skip-permissions` and Codex with
  `--dangerously-bypass-approvals-and-sandbox`, since the computer is a sandbox.

## Limits

- Pi, T3 Code, Kimi Code and your own agents run only on your computer, with your own sign-ins.
  They can't be set up on the bot's computer yet.
- Gemini CLI, OpenCode and Cline aren't listed yet: they haven't passed a real run.
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
