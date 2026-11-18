---
title: What is MCP, and what is an MCP client?
h1: What is MCP, and what is an MCP client?
description: MCP (Model Context Protocol) is a standard way for AI apps to use outside tools and data. A server offers tools; a client is the AI app that uses them.
lead: MCP, the Model Context Protocol, is a standard way for an AI app to use tools and data from somewhere else. An MCP server offers the tools. An MCP client is the AI app that connects and uses them.
updated: 2026-11-18
order: 12
---

## The idea

Before MCP, every AI app needed its own connector for every service: one for the calendar, one for
the database, one for the ticket tracker, written again for each app. MCP is one plug shape. A
service publishes an MCP server once, and any AI app that speaks MCP can use it.

| Word | Meaning | Examples |
|---|---|---|
| MCP server | A program that offers tools, data or prompts | A server for GitHub, a database, your notes, a company's own system |
| MCP client | The AI app that connects to servers and lets its model use their tools | Chat apps, coding assistants, agent platforms |
| Tool | One thing a server can do | "Search issues", "run a query", "create a page" |

A server can run on your own computer or on the internet. Remote servers usually ask you to sign
in, so the AI app acts with your permissions and not more.

## What it means for AI agents

An agent is only as useful as the things it can reach. MCP widens that without waiting for the
agent's maker to build each connection:

- **More tools.** If a service has an MCP server, your agent can use it.
- **Your own tools.** A small MCP server in front of an internal system gives an agent a safe,
  narrow way in.
- **Both directions.** An agent platform can be a client (its agents use other servers) and a
  server (other AI apps hand work to its agents).

## What to check before connecting one

- **Who runs the server.** A tool is code that acts with your access. Use servers from the service
  itself or a source you trust.
- **What each tool can do.** Reading is different from deleting. Good clients let you set which
  tools need approval.
- **What the tool's output can say.** Results come from outside, so they should be treated as
  untrusted, like a web page.

## MCP in Casama

Casama works in both directions.

**As a client.** A bot can use tools from MCP servers you add, next to its built-in tools and
connected apps. Each tool gets a risk level you can change (read-only, makes changes, always
asks), so approvals apply to MCP tools the same way as to everything else.

**As a server.** Casama has its own MCP server, so AI apps such as Claude, ChatGPT or a coding
assistant can talk to your bots and hand them work. The
[MCP guide](https://docs.casama.ai/guide/mcp) shows how to connect.

**For builders.** Casama's documentation is also available over MCP with no sign-in, at
`https://api.casama.ai/mcp/docs`, so a coding agent can look up the API while it works.
`npx -y @casama/mcp` adds a gallery search.

## Questions

### Is MCP only for developers?

No. Adding a server is usually pasting an address and signing in. Building one takes code.

### Is MCP the same as an API?

An API is how programs talk to a service. MCP is a layer on top that describes tools in a way an
AI model can choose from and call.

### Do I need MCP to use an AI agent?

No. It is one way to give an agent more tools.

## Related questions

- [What is an AI agent?](/learn/what-is-an-ai-agent)
- [How do AI agents work?](/learn/how-do-ai-agents-work)

{{cta}}
