# Deploys nobody notices

Status: built 2026-11-18 as D-402 (Oliver: "build all in 1 go now"), with the recommended answers:
Phase 4 option A, 10 minutes of call handover. Phases 1 to 6 are in the working tree; Phase 3b (start
the new worker first) is not built. Not committed, pushed or deployed; the app changes need a build.
What was built, and what was checked, is in `docs/DECISIONS.md` under D-402.

## Why

Oliver asked whether every server deploy interrupts people and bots, then asked for a deeper look
at how to deploy without that. This is what a deploy does today, measured from the code and from
production (read-only), and a plan to remove the interruptions in order of payoff.

## What a deploy does today

`scripts/deploy-prod.sh` runs `compose up -d`, which stops the API and worker containers and starts
new ones. Nothing else restarts unless its own image or config changed.

**How often and how long**

- 50 deploys between 16 and 18 November, about 17 a day.
- The new API needs 7.8 s from container start to "api listening" (measured on the deploy at
  11:41 UTC on 18 November). The old one takes up to 5 s to stop. So the API is unreachable for
  roughly 9 to 14 s per deploy. That is an estimate from the two halves, not an end-to-end
  measurement. At 17 deploys a day it adds up to about 3 minutes a day.
- The worker needs about 7 s to start.

**While the API is unreachable**

| What the person is doing | What happens |
| --- | --- |
| Sends a message | The bubble says "Not sent" with a Retry button. Nothing retries by itself (`chat_controller.dart:1032`). |
| Opens a screen, pulls to refresh | An error, and the "can't reach the server" bar (`server_reachability.dart:44`). The app's HTTP client has no retry. |
| Watches a reply stream in | Keeps working. The text arrives over Supabase Realtime, which a deploy doesn't restart. |
| Is on a voice call paid from credits | The call's socket goes through the API's relay (D-333), so it is cut. The app tries to resume once, at once (`gemini_live.dart:476`), the API isn't back yet, and the call ends. |
| Is on a voice call on their own key | Nothing. That socket goes straight to Google. A tool the bot uses during the gap fails with "The tool could not run." |
| Watches a computer's live view | "Reconnecting…", then live again (D-360). |
| Has the terminal open | "Disconnected". Pressing Connect starts a new shell. |
| Desktop app sharing a Mac | Redials after 1 s. |
| Island and menu bar | Drops a run after three missed reads, about 9 s (`run_tracker.dart:215`). |
| A phone call through Twilio, when that's on | Cut, and a phone call can't resume. |
| Telegram, WhatsApp, billing webhooks | Get a 502. The sender tries again later. |

**While the worker restarts**

- Runs are durable workflows (DBOS). Every model call and tool call is a saved step, and the new
  worker picks up every unfinished run when it starts.
- The worker stops without waiting: `DBOS.shutdown()` is called with no drain, so a step in flight
  is cut. The new worker runs that step again. A model call starts over. A tool that only looks
  runs again. A tool that changes something tells the bot "Casama restarted while this action was
  running, so it may or may not have happened" (D-268).
- **A run replayed on changed code can fail.** When the new build changes the steps a run already
  went through, the replay doesn't match and the run ends with "Casama was updated while this was
  waiting, so it stopped. Send your message again." Two of the nine failed runs in the last three
  days were this:
  - 17 Nov 06:31 run. The deploy waited for it. The moment it paused to ask for an approval
    (06:40:31) the deploy stopped counting it, went ahead, and the run died at 06:41:38.
  - 17 Nov 09:55 run. It had been waiting on the person for 87 minutes. The 11:22 deploy killed it
    47 s later.
- The script's wait for runs has three gaps:
  - It counts only runs that are working, not runs waiting on a person.
  - It runs before the backup and the build, so a run that starts during those isn't waited for.
  - It needs a moment with no run at all. With 241 runs in three days that works. With real traffic
    there will never be such a moment, and deploys will either block for 10 minutes or be forced.

## What we want

1. No request fails because of a deploy.
2. No run is cut in the middle of a step, and deploys don't wait for a quiet moment.
3. A run waiting on a person survives a deploy.
4. A call survives a deploy.

## The plan

Phases 1 to 4 are server-only and need no app build. Each one stands alone, so we can stop after
any of them.

### Phase 1: no failed requests

Small, mostly config. About half a day.

1. **Caddy holds requests while the API is away.** Add `lb_try_duration 30s` and
   `lb_try_interval 250ms` to the three `reverse_proxy api:…` blocks in
   `infra/compose/selfhost/Caddyfile` and the one in `sites-edge-true.caddy`. A request that
   arrives during the gap waits and then goes through. Caddy only waits when it can't connect at
   all, so nothing is ever sent twice. Self-hosters get it too.
2. **Reorder the script:** fast-forward, build, back up, then wait for runs, then restart. The
   window where a new run can slip in drops from minutes to about a second.
3. **The dry run says how many runs are waiting on a person**, since those are the ones a deploy
   can kill today.
4. **The API says "restarting" to every socket.** Live views and desktop apps already get close
   code 1012. The call relay, the terminal and the phone bridge get it too, and the relay saves its
   last seconds of usage before the process exits.

What people notice after: a message sent during a deploy takes up to about 12 s longer instead of
failing. Screens load slowly instead of erroring. A credit call's one resume attempt is held by
Caddy and reaches the new API, so the call goes quiet for about 10 s and continues instead of
ending.

Loading the new Caddy config needs one Caddy restart, which is a 1 to 2 s blip for everything
behind it, including sign-in and Realtime. The script already does this when the Caddyfile changes.

### Phase 2: the new API starts before the old one stops

One to two days with testing on the local stack.

1. **Deploy script:** start a second API container on the new image
   (`compose up -d --no-deps --no-recreate --scale api=2 api`), wait until it answers `/readyz`,
   then stop the old one. The script finds containers by their compose service, not by the name
   `casama-api-1`.
2. **Old API on stop:** stops accepting new connections first, lets requests in flight finish
   (30 s, not today's 5 s), then closes its sockets with 1012.
3. **Calls finish on the old API.** After it stops accepting connections, the old API stays up
   while it still carries a call relay or a phone bridge, for up to 10 minutes. Then it closes them
   with 1012 and the app resumes on the new API. This is the only way a Twilio phone call survives
   a deploy, and it needs no app change. A deploy that finds an old API still lingering from the
   previous deploy stops it first.
4. **State that lives in one API process** has to be handled for the seconds two run side by side:
   - Desktop app sockets (`DeviceRegistry`). The worker reaches a shared Mac through
     `http://api:8787/internal/local/…`, which can land on the API that doesn't hold the socket.
     The old API closes those sockets as soon as the new one is ready, and the worker's existing
     grace period for a reconnecting computer covers the rest.
   - Live view pairing: a view opened in those seconds may need its one redial.
   - In-memory rate limits reset, as they do today.

The Helm chart already runs two API replicas, so two at once is a supported shape.

What people notice after: nothing for requests. Sockets other than calls reconnect in about a
second. Calls aren't touched unless they outlast the 10 minutes.

### Phase 3: the worker finishes the step, then hands over

One to two days with tests.

1. **On stop, no new step starts.** A gate in the step wrapper (`runAgentDurably` in
   `apps/server/src/worker/workflows.ts`) holds every run at its next step boundary. Steps in flight
   finish and are saved. The worker exits when none are left, or after 45 s. Compose gives it
   `stop_grace_period: 60s`.
2. **The new worker continues each run at its next step.** Nothing runs twice, nothing is cut.
3. **Steps longer than 45 s** (a long command on a computer) are cut as they are today, with the
   D-268 protections. If a model call is cut, the half-written draft has to be taken back before the
   step runs again. I haven't confirmed what the chat shows for that today; it's on the check list.
4. **The script stops waiting for runs.** `--wait-runs` stays as an option.

What people notice after: a reply that is mid-work during a deploy pauses for up to about 20 s
between two steps, then carries on. A message sent in that window starts up to 20 s late. No deploy
waits 10 minutes.

**Later, 3b: start the new worker first.** Then new messages start at once and the pause goes away.
It needs a short trial first, because two workers at once is new ground here:

- Each worker needs its own executor ID. Today both would be `local`, and a worker that starts
  re-queues every unfinished run with its ID, including ones the other worker is still running.
- After the old worker exits, its leftover runs have to be re-queued for the new one. DBOS does
  that with one database call (`reenqueueWorkflowsForRecovery`).
- Every loop in the worker has to be safe twice over (the account email outbox, the minute ticks).

Side finding, not verified in a cluster: the Helm chart's worker uses Kubernetes' default rolling
update, which starts the new worker pod before stopping the old one, so the two-workers problem
above may already exist for Kubernetes self-hosters. `strategy: Recreate` on the worker Deployment
is the safe setting until 3b exists.

### Phase 4: a waiting run survives a deploy

This is the failure that already hit real runs twice. Three ways to fix it:

- **A. Continue automatically (recommended, about a day).** When a run dies because the replay
  doesn't match, the worker starts a new run in the same chat with a note that it was interrupted by
  an update and should carry on from what the chat already shows. The person doesn't resend
  anything. A pending approval is asked again.
- **B. Save steps by name, not by position.** A step added or removed by a new build then no
  longer breaks older runs. This is the real fix, and it is a redesign of how runs are saved,
  including the waits. Worth doing only if A's repeated approvals turn out to bother people.
- **C. Guard every change to the run loop with a version check** (DBOS patching). Not recommended:
  it depends on every change, by every agent, being careful forever.

### Phase 5: the app, with the next builds

1. **Calls:** retry the resume for about 30 s (0.5, 1, 2, 4, 8, 15 s) instead of once. A safety net
   for crashes and for calls that outlast Phase 2's 10 minutes.
2. **"Not sent" retries by itself** on a connection failure. That needs an idempotency key on
   `sendMessage` so a retry can never post twice; the server side of that is small.
3. **Terminal reconnects by itself** on 1012.
4. **Island and menu bar** tolerate a longer gap before dropping a run.

### Phase 6: one rule

**A migration must work with the build before it.** The old code keeps serving for a short time
after migrations run, today for seconds and after Phase 2 for up to 10 minutes. So a column or
table is removed in the deploy after the code stopped using it, never in the same one. This goes
into `docs-site/develop/contributing.md` and the `casama-contribute` skill.

## Not chosen

- **Deploying only at night or in batches.** It hides the problem instead of removing it, and after
  Phases 1 to 3 the number of deploys stops mattering.
- **A second server or Kubernetes for production.** Everything above works on the one VPS. It has
  12 GB with 8 GB free, enough for a second API for a few minutes.
- **A separate, rarely deployed service for calls.** Phase 2's "calls finish on the old API" gets
  the same result without a new service to run.

## To check before relying on it

All on the local stack unless noted.

- Caddy keeps retrying while the `api` container doesn't exist (the name stops resolving), not only
  while it refuses connections.
- With two API containers behind the name `api`, Caddy skips the one that isn't listening. If not,
  switch to Caddy's dynamic upstreams with health checks.
- A credit call resumes through the relay on a new API process: the relay row and the stored
  provider token are accepted a second time and Gemini honours the resume handle. Needs a real call.
- What the chat shows today when a model step is cut and runs again (the leftover draft).
- The API gap measured end to end during a real deploy, before and after each phase: a loop on
  `/healthz` once a second.
- Tests: a worker stop test (steps in flight finish, no new step starts, the run continues on a new
  worker), the 1012 cases for relay and terminal, and the auto-continue run.

## Questions for Oliver

1. Go ahead with Phases 1 to 3?
2. Phase 4: is A (continue automatically, approvals asked again) fine for now?
3. Calls: is 10 minutes the right time for an old API to keep carrying calls?
4. Phase 1 needs one Caddy restart on production (a 1 to 2 s blip). OK to do it with the first
   deploy of this work?
