# Your own computer

The Kasama desktop app for macOS, Windows and Linux can lend your machine to the bots you choose.
They can run commands and edit files in folders you share, use their own browser, use desktop apps
and reach MCP servers running on your machine. Use it when a bot needs your local files, apps or
sign-ins rather than its sandboxed [computer](/guide/computers).

Everything a bot does on your machine shows on screen and can be stopped, and nothing is allowed
until you turn it on.

## Turn it on

1. In the desktop app, open **Settings → Use this computer for bots**.
2. Tap **Use this computer for bots** to pair this machine with your account.
3. Under **What bots may do**, turn on only the capabilities you want (see below).
4. Under **Shared folders**, tap **Add a folder** and pick each folder bots may reach.
5. Under **Bots allowed**, check each bot that may use this computer.

The switch at the top turns the whole feature on or off without unpairing. Its status reads
**On: bots you allow can use this computer**, **Connecting…**, **Cannot reach Kasama; retrying**
or **Off**.

Allowing a bot makes this computer that bot's computer, so its commands, files and browsing happen
here from then on. Unchecking it sends the bot back to its usual computer. The computer appears in
your computer lists as **This device**.

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

High-risk actions always ask for your approval on your own computer, whatever the bot's
[autonomy](/guide/autonomy) setting.

## Shared folders

Bots can only reach the folders you share. File paths and working folders are checked against
them, with symbolic links resolved, so a link can't point a bot outside a shared folder. Remove a
folder with the **x** next to it.

## The overlay and Stop

While a bot acts on your computer, a bar stays on top of your windows: "{bot} is working on this
computer: {action}". Tap **Stop** to cancel that bot's run immediately. The tray or menu bar icon
also shows which bot is acting.

## Local MCP servers

Bots can use MCP servers that run on your machine, such as tools for a design app or a coding agent,
without exposing them to the internet. Tokens and environment values stay on your computer.

1. Turn on **Local tools (MCP)** under **What bots may do**.
2. Under **Local tools (MCP)**, tap **Add a local MCP server**.
3. Enter a **Name**, then choose how to reach the server:
   - **A command**: the **Command** that starts it, for example `npx -y @example/mcp-server`. You
     can pick a **Working folder (optional)** inside a shared folder and add **Environment** values,
     one `KEY=value` per line.
   - **An address on this computer**: an **Address** such as `http://127.0.0.1:3845/mcp`. Only
     `127.0.0.1` and `::1` are accepted.
4. Tap **Add a local MCP server**.

How it works:

- A command-based server starts the first time a bot uses it and stops after 10 idle minutes.
- New servers are attached to the bots this computer allows. Only you can attach them to other bots.
- The command is visible to your workspace. Environment values are kept in the app's secure storage
  and never leave your machine.
- A call can run up to 30 minutes by default and stays alive while the server reports progress.
  Progress shows in the bot's timeline, and cancelling the run cancels the call.
- If your computer is offline, the bot gets a clear error and the server stays connected for next
  time.

For hosted MCP servers and connecting AI apps to Kasama, see [MCP](/guide/mcp).

## Coding agents

The **Coding agents** section lists the coding agents the app finds on this computer: Claude Code
(`claude`), Codex (`codex`) and Cursor's command-line agent (`cursor-agent`). Bots can hand coding
tasks to them, and they run with your own sign-ins in your shared folders.

Coding agents run as commands, so they need **Run commands** turned on. If it's off, tap
**Turn on** in this section. See [Coding agents](/guide/coding-agents).

## Desktop context in Quick ask

Press Cmd+Shift+K on macOS or Ctrl+Shift+K on Windows and Linux to open **Quick ask** from
anywhere. Just before Kasama's window comes forward, the app reads what you were looking at:

- the app and window title in front,
- the text you had selected (**Selected text**),
- the current browser tab's title and address.

Each part appears as a chip you can switch off before sending. The parts you keep are added after
your message. Tap **Add a screenshot** to include an image of your screen; Kasama's window steps
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

## Search files on your computer

When a bot works on your computer, it can search for files, only inside your
shared folders. It uses Spotlight on macOS, the Windows Search index on Windows, and `locate` (or
`find`) on Linux. Results are filtered to your shared folders again on the server before the bot
sees them.

## Watched folders and activity

Two related features live under **Settings → Device connections**:

- **Watched folders**: a new file in a folder you pick can start a routine, such as "file new PDFs
  in Downloads". The app waits until the file stops growing and skips partial downloads and hidden
  files. Only the folder and file names are shared. See [Routines](/guide/routines#device-triggers).
- **Computer activity** (off by default): an hourly summary of which apps you used and for how
  long, for end-of-day recaps and time tracking. It never includes selections, screenshots or
  keystrokes. See [Devices](/guide/devices).

## iMessage

iMessage has no bot API, so your own Mac does the work.

1. On your Mac, in **Settings → Use this computer for bots**, turn on **Messages (iMessage)**.
2. Give Kasama Full Disk Access in macOS System Settings, so it can read your Messages history.
3. Connect an iMessage chat app on the bot. See [Chat apps](/guide/chat-apps).

Kasama checks for new messages every minute through your Mac and sends replies with AppleScript.
The first check only records where to start, so old messages are never answered. Only the Mac's
owner can connect it, and only for a bot allowed on that Mac.

## Limits

- Your own computer has no live view, terminal, checkpoints or sleep. Those need a sandboxed
  computer.
- iMessage is text only (no attachments or images), and group chats aren't supported.
- Coding agents and local MCP servers need the desktop app running and online.
- The macOS app is distributed with Developer ID signing rather than through the Mac App Store,
  because it needs to run commands and start a browser outside an app sandbox.
- Not yet: the Windows browser tab in Quick ask context, and macOS Calendar and Reminders.

## Related

- [Computers](/guide/computers)
- [Coding agents](/guide/coding-agents)
- [MCP](/guide/mcp)
- [Chat apps](/guide/chat-apps)
- [Devices](/guide/devices)
