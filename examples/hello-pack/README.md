# hello-pack: an example pack

A pack is an [Agent Plugins 1.0](https://agent-plugins.org) plugin with a `com.casama/` folder.
Besides the plugin's skills and tool servers, it brings a bot, a routine, an app to connect, a
look and two install questions. Other apps that read Agent Plugins use its skills and server and
skip `com.casama/`. The [packs guide](../../docs-site/develop/packs.md) explains every part.

| File                                     | What it shows                                                                 |
| ---------------------------------------- | ----------------------------------------------------------------------------- |
| `plugin.json`                            | The manifest, a secret and a plain setting under Casama's extension           |
| `mcp.json`, `server/notes.mjs`           | A notes server that runs on the bot's computer (as in `hello-plugin`)         |
| `skills/team-standup/`                   | A skill the Stand-up bot gets                                                 |
| `skills/house-style/`                    | A skill for the whole workspace (`workspace_skills`)                          |
| `com.casama/pack.json`                   | Summary, icon, two questions, an app it needs and a gallery skill it includes |
| `com.casama/bots/standup.json`           | A starter bot: its skills, routine and tool server by name                    |
| `com.casama/routines/monday-recap.json`  | A routine whose time comes from a question (`{{time.hour}}`)                  |
| `com.casama/apps/deepwiki/app.json`      | An app to connect, in the gallery's app format plus a `name`                  |
| `com.casama/looks/themes/*.json`         | A theme, in the gallery's theme format plus a `name`                          |

## Try it

From the repository root:

```sh
node packages/plugin-check/src/main.ts examples/hello-pack
```

Then paste the folder's GitHub link in Casama: **Gallery → Packs → Add from a link**.
