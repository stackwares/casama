# Projects and the ticket board

**Tasks** is a shared ticket board for people and bots. Assign a ticket to a bot and it starts
working, reports back in comments and moves the ticket along. A **project** keeps one larger piece
of work together: its chat, its plan and to-dos, its files, and everything a bot made for it.

Use tickets for single pieces of work. Use a project for work that takes several files or several
sittings, such as a game, a site or a set of reports.

## The ticket board

Open **Tasks** in the main navigation. On tablets and computers it has one column per status; on
phones, tickets are a list grouped by status:

| Column | Meaning |
| --- | --- |
| **To do** | Not started. |
| **In progress** | Someone, or a bot, is working on it. |
| **In review** | A bot finished and a person should check the result. |
| **Blocked** | Stuck. A failed bot run lands here with a comment saying why. |
| **Done** | Finished. |

Filter the board with **All**, **Mine** or **Bots**, by **Priority**, and by project with the
project picker (**All projects** or one project). To change a ticket's status, long-press it and
drag it to another column; on a phone, long-press it and pick where to move it.

## Create a ticket

1. In **Tasks**, tap **New ticket**.
2. Enter a **Title** and **Details**.
3. Pick a **Priority**: **Urgent**, **High**, **Medium**, **Low** or **No priority**.
4. Under **Assigned to**, pick a bot, or leave it **Unassigned**.
5. Turn on **Needs review** if a person should check the bot's work before it counts as done.
6. Tap **New ticket**.

Bots can create, update, comment on and list tickets too, so you can also ask a bot to "plan this
work on the board".

## When a bot works a ticket

Assigning a bot, when you create a ticket, reassign it, or when another bot assigns it, starts a run
in the ticket's own thread with the bot:

1. The ticket moves to **In progress**.
2. The bot works on it and reports in the ticket's comments.
3. When the run ends, a ticket that's still open moves to **In review** if it needs review,
   otherwise to **Done**. The bot's reply is added as a comment.
4. If the run fails, the ticket moves to **Blocked**, the bot comments why, and the ticket's owner
   gets a notification.

Commenting on a bot's ticket wakes the bot, so you can answer its questions or ask for changes
right there. Moving tickets between columns by hand never wakes a bot.

## The ticket sheet

Tap a ticket to open it. From the sheet you can:

- change its **Status**, **Priority** and **Assigned to** bot,
- assign it to yourself with **Me**,
- turn **Needs review** on or off,
- read and add **Comments**,
- **Open the bot's thread** to see the full conversation,
- **Delete ticket**.

## Projects

A project needs only a name and a bot. It holds:

| Part | Where you see it |
| --- | --- |
| **Project chat** | A topic with the bot. What the bot makes there belongs to the project. |
| **Made in this project** | The sites, games, pictures, videos, documents and files the bot made for it. They are also in the **Library**. |
| **Plan** | The bot's notes on what is done and what is next. |
| **To-dos** | Tickets on the board that belong to the project. |
| **Files** | One folder on the bot's computer for working files such as code. |

You can work on a project in two ways:

- **Together, in its chat.** This is how every new project starts. Nothing happens unless you ask.
- **By itself.** The bot drafts a plan for you to approve, then works in sessions until the goal is
  met. See [Let the bot work on it by itself](#let-the-bot-work-on-it-by-itself).

### Start a project

There are three ways:

- **From a topic.** In a topic, open the chat's **…** menu and tap **Make This a Project**. The
  topic becomes the project's chat, and what the bot already made there is filed under the project.
  General can't become a project.
- **From the list.** In **Tasks**, open the project picker and tap **Manage projects**, then
  **New project**. Enter a **Name**, pick the **Lead bot** and tap **Create Project**. The project
  gets a new topic as its chat.
- **By asking the bot.** Ask for one ("start a project for this"), or let the bot start one when
  the work clearly takes several files. In a topic, the topic becomes the project's chat. In
  General, only what the bot makes in that reply is filed under the project.

### Find a project

- **Library** has a **Projects** row at the top, one card per project. Tap a card to open the
  project, or **See All** for the list.
- A topic that is a project's chat shows a **Project** chip at the top, and **Open Project** in its
  **…** menu.
- Something in the Library shows the project it belongs to. Tap it to open the project.

What belongs to a project still shows in the Library's main grid. To see only one project's things,
open the project and tap **See All** next to **Made in this project**.

### Move something into or out of a project

Things file themselves: whatever a bot makes in a project's chat, or while working on a project,
belongs to it. To change that by hand, open the thing in the **Library**, open its **…** menu and
tap **Move to Project**. Pick a project, or **No Project** to take it out.

### Files and code

The bot keeps a project's working files in one folder on its computer. **Files** on the project
screen opens that folder. It is empty until the bot saves something there.

Code and other working files stay on the computer. They reach the Library when the bot links one in
a reply, or keeps the folder as one zip labelled **Source** (ask it to if it hasn't). Keeping it
again makes a new version of the same item. The Library is kept by the server, so that copy survives
a reset of the computer.

### Finish a project

On a project you work on together, tap **Mark as Done**. Tap **Reopen** to pick it up again.

### Let the bot work on it by itself

Turn on the switch **Let Ada work on it by itself** (it names your bot) on the project screen, or
in the **New project** sheet. It asks for:

1. the **Goal**,
2. **Done when**: how you'll know the project is finished (optional),
3. a **Budget** in dollars (optional).

Tap **Start Planning**. The bot drafts a plan in the project chat: milestones with tickets, who
should do each one, which milestones need your sign-off, and a written plan. You get a notification
when it's ready. Until you approve it, asking the bot to plan again replaces the proposed tickets.
Nothing starts before you approve.

Turn the switch off to go back to working on it together. Nothing more starts by itself; a session
already running finishes. Turning it on again later carries on with the plan you approved.

### Approve and follow along

The project screen shows:

- the status (**Planning**, **Active**, **Paused**, **Blocked**, **Done** or **Cancelled**) and,
  when there is one, the reason,
- **Approve the plan**, while a plan is waiting for you,
- **Pause** or **Resume**,
- **Made in this project**,
- the **Goal**, and spend against the **Budget**,
- **Milestones**, with tickets done out of the total and **Sign off** where one waits for you,
- the **Plan**, the **Tickets** and a **Timeline** of every run,
- **Files**,
- **Project chat**, which opens the conversation with the lead bot.

Tap **Approve the plan** to make the project active.

### How a project runs by itself

Once the plan is approved, Casama checks every active project that works by itself each minute.
When nothing is already running for it, it does the next thing:

1. **Pause** if the project has reached its budget or passed its deadline. You get a note in the
   project chat and a notification.
2. **Close finished milestones.** A milestone that needs sign-off waits for you to tap **Sign off**.
3. **Start a session** for up to 10 ready tickets in the current milestone, highest priority first.
   In a session, the lead bot works on tickets or hands them out to other bots, keeps statuses
   current and updates the plan.
4. **Wrap up.** When every ticket is done, one last session checks the done criteria and marks the
   project **Done**. If the criteria aren't met, the project goes **Blocked** for you to decide.

The lead bot can also pause the project and ask you a question; you get a notification and the
project shows **Blocked** until you answer in the project chat and tap **Resume**.

Sessions are normal runs, so the usual step and time limits apply. Every run for the project counts
toward its spend: sessions, ticket runs, work a bot delegates, and your own messages in the project
chat. Progress is kept in the database, so a project picks up where it left off after a server
restart.

## Who can do what

- A project made from the list is seen by everyone in the workspace.
- A project that grew out of your own chat (made from a topic, or started by a bot there) is seen by
  you and by people who can open that chat.
- Tickets are on the shared board, so everyone in the workspace sees a project's to-dos.
- The project's owner, workspace admins and people who manage the lead bot can approve the plan,
  sign off milestones, pause, resume, finish it and switch working by itself on or off.

## Limits

- The app doesn't set a project's deadline, rename it or cancel it yet. All three are available
  through the [API](/develop/api) (`PATCH /v1/projects/{id}`), which also changes the budget and
  the plan.
- A project has one lead bot, and its chat is with that bot.
- Ticket labels and due dates exist in the API but aren't shown on the board.

## Related

- [Routines](/guide/routines)
- [Bots working together](/guide/bots-together)
- [Usage and budgets](/guide/usage)
- [Group chats](/guide/group-chats)
- [API](/develop/api)
