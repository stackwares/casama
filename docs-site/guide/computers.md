# Computers

Every bot works on its own sandboxed Linux computer: a shell, a home folder that persists between
chats, a browser that stays signed in, and on desktop computers, a screen you can watch and
control. Use this page to understand what's on a computer, how it sleeps and wakes, and how to
step in when a bot needs a hand.

If you run your own server, provider setup (Docker, gVisor, E2B, Daytona) lives on
[Self-hosting computers](/self-hosting/computers).

## Team, private and personal computers

| Kind | Who uses it | Shown in the app as |
| --- | --- | --- |
| Team computer | Every bot in the workspace that has no computer of its own. One per workspace. | **Team computer** |
| Private computer | One bot. Its files stay separate from the team computer. | **{bot}'s computer** |
| Your own computer | Bots you allow, through the desktop app. See [Your own computer](/guide/companion). | **This device** |

A bot with no setting uses its private computer if it has one, otherwise the team computer. To
pick a different one, open the bot's **Bot settings → Computer** and choose **Automatic** or a
specific computer.

Workspace admins manage the team computer. Whoever manages a bot manages its private computer.
Bots never share a computer across workspaces.

## Create a private computer

1. Open **Settings → Computers**.
2. Tap **New computer**.
3. Choose the bot under **For bot** and give the computer a **Name**.
4. Turn on **With a desktop** if you want a screen you can watch live. It uses more memory.
5. Tap **Create**.

From the same list, each computer's **More** menu offers **Live view** (desktop computers),
**Switch to desktop** or **Switch to headless**, **Rename** and **Delete**. Deleting a computer
also deletes its files, snapshots and checkpoints. The team computer has no **Delete** option.

## What's on a computer

Every computer starts from Casama's image, based on Ubuntu 24.04:

| Area | Included |
| --- | --- |
| Shell and tools | bash, git, curl, wget, jq, ripgrep, zip and unzip, nano, vim, OpenSSH client, build tools |
| Languages | Node.js 24, Python 3 with pip and venv |
| Browser | Chromium, driven by the bot through agent-browser |
| Desktop computers only | A desktop with a taskbar (**Browser**, **Terminal**, **Text editor**), accessibility tooling so the bot can use apps, and the live view streamer |

The bot works as an unprivileged user named `casama`, and its home folder is the only place that
persists. On the default Docker provider the rest of the filesystem is read-only, so install extra
tools into the home folder: `pip install` installs for the user, and `npm install -g` installs
under `~/.npm-global`. `/tmp` is a 1 GB scratch space that's cleared when the computer sleeps.

By default, a computer on the Docker provider gets 1 CPU and 1 GB of memory. Your server's
operator can change these defaults.

## Headless and desktop computers

New computers are **Headless** unless you turn on a desktop. A headless computer has a shell,
files and a browser, but no screen. Its **Screen** tab shows the bot's open browser page, refreshed
every 5 seconds, and stays blank until the bot opens a page.

A **Desktop** computer adds a real screen that you can watch and control live, and the bot can use
desktop apps. On a desktop computer the bot's browser runs as a visible window, so when you take
over you see exactly what the bot sees.

To switch, tap **Switch to desktop** on the Screen tab, or use **Switch to desktop** or **Switch to
headless** in the computer's **More** menu. A running computer restarts into the new profile, and
its files are kept.

If a bot on a headless computer asks you to take over, for example to sign in, Casama switches that
computer to the desktop profile for you and reopens the bot's current page in a visible window.

## The computer panel

Open a bot's computer in any of these ways:

- **Computer** in the main navigation shows the team computer.
- In a chat on a wide screen, tap **Show computer** at the far right of the header. The panel
  opens beside the chat.
- In a chat on a phone or narrow window, open the **More** menu and tap **Computer**.

The panel shows the computer's name and state, with **Sleep** or **Wake up**, and four tabs:
**Screen**, **Terminal**, **Files** and **Checkpoints**.

On wide screens you can resize the side panel: drag its left edge. It stays between 360 px and 60%
of the window, and the chat always keeps at least 420 px. Double-click the edge to reset it. The
width is remembered on this device.

### States you'll see

The state shown is checked against the sandbox each time the app lists computers, so a computer
that says **Running** really is running. The panel refreshes itself while it's visible: every 3
seconds while the computer wakes, otherwise every 10 seconds, and again when you return to the app.

| State | Meaning |
| --- | --- |
| **Setting up** | The computer is being created for the first time. |
| **Starting** | It's waking up and restoring its files. |
| **Running** / **Idle** | It's awake and ready. |
| **Going to sleep** | Its files are being saved before it stops. |
| **Asleep** | Its files are saved and it isn't running. It wakes when needed. |
| **Stopped** | It's been stopped. |
| **Error** | Something went wrong. The panel shows the error, and **Try again** retries. |

## Sleep and wake

A computer goes to sleep after 10 minutes with no tool calls, open terminals, running commands or
live viewers. Sleeping saves the home folder (your files, the bot's workspace and its browser
profile) to storage and stops the computer, so an asleep computer costs nothing to keep.

It wakes on its own the next time a bot needs it or you open the live view. You can also tap
**Wake up** in the panel, or **Sleep** to put it to sleep now. Everything in the home folder comes
back, including browser sign-ins.

## Files

The **Files** tab browses the computer's home folder. You can open folders, go **Up**,
**Download** a file, **Upload** files from your device, and **Delete** files. Files your bots make
and files you upload both show up here.

Files you attach in a chat are uploaded to `~/workspace/uploads` on the bot's computer. When a bot
links a file it made, such as `[report.md](workspace/report.md)`, tap the link to preview it and
open, save or share it. See [Chat](/guide/chat).

The **Terminal** tab opens a shell on the same computer the bots use, so you can see and fix what
they did. Tap **Connect** to start a session.

## The browser and sign-ins

The bot's browser keeps its profile in the home folder, so cookies and sign-ins survive sleep,
wake and restores. Sign in once, and the bot stays signed in.

When a site needs you, for example a password or a two-step code, the bot can ask you to take over.
You sign in yourself in the live view, and nothing you type reaches the bot. See
[Take control](#take-control-and-hand-back).

## Checkpoints and restore

A checkpoint saves the computer's home folder so you can undo a change. The bot saves one
automatically before commands that destroy data, such as `rm -r` or `rm -f`, `git reset --hard`,
`git clean -f`, force pushes, package uninstalls, `dd`, `mkfs` and `truncate -s 0`. Bots can also
save one on purpose before risky work.

To restore one:

1. Open the computer panel and go to **Checkpoints**.
2. Tap **Restore** next to the checkpoint.
3. Confirm. Files changed since then are replaced.

Checkpoints also appear in the chat and run timeline with a **Restore** button.

Each computer keeps its last 20 checkpoints or 7 days of them, whichever is fewer. Older ones are
deleted.

## Live view

Live view streams a desktop computer's screen to the app over WebRTC. Open it
from the **Screen** tab (**Open live view**, or **Wake up and watch live** if it's asleep), from
**Live view** in a computer's menu, or from a bot's request for help. Opening it wakes a sleeping
computer, and watching keeps it awake.

On wide screens the live view plays right inside the side panel. Tap **Full screen** to expand it
and **Back to the side panel** to return. The header shows the latency in milliseconds.

If your network blocks live video, the view falls back to screenshots and says **Screenshots (live
video unavailable on this network)**.

### Quick actions

Under the live status, in the side panel and full screen:

| Action | What it does | Needs control |
| --- | --- | --- |
| **Copy** | Presses Ctrl+C on the computer and puts the copied text on your device's clipboard. | Yes |
| **Paste** | Sends your device's clipboard to the computer and presses Ctrl+V. | Yes |
| **Screenshot** | Saves or shares a screenshot from your device. | No |
| **Keyboard** | Opens your phone's keyboard. Enter types Return on the computer. | Phones, yes |

While in control you can also turn on **Right-click on next tap** for touch screens.

## Take control and hand back

At any time you can take the mouse and keyboard from the bot.

1. In the live view, tap **Take control**. The status changes to **You're in control**.
2. Do what you need to, such as signing in.
3. Tap **Hand back**. Optionally add a **Note for the bot**, for example "I signed in, carry on".
4. Confirm with **Hand back**.

While you're in control, the bot is paused. Its browser and desktop actions wait, and so do its
shell and file commands. Nothing you type or see is sent to the bot. When you hand back, the bot
reads your note and takes a fresh look at the screen before it continues.

Control returns to the bot on its own after 15 minutes without input from you. Only one person can
be in control at a time. Others see **Someone else is in control** and can only watch.

### When a bot asks for help

A bot can ask you to take over, for example at a sign-in page or a CAPTCHA. You get a notification,
and the chat shows the request with **Take control**. The live view shows "The bot asks: ..." with
the reason. Take control and hand back as above, or tap **Dismiss** to decline. A request that no
one answers expires after 24 hours.

## Team computer folders

On a team computer, each bot works in its own folder, `~/workspace/bots/<name>`, and
`~/workspace/shared` holds what the bots share. Both are created the first time the bot needs
them.

- The folder name comes from the bot's name, such as `research-bot`, with `-2`, `-3` and so on if
  two bots would clash. It's kept when you rename the bot, so its files don't move.
- The bot's commands start in its own folder. Paths starting with `shared/` or `bots/` point into
  the workspace, so every bot reaches the shared folder the same way.
- This is a convention, not a wall. Bots on a team computer share one Linux user and can technically
  reach each other's folders. Give a bot a private computer when it needs real separation.

### Desktop users at once

A team computer has one screen. **Desktop users at once** (1 to 10, default 1) limits how many bots
use desktop tools at the same time. When the screen is in use, other bots keep working with the
shell, files and browser. Admins change it from the team computer's **More** menu in
**Settings → Computers**.

## Network and egress

On the default Docker provider, a computer has no direct route to the internet. All its traffic
goes through Casama's egress proxy, which:

- Allows outbound HTTP and HTTPS to public addresses.
- Refuses private, loopback, link-local (including cloud metadata), CGNAT, multicast and reserved
  addresses. It checks the address it actually connects to, so DNS tricks can't get around it.
- Has no route for other traffic. SSH and other non-HTTP protocols can't reach the internet, so
  clone repositories over HTTPS.
- Applies per-computer connection and bandwidth rate limits.

Computers can't reach each other or Casama's internal services.

## Use computers from the CLI

The [CLI](/develop/cli) works with the team computer by default, or another one with `--computer`:

```sh
casama computer status                 # list computers and their state
casama computer start                  # wake (restore) the computer
casama computer stop                   # save files and sleep
casama computer shell                  # interactive terminal
casama computer files ls workspace     # also get, put and rm
casama computer checkpoints            # list undo points
casama computer restore <checkpoint-id>
```

## Limits

- The 10 GB disk size isn't enforced yet on the Docker provider.
- Checkpoints save the whole home folder each time rather than only what changed.
- Bots work from the screen's accessibility tree and page snapshots. Screenshots they take are saved
  as files for you and aren't sent to the model as images.
- On E2B and Daytona, computers have their own internet access, so the egress proxy's private-range
  blocking doesn't apply there.
- There's no setting in the app for per-workspace domain allow or deny lists.

## Related

- [Your own computer](/guide/companion)
- [Teach by showing](/guide/teach)
- [Coding agents](/guide/coding-agents)
- [Self-hosting computers](/self-hosting/computers)
- [Autonomy and approvals](/guide/autonomy)
