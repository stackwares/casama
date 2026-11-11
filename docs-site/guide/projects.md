# Projects and the ticket board

The **Board** is a shared ticket board for people and bots. Assign a ticket to a bot and it starts
working, reports back in comments and moves the ticket along. A **project** goes further: give a
lead bot a goal, approve the plan it drafts, and it works through milestones and tickets in
sessions until the goal is done, within the budget and deadline you set.

Use tickets for single pieces of work. Use a project for a larger goal that takes many steps over
days.

## The ticket board

Open **Board** in the main navigation. It has one column per status:

| Column | Meaning |
| --- | --- |
| **To do** | Not started. |
| **In progress** | Someone, or a bot, is working on it. |
| **In review** | A bot finished and a person should check the result. |
| **Blocked** | Stuck. A failed bot run lands here with a comment saying why. |
| **Done** | Finished. |

Filter the board with **All**, **Mine** or **Bots**, and by **Priority**. Long-press a ticket and
drag it to another column to change its status.

## Create a ticket

1. In **Board**, tap **New ticket**.
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

A project has a goal, done criteria, a lead bot, and optionally a budget. The lead bot plans the
work as milestones, each with tickets, and nothing starts until you approve the plan.

### Start a project

1. In **Board**, tap **Projects** (the target icon), then **New project**.
2. Enter a **Title** and the **Goal**.
3. Describe **Done when**: how you'll know the project is finished.
4. Pick the **Lead bot**.
5. Optionally set a **Budget** in dollars.
6. Tap **Start planning**.

The lead bot drafts a plan in the project chat: milestones with tickets, who should do each one,
which milestones need your sign-off, and a written plan. You get a notification when it's ready.
Until you approve it, asking the bot to plan again replaces the proposed tickets.

### Approve and follow along

Open the project from **Board → Projects**. The project screen shows:

- the status (**Planning**, **Active**, **Paused**, **Blocked**, **Done** or **Cancelled**) and,
  when there is one, the reason,
- **Approve the plan**, while a plan is waiting for you,
- **Pause** or **Resume**,
- the **Goal**, and spend against the **Budget**,
- **Milestones**, with tickets done out of the total and **Sign off** where one waits for you,
- the **Plan**, the **Tickets** and a **Timeline** of every run,
- **Project chat**, which opens the conversation with the lead bot.

Tap **Approve the plan** to make the project active.

### How a project runs

Once the plan is approved, Kasama checks every active project each minute. When nothing is already
running for it, it does the next thing:

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

Sessions are normal runs, so the usual step and time limits apply. Every run started for the
project, including ticket runs and work a bot delegates, counts toward its spend. Progress is kept
in the database, so a project picks up where it left off after a server restart.

## Who can do what

- Everyone in the workspace can see projects and their tickets.
- The project's owner, workspace admins and people who manage the lead bot can approve the plan,
  sign off milestones, pause and resume.

## Limits

- The app doesn't set a project's deadline or cancel a project yet. Both are available through the
  [API](/develop/api) (`PATCH /v1/projects/{id}`), which also changes the budget and the plan.
- Ticket labels and due dates exist in the API but aren't shown on the board.

## Related

- [Routines](/guide/routines)
- [Bots working together](/guide/bots-together)
- [Usage and budgets](/guide/usage)
- [Group chats](/guide/group-chats)
- [API](/develop/api)
