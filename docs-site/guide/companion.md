# Your own computer

The Casama desktop app for macOS, Windows and Linux can lend your machine to the bots you choose.
They can run commands and edit files in folders you share, use their own browser, use desktop apps
and reach MCP servers running on your machine. Use it when a bot needs your local files, apps or
sign-ins rather than its sandboxed [computer](/guide/computers).

Everything a bot does on your machine shows on screen and can be stopped, and nothing is allowed
until you turn it on.

## Turn it on

1. In the desktop app, open **Settings → Advanced → Use this computer for bots**.
2. Tap **Use this computer for bots** to pair this machine with your account.
3. Under **What Bots May Do**, turn on only the capabilities you want (see below).
4. Under **Shared Folders**, tap **Add a Folder** and pick each folder bots may reach.
5. Under **Bots Allowed**, check each bot that may use this computer.

The switch at the top turns the whole feature on or off without unpairing. Its status reads
**On: bots you allow can use this computer**, **Connecting…**, **Cannot reach Casama; retrying**
or **Off**.

Allowing a bot makes this computer that bot's computer, so its commands, files and browsing happen
here from then on. Unchecking it sends the bot back to its usual computer. The computer appears in
your computer lists as **This device**, with its system (for example `macOS 26.2 · This device`)
and what bots may use on it.

### In the app

From any of your devices, the computer's panel shows **Connected** or **Offline** instead of awake
or asleep. While it's connected you see a screenshot that refreshes every 5 seconds, and **Files**
for your shared folders. You can open, play and list files there yourself, without a bot; changing
files still needs a bot you allowed. The panel offers only what works on your own computer, so
there's no live view, terminal, restore points or sleep. When it's offline, it says to open Casama
on that computer and turn the setting on.

To stop for good, tap **Stop using this computer and unpair it** at the bottom of the screen.

::: tip
The app needs to be running and online for bots to reach your computer. Your computer never
sleeps the way a sandboxed computer does, and bots get a clear error when it's offline.
:::

## Capabilities

Each capability is off until you approve it.

| Capability | What bots can do |
| --- | --- |
| **Run commands (inside shared folders)** | Run shell commands. The working folder must be inside a shared folder. |
| **Read and edit files in shared folders** | Read, write and search files, only inside shared folders. |
| **Use a browser (its own, separate from yours)** | Drive a browser session of its own. It never touches your other browser sessions. |
| **Use desktop apps** | Open and operate apps on your desktop. |
| **Local tools (MCP)** | Call MCP servers you add on this computer. |
| **Messages (iMessage)** | Mac only. Read and send iMessages for a connected iMessage chat app. |

High-risk actions on your own computer, such as deleting files outside the bot's workspace, ask for
your approval under **Ask before acting** and **Ask for risky actions**. They run without asking
when the bot is set to **Act on its own**, when you tapped **Always Allow** for that tool, or when
the workspace has [full access](/guide/autonomy#full-access) on.

## Shared folders

Bots can only reach the folders you share. File paths and working folders are checked against
them, with symbolic links resolved, so a link can't point a bot outside a shared folder. Remove a
folder with the **x** next to it.

## The overlay and Stop

While a bot acts on your computer, a bar stays on top of your windows: "{bot} is working on this
computer: {action}". Tap **Stop** to cancel that bot's run immediately. The tray icon (Windows and
Linux) lists every bot at work, with **Stop**, **Allow** and **Deny** (see
[Windows and Linux: the tray](/guide/notch#windows-and-linux-the-tray)). On a Mac, the notch and the menu bar show it instead: see
[Bots in the notch and menu bar](/guide/notch).

## Local MCP servers

Bots can use MCP servers that run on your machine, such as tools for a design app or a coding agent,
without exposing them to the internet. Tokens and environment values stay on your computer.

1. Turn on **Local tools (MCP)** under **What Bots May Do**.
2. Under **Local Tools (MCP)**, tap **Add a Local MCP Server**.
3. Enter a **Name**, then choose how to reach the server:
   - **A Command**: the **Command** that starts it, for example `npx -y @example/mcp-server`. You
     can pick a **Working Folder (Optional)** inside a shared folder and add **Environment** values,
     one `KEY=value` per line.
   - **An Address**: an **Address** such as `http://127.0.0.1:3845/mcp`, then how it signs in (see
     below).
4. Tap **Add a Local MCP Server**.

### Signing in to an address

Under **Sign-In**, pick what the server asks for:

- **None**: it needs nothing.
- **Token**: paste the token. It's sent as `Authorization: Bearer <token>`.
- **Header**: a header name and value, such as `X-API-Key`.
- **Browser**: Casama opens your browser so you can sign in and approve it, the way T3 Code and
  many hosted servers work. Casama refreshes the sign-in by itself. If it runs out, the row says
  **Needs sign-in** and a bot that tries the server shows a card in chat. Tap **Sign In** on the
  row, or on the card on this computer.

Tokens, header values and sign-ins stay in the app's secure storage on this computer. Your
workspace only knows which kind of sign-in a server uses.

### Addresses on your network

An address on this computer (`127.0.0.1`, `localhost`, `::1`) works as is. You can also add a
server elsewhere on your network, such as `http://192.168.1.20:8080/mcp`, or an `https` address
anywhere. The form warns you first: bots that can use this computer can then reach that server
through it. Plain `http` is accepted only for local network addresses.

Servers that only speak the older HTTP+SSE transport (often with an address ending in `/sse`) work
too.

### Add from other apps

Tap the download icon (**Add From Other Apps**) next to **Add** to find servers you already set up in T3 Code, Claude Code,
Claude Desktop, Cursor, VS Code, Codex or Windsurf. Pick the ones to add. If those settings only
refer to a value, such as `${GITHUB_TOKEN}`, and it isn't set, type it in. Servers on the internet
aren't picked by default: they're usually better as a workspace connection. T3 Code is added with
browser sign-in, and if its address changes, Casama follows it.

### Questions from a server

Some servers ask you something in the middle of a task, such as which environment to deploy to.
The question shows as a card in the chat with the server's form. **Send** your answer or
**Decline**. The bot's call waits up to 10 minutes; after that, or if the run stops, the question
closes. Only the person who started the chat or a workspace admin can answer. Your answer goes to
the server and isn't kept. This works for hosted MCP connections too.

How it works:

- A command-based server starts the first time a bot uses it and stops after 10 idle minutes.
- New servers are attached to the bots this computer allows. Only you can attach them to other bots.
- The command is visible to your workspace. Environment values are kept in the app's secure storage
  and never leave your machine.
- A call can run up to 30 minutes by default and stays alive while the server reports progress.
  Progress shows in the bot's timeline, and cancelling the run cancels the call.
- If your computer is offline, the bot gets a clear error and the server stays connected for next
  time.
- Bots can use local MCP servers from any device, including phones and the web, while this
  computer is online. Adding one works only in the desktop app.

For hosted MCP servers and connecting AI apps to Casama, see [MCP](/guide/mcp).

## Coding agents

The **Coding Agents** section lists the coding agents the app finds on this computer: Claude Code
(`claude`), Codex (`codex`), Cursor's command-line agent (`cursor-agent`), Pi (`pi`), T3 Code
(`t3`), Kimi Code (`kimi`) and any others on Casama's list, which comes from the server, so new
agents appear without an app update. Bots can hand coding tasks to them, and they run with your
own sign-ins in your shared folders.

Coding agents run as commands, so they need **Run commands** turned on. If it's off, tap
**Turn On** in this section. An agent with **Allow** next to it hasn't run on this computer yet:
tap it once and bots can hand it tasks.

**Add Your Own** adds an agent Casama doesn't list: a name, the command with `{task}`, how to read
its answer and a time limit, with a **Test** that asks it to reply "pong". Your own agents show a
**Yours** label, run only on this computer and only for you, and nobody else in the workspace can
see or change them. See [Coding agents](/guide/coding-agents).

## Desktop context in Quick ask

Press Cmd+Shift+K on macOS or Ctrl+Shift+K on Windows and Linux to open **Quick ask** from
anywhere. Just before Casama's window comes forward, the app reads what you were looking at:

- the app and window title in front,
- the text you had selected (**Selected Text**),
- the current browser tab's title and address.

Each part appears as a chip you can switch off before sending. The parts you keep are added after
your message. Tap **Add a Screenshot** to include an image of your screen; Casama's window steps
aside while it's taken, and the image is uploaded to the bot's computer like a chat attachment.

Context is read only when you press the shortcut and used once. Missing tools or permissions mean
less context, not an error.

| Platform | Where it reads from |
| --- | --- |
| macOS | System Events for the app and window, the Accessibility selection, and Chrome, Arc, Brave, Edge, Vivaldi, Opera or Safari for the tab |
| Windows | The foreground window, and UI Automation for the selection |
| Linux | `xdotool` and the primary selection |

On macOS, the selection and window title need Accessibility permission, the browser tab needs
permission to control the browser (Automation), and screenshots need Screen Recording permission.

## Turning permissions on

When a bot needs a permission you haven't turned on, such as Accessibility or Screen Recording on
a Mac, it shows a card in the chat with a button for each one. Tap a button and Casama shows the
system's prompt, or opens the exact page in System Settings with the switch. You always flip the
switch yourself; nothing can turn a permission on for you. Each row turns to On as soon as the
computer sees the change. Screen Recording takes effect after Casama restarts, so its row offers a
Restart button. When everything is on, Continue tells the bot to carry on.

The card works from any of your devices: tap it on your phone and the page opens on your Mac.
Not now stops that bot asking for the same permission on that computer for a day. You can see and
change every permission for the device you're on in Settings → Permissions.

## Search files on your computer

When a bot works on your computer, it can search for files, only inside your
shared folders. It uses Spotlight on macOS, the Windows Search index on Windows, and `locate` (or
`find`) on Linux. Results are filtered to your shared folders again on the server before the bot
sees them.

## Watched folders and activity

Two related features live under **Settings → Advanced → Device connections**:

- **Watched Folders**: a new file in a folder you pick can start a routine, such as "file new PDFs
  in Downloads". The app waits until the file stops growing and skips partial downloads and hidden
  files. Only the folder and file names are shared. See [Routines](/guide/routines#device-triggers).
- **Computer activity** (off by default): an hourly summary of which apps you used and for how
  long, for end-of-day recaps and time tracking. It never includes selections, screenshots or
  keystrokes. See [Devices](/guide/devices).

## iMessage

iMessage has no bot API, so your own Mac does the work.

1. On your Mac, in **Settings → Advanced → Use this computer for bots**, turn on **Messages
   (iMessage)**.
2. Give Casama Full Disk Access in macOS System Settings, so it can read your Messages history.
3. Connect an iMessage chat app on the bot. See [Chat apps](/guide/chat-apps).

Casama checks for new messages every minute through your Mac and sends replies with AppleScript.
The first check only records where to start, so old messages are never answered. Only the Mac's
owner can connect it, and only for a bot allowed on that Mac.

## Limits

- Your own computer has no live view, terminal, checkpoints or sleep. Those need a sandboxed
  computer.
- iMessage is text only (no attachments or images), and group chats aren't supported.
- Coding agents and local MCP servers need the desktop app running and online.
- On a Mac, this needs the app from [casama.ai/download](https://casama.ai/download). The Mac App
  Store version runs in Apple's sandbox, which doesn't allow running commands or starting a browser
  outside the app, so it can't lend your Mac to bots. See
  [which Mac app to get](/faq#should-i-get-the-mac-app-from-the-website-or-the-mac-app-store).
- Not yet: the Windows browser tab in Quick ask context, and macOS Calendar and Reminders.

## Related

- [Computers](/guide/computers)
- [Coding agents](/guide/coding-agents)
- [MCP](/guide/mcp)
- [Chat apps](/guide/chat-apps)
- [Devices](/guide/devices)
