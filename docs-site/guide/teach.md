# Teach by showing

Instead of writing instructions, you can show a bot how to do a task. Do it yourself once on the
bot's desktop computer while Casama records each step, and the bot turns the recording into a
[skill](/guide/skills) it can reuse. You can also save the steps as a replay that runs without the
model, which is faster and cheaper for tasks that don't change.

## Before you start

- The bot needs a desktop [computer](/guide/computers). On a headless computer, use **Switch to
  Desktop** first.
- Teaching happens in the live view, and only while you're in control.

## Teach a task

1. Open the bot's computer and tap **Open Live View**.
2. Tap **Take Control**.
3. Open **More** (**⋯**) and tap **Teach a task**. On a team computer, pick **Which bot should
   learn this?**
4. A red **Recording** banner appears. Do the task as you normally would. The banner shows the last
   step it saved.
5. If you type something sensitive that isn't in a password field, tap **Mark as Secret** right
   after typing it, give it a **Name** such as `EMPLOYEE_ID`, and tap **Save**.
6. Tap **Stop** when you're done.

The bot then writes a draft skill from your recording in a new chat called "Teach: draft a skill",
and the app opens the **New skill** screen while it works ("Writing a skill from your
recording…").

## Review and save the skill

The **New skill** screen shows the bot's draft:

- **Name (lowercase, dashes)** and **One-line description**,
- **Instructions**, including an Inputs section and a Success checks section,
- **What you showed**: the recorded steps, with secrets shown by name only.

Check the steps, inputs and success checks, then choose:

| Button | What it does |
| --- | --- |
| **Save** | Adds the skill to the bot. |
| **Save and try** | Adds the skill and opens a chat asking the bot to use it now. |
| **Also save as a replay** | Saves the recording as a replay too (see below). |
| **Discard** | Deletes the recording: every step, snapshot and screenshot it captured. |

If the bot couldn't write a draft, the screen says so. You can still write the skill yourself from
the recorded steps, or discard it.

## What gets recorded

| You do | Recorded as |
| --- | --- |
| Click | One step, at that position. |
| Type | One step, until you click, press a special key or pause for 1.5 seconds. |
| Scroll | Grouped into one step, the same way as typing. |
| Special keys and shortcuts | Their own step, such as `Tab` or `Ctrl+c`. |

After each step, Casama captures what the screen looks like: the accessibility snapshot of the
desktop (or the bot's browser), the browser's address and a screenshot. Anything it can't capture
is skipped.

## Privacy and secrets

Live view normally keeps everything you do away from the bot. Teaching is the one exception, and
Casama makes it obvious:

- Recording runs only while you hold control, and each step checks that again. If you lose control,
  recording stops.
- The red **Recording** banner with **Stop** stays on screen the whole time.
- Text typed into a password field is never stored. The step becomes a named placeholder such as
  `{{secret:PASSWORD}}`, and the bot asks for the value when it uses the skill.
- **Mark as secret** deletes the text you last typed from the recording and turns it into a named
  secret input. You can only mark secrets before **Stop**, because **Stop** sends the recording to
  the model.
- Only you can see your recordings. Starting a recording is written to the workspace's audit log.
- One recording at a time per computer.

The bot gets the recording as text: steps grouped by page address, each with the start of the
screen snapshot after it. Screenshots are kept for you but aren't sent to the model.

## Replays

A replay is a recorded set of browser or desktop steps that the bot runs as is, without calling the
model. It's faster and cheaper than having the bot work the task out each time. If a step doesn't
work any more, the bot takes over from that step and can update the replay.

Each step can carry:

- **Parameters** for values that change between runs, with defaults.
- **Secrets** as `{{secret:NAME}}` placeholders, each limited to the site it belongs to.
- **Targets** found by an element's role and label rather than by position, so the step still works
  when the page reloads.
- **Checks**, such as "the address contains..." or "the screen shows...".

### Save a replay

- **From a teach recording:** tap **Also save as a replay** on the **New skill** screen. Clicks
  become clicks at the recorded position, typed text becomes a parameter with what you typed as its
  default (secrets stay placeholders), and each page address becomes a check.
- **From a chat:** after the bot does a browser or desktop task, ask it to save the steps it took as
  a replay. It saves the steps with targets, checks and parameters, and refuses to store plain text
  typed into password fields.

### Run a replay

1. Open the bot's **Bot profile → Replays**.
2. Tap **Run** on the replay.
3. Check the values it fills in, then run it. The run's chat opens.

The bot can also run a replay itself during a chat. Each replay shows how many steps it has, how
many times it's run and how many runs needed help.

### When a step fails

A missing element, a failed check or a tool error stops the replay at that step. The bot gets where
and why it stopped, plus what was already done, and carries on from there with the model. It can
then offer to update the replay. A replay run still passes through your approval rules as usual.

To delete a replay, use **Delete** in **Bot profile → Replays**.

## Limits

- Teaching needs a desktop computer and the live view.
- Clicks recorded from a teach recording are screen positions, not elements, so they're usually the
  first thing to need the bot's help when a screen changes. Replays the bot saves from a chat use
  elements instead.
- Screenshots from a recording aren't sent to the model yet.
- Password manager items in replays aren't supported yet.

## Related

- [Skills](/guide/skills)
- [Computers](/guide/computers)
- [Autonomy and approvals](/guide/autonomy)
- [Routines](/guide/routines)
