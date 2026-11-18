---
title: Is OpenClaw safe and free? What to check before installing
h1: Is OpenClaw safe, and is it free?
description: OpenClaw is free and MIT-licensed. It can be run safely, but its sandbox and approvals are off by default. What that means, and how to set it up more safely.
lead: OpenClaw is free: MIT-licensed software from a nonprofit, with no paid tier. You pay only your AI model provider, or nothing with a local model. Whether it is safe depends on how you set it up. By its own docs, tools run on your machine with the sandbox and approval prompts off until you turn them on. With both on, on a spare machine, and with care over skills, it is far safer.
updated: 2026-11-18
order: 21
---

## Is OpenClaw free?

Yes, entirely. OpenClaw's site says there is no subscription or paid edition, and it is run by the
OpenClaw Foundation, a nonprofit. The code is MIT-licensed.

What can cost money:

- **The AI model.** OpenClaw takes your own API keys, a ChatGPT or Claude plan, or local models.
  With a key, you pay the provider for what you use. A local model costs nothing.
- **A machine to run it on.** There is no hosted OpenClaw. It runs on your own computer or server,
  and it only answers while that machine is on.

## Is OpenClaw safe?

OpenClaw can be set up safely, but it doesn't start that way. Four facts from its own docs and from
press:

1. **Tools run on your machine.** The sandbox is optional and off by default, so the agent can
   reach what your user account can reach.
2. **Approvals are off by default.** Command approvals exist but have to be turned on.
3. **Security advisories.** The Register reported three high-impact security advisories in three
   days in February 2026, and malicious skills on its skill registry.
4. **It isn't built to keep users apart.** Its docs say a group that trusts each other can share
   one, but it isn't designed for people who don't trust each other.

None of that makes it unusable. It means OpenClaw trusts you to choose your own safety settings.

## How to run OpenClaw more safely

- **Turn on the sandbox** so tools run apart from your own files.
- **Turn on command approvals** so risky commands wait for you.
- **Use a spare machine or a virtual machine**, not the laptop with your banking and work sign-ins.
- **Read a skill before you install it.** Skills run with the agent's permissions.
- **Connect the fewest accounts you can**, and use separate logins for the agent where possible.
- **Keep it updated.** On November 18, 2026 the latest release was v2026.11.5, published the day
  before.
- **Don't share one agent** with people you wouldn't give your computer to.

## Who OpenClaw suits

OpenClaw is a strong choice if you are comfortable with a terminal, want the most chat apps (about
29), want software with no paid tier at all, and will set up the sandbox and approvals yourself. It
has the largest community of the agents we track, with about 395,000 GitHub stars.

## If you'd rather not set it up yourself

Some agents start with these protections on. Casama gives each bot its own sandboxed Linux
computer, asks before risky steps by default, always asks before payments, and saves a checkpoint
before destructive commands. It is free to self-host and has a free hosted plan. It is also much
newer than OpenClaw, with a small community and fewer chat apps.

Compare them side by side in [Casama vs OpenClaw](/alternatives/openclaw), or see eight
[OpenClaw alternatives](/compare/openclaw-alternatives).

## Questions

### Does OpenClaw have a paid plan?

No. There is no subscription or paid edition, and no hosted version.

### Can OpenClaw access my files?

By default, tools run on your machine with the sandbox off, so it can reach what your user account
can. Turn on the sandbox to limit that.

### Does OpenClaw train on my data?

There is no OpenClaw cloud, so OpenClaw itself doesn't receive your data. Your model provider's
policy applies, unless you use a local model. See
[which AI agents don't train on your data](/learn/which-ai-agents-dont-train-on-your-data).

### Are OpenClaw skills safe?

Treat each one like software from a stranger. Malicious skills were reported on its registry in
February 2026. Read what a skill does before installing it.

## Related questions

- [Is it safe to give an AI agent access to my email and accounts?](/learn/is-it-safe-to-give-an-ai-agent-access-to-my-email)
- [Which AI agents ask before they act?](/learn/which-ai-agents-ask-before-they-act)

## Sources

{{sources: openclaw}}

{{cta}}
