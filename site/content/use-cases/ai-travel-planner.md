---
title: AI travel planner that builds the trip and asks before paying
h1: An AI travel planner that builds the trip and asks before paying
card: Travel
crumb: Travel
description: A Casama bot plans trips day by day with real travel times, rough costs and links to official sites. It lists what to book, and every payment asks first.
lead: Planning a trip means twenty browser tabs and a spreadsheet. A Casama bot opens the tabs on its own computer and hands you a day-by-day plan with links. Booking and paying stay under your control.
updated: 2026-11-18
order: 13
---

## What the bot does

- **Asks first.** Dates, budget, pace, interests and who is travelling.
- **Builds the itinerary.** Day by day, with realistic travel times, a few options per day and
  rough costs.
- **Links to official sites.** For opening hours, tickets and entry requirements, and says what to
  double-check.
- **Lists what to book and when.** In the order that matters, such as the train before the museum
  slot.
- **Makes the packing list.** For the place, the season and the people.
- **Remembers.** That you want an aisle seat, a late start and no more than one museum a day.

## Where it stops to ask

- **Booking.** The built-in Travel persona is told never to book or pay for anything. It lists
  what to book, and you book it.
- **Paying.** If you change the instructions so the bot may fill in a booking form in its own
  browser, every payment still asks first, whatever its settings.
- **Signing in.** At a password or a two-step code, the bot asks you to take over its screen. You
  sign in yourself, and nothing you type reaches the bot.
- Sending email, such as a question to a hotel, under the default setting.

You set these rules per bot and per action. See [how approvals work](/security).

## What it looks like

An example trip:

1. You: "Plan five relaxed days in Lisbon in May for two. Mid-range budget. We like food and
   walking."
2. The bot asks about your arrival time and whether you want a day trip.
3. It reads official sites and returns five days, each with a morning, an afternoon and two dinner
   options, with walking times between them.
4. It lists four things to book now and two that can wait, with links.
5. You ask it to swap day two and day four because of a closing day it flagged. It updates the
   plan.

## Why its own computer matters

Each Casama bot works on a sandboxed Linux machine of its own, with a browser, files and a shell.
It keeps going when you close your laptop, it can't reach your own files, and you can watch its
screen or take over at any time. Before a command that deletes data, its computer is saved, so the
work can be undone.

For travel this matters in one more way. The bot's browser keeps its sign-ins, so once you have
signed in to a booking site on its computer, it stays signed in there and not on your laptop.

## Set it up

1. Create a bot with the **Travel** persona.
2. Tell it how you travel: budget, pace, seats, food, what you never want.
3. Ask for a trip. Read the plan and check the things it says to double-check.
4. If you want it to prepare bookings, edit its instructions to allow filling in forms, and add
   an action rule for **Payments** set to **Hand it to me to finish** if you would rather type
   the card yourself.

Ready-made skills, starter bots and routines are in the [gallery](https://gallery.casama.ai).

## What it won't do for you

- Prices and opening hours change. The bot links to the source so you can check on the day.
- It can get a travel time or an entry rule wrong. Confirm visas and entry requirements with the
  official site.
- Paying through Casama needs the workspace owner to set up payments first. Without that, the bot
  prepares the booking and you pay.

## Questions

### Can it book flights and hotels?

Not with the built-in persona, which only plans. With changed instructions a bot can fill in a
booking form in its own browser. Paying always asks, and you can take over the screen to finish
yourself.

### Does the bot see my card number?

No. When payments are set up, each approved purchase gets a single-use virtual card, and the bot
handles placeholders, not card details.

### Can it tell me when to leave for the airport?

A routine can run when it is time to leave for your next calendar event that has a location. It
needs your places set up, a connected calendar and a maps key on the server.

### Can it plan for a group?

Yes. Tell it who is travelling and what each person needs.

See [what else Casama bots do](/use-cases/).

{{cta}}
