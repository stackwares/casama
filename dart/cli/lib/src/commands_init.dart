import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'commands_gallery.dart' show InitFromGalleryCommand;
import 'runner.dart';

/// `casama init <kind> [directory]`: scaffolds a project for building on Casama (a plugin, a
/// skill, a bot template or a routine file), each with an AGENTS.md for the author's coding agent.
/// Works offline and needs no sign-in.
class InitCommand extends Command<int> {
  InitCommand(CliContext ctx) {
    addSubcommand(_InitPluginCommand(ctx));
    addSubcommand(_InitPackCommand(ctx));
    addSubcommand(_InitSkillCommand(ctx));
    addSubcommand(_InitBotCommand(ctx));
    addSubcommand(_InitRoutineCommand(ctx));
    addSubcommand(InitFromGalleryCommand(ctx));
  }
  @override
  String get name => 'init';
  @override
  String get description =>
      'Start a plugin, pack, skill, bot template or routine, with an AGENTS.md for your coding agent. '
      'Or start from a gallery bot or plugin: --from-gallery bot/<id> or plugin/<id>.';
  @override
  String get invocation =>
      'casama init <plugin|pack|skill|bot|routine> [directory] [--name <name>] [--force]\n'
      '       casama init --from-gallery <bot|plugin>/<id> [directory] [--force]';
}

/// Lowercase letters, digits and single dashes, up to 63 characters: valid as a plugin name, a
/// skill name and a file name.
String slugify(String s) {
  final slug = s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final cut = slug.length > 63 ? slug.substring(0, 63) : slug;
  return cut.replaceAll(RegExp(r'-+$'), '');
}

/// "weekly-chase" -> "Weekly chase".
String _titleOf(String slug) {
  final words = slug.split('-').where((w) => w.isNotEmpty).join(' ');
  return words.isEmpty ? words : words[0].toUpperCase() + words.substring(1);
}

/// Front matter value: quoted when YAML would read it differently.
String _yaml(String v) =>
    RegExp(r'''[:#\n"'{}\[\],&*!|>%@`]''').hasMatch(v) || v.trim() != v
    ? jsonEncode(v)
    : v;

final _pluginName = RegExp(
  r'^(?!.*(?:--|\.\.))[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$',
);
final _skillName = RegExp(r'^[a-z0-9][a-z0-9_-]{0,62}$');

abstract class _InitKindCommand extends KCommand {
  _InitKindCommand(super.ctx) {
    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Name (default: the folder\'s name, slugified).',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Overwrite files that already exist.',
      );
  }

  /// What `casama init <kind>` makes, for help.
  String get what;
  @override
  String get description => what;
  @override
  String get invocation =>
      'casama init $name [directory] [--name <name>] [--force]';

  /// The files to write (path relative to the folder -> content), given the folder and the name.
  Map<String, String> files(String dir, String slug, String display);

  /// What to do next, one line each.
  List<String> nextSteps(String dir, String slug);

  /// Checks a --name; returns the slug to use. Throws UsageException when it can't be used.
  String slugFromName(String given) {
    final slug = slugify(given);
    if (slug.isEmpty) {
      throw UsageException(
        '"$given" has no letters or digits to name it by.',
        usage,
      );
    }
    return slug;
  }

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length > 1) {
      throw UsageException('Only one directory, please.', usage);
    }
    final dir = p.normalize(p.absolute(rest.isEmpty ? '.' : rest.single));
    final given = argResults!['name'] as String?;
    final String slug;
    final String display;
    if (given != null && given.trim().isNotEmpty) {
      slug = slugFromName(given.trim());
      display = given.trim();
    } else {
      slug = slugify(p.basename(dir));
      if (slug.isEmpty) {
        throw UsageException(
          'Can\'t make a name from the folder "${p.basename(dir)}". Pass --name.',
          usage,
        );
      }
      display = _titleOf(slug);
    }
    final toWrite = files(dir, slug, display);
    final force = argResults!['force'] as bool;
    final existing = [
      for (final rel in toWrite.keys)
        if (FileSystemEntity.typeSync(p.join(dir, rel)) !=
            FileSystemEntityType.notFound)
          rel,
    ];
    if (existing.isNotEmpty && !force) {
      throw CliError(
        'file_exists',
        'Already there: ${existing.join(', ')}. Nothing was written. Pass --force to overwrite.',
      );
    }
    for (final MapEntry(key: rel, value: content) in toWrite.entries) {
      final f = File(p.join(dir, rel));
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(content);
    }
    // Inside the current folder, a short relative path; elsewhere, the full one.
    final shown = p.isWithin(p.current, dir) || p.equals(p.current, dir)
        ? p.relative(dir)
        : p.normalize(p.absolute(dir));
    final steps = nextSteps(shown, slug);
    final human = StringBuffer('Created $name "$slug" in $shown:\n');
    for (final rel in toWrite.keys) {
      human.writeln('  ${existing.contains(rel) ? '~' : '+'} $rel');
    }
    human
      ..writeln()
      ..writeln('Next steps:');
    for (final s in steps) {
      human.writeln('  $s');
    }
    human.write(
      '\nAGENTS.md tells your coding agent the rules. Docs: https://docs.casama.ai/llms.txt',
    );
    return ctx.emit({
      'kind': name,
      'name': slug,
      'directory': dir,
      'files': toWrite.keys.toList(),
      'overwritten': existing,
      'next_steps': steps,
    }, human.toString());
  }
}

String _fill(String template, Map<String, String> values) {
  var out = template;
  values.forEach((k, v) => out = out.replaceAll(k, v));
  return out;
}

// --- plugin -----------------------------------------------------------------------------------

class _InitPluginCommand extends _InitKindCommand {
  _InitPluginCommand(super.ctx);
  @override
  String get name => 'plugin';
  @override
  String get what =>
      'An Agent Plugins 1.0 plugin: manifest, a Node MCP server, a skill and a CI check.';

  @override
  String slugFromName(String given) {
    if (given.length > 64 || !_pluginName.hasMatch(given)) {
      throw UsageException(
        '"$given" isn\'t a valid plugin name: lowercase letters, digits, dots and dashes, '
        'up to 64, starting and ending with a letter or digit. Try "${slugify(given)}".',
        usage,
      );
    }
    return given;
  }

  @override
  Map<String, String> files(String dir, String slug, String display) {
    // A skill name allows no dots and 63 characters at most.
    var skill = slugify(slug);
    if (skill.isEmpty) skill = 'main';
    final v = {'__NAME__': slug, '__SKILL__': skill};
    return {
      'plugin.json': _fill(_pluginJson, v),
      'mcp.json': _fill(_pluginMcpJson, v),
      'server/server.mjs': _fill(_pluginServer, v),
      'skills/$skill/SKILL.md': _fill(_pluginSkill, v),
      'README.md': _fill(_pluginReadme, v),
      'AGENTS.md': _fill(_pluginAgents, v),
      '.github/workflows/plugin-check.yml': _pluginWorkflow,
    };
  }

  @override
  List<String> nextSteps(String dir, String slug) => [
    '1. Try the server: printf \'%s\\n\' \'{"jsonrpc":"2.0","id":1,"method":"tools/list"}\' | node $dir/server/server.mjs',
    '2. Check it the way Casama will:',
    '     npx @casama/plugin-check ${p.normalize(p.absolute(dir))} --strict',
    '   (the GitHub workflow in .github/workflows runs the same check on every push)',
    '3. Push it to a public GitHub repository.',
    '4. In Casama: a bot\'s settings > Plugins > Add a plugin, and paste the repository link.',
  ];
}

// --- pack -------------------------------------------------------------------------------------

/// A plugin with a com.casama/ folder: a bot that uses the plugin's skill and tools, a routine,
/// one question. Other Agent Plugins clients still read it as a plain plugin.
class _InitPackCommand extends _InitPluginCommand {
  _InitPackCommand(super.ctx);
  @override
  String get name => 'pack';
  @override
  String get what =>
      'A pack: a plugin plus a com.casama/ folder with a bot, a routine and a question.';

  @override
  Map<String, String> files(String dir, String slug, String display) {
    final base = super.files(dir, slug, display);
    var skill = slugify(slug);
    if (skill.isEmpty) skill = 'main';
    final v = {'__NAME__': slug, '__SKILL__': skill, '__TITLE__': _titleOf(slugify(slug))};
    return {
      ...base,
      'com.casama/pack.json': _fill(_packJson, v),
      'com.casama/bots/helper.json': _fill(_packBot, v),
      'com.casama/routines/weekly-check.json': _fill(_packRoutine, v),
      'AGENTS.md': '${base['AGENTS.md']}\n${_fill(_packAgents, v)}',
    };
  }

  @override
  List<String> nextSteps(String dir, String slug) => [
    '1. Check it the way Casama will (it prints what the pack installs):',
    '     npx @casama/plugin-check ${p.normalize(p.absolute(dir))} --strict',
    '2. Try it in your workspace without publishing:',
    '     casama packs preview $dir',
    '     casama packs install $dir --input team="My team"',
    '3. Push it to a public GitHub repository, then share the link or submit it to the gallery.',
  ];
}

const _packJson = r'''{
  "format": "casama.pack",
  "version": 1,
  "title": "__TITLE__",
  "icon": "package",
  "summary": "__TITLE__: a helper bot with its skill, its tools and a weekly check.",
  "inputs": [
    { "key": "team", "label": "Your team's name", "type": "text", "default": "the team" }
  ],
  "needs": { "apps": [] },
  "includes": [],
  "workspace_skills": [],
  "examples": ["What can you help me with?"]
}
''';

const _packBot = r'''{
  "name": "__TITLE__ helper",
  "description": "Helps {{team}} with __NAME__.",
  "category": "work",
  "icon": "sparkles",
  "mascot": "winky",
  "persona": "You help {{team}}. Use the __SKILL__ skill and your tools. Keep answers short.",
  "starters": ["What can you help me with?"],
  "autonomy": "ask_risky",
  "skills": ["__SKILL__"],
  "routines": ["weekly-check"],
  "tools": ["main"]
}
''';

const _packRoutine = r'''{
  "name": "Weekly check",
  "description": "Every Monday morning: what needs attention this week.",
  "category": "work",
  "icon": "calendar-check",
  "instructions_md": "Look at what {{team}} has coming up this week and write three short lines: what's due, what's stuck, and one suggestion.",
  "schedule_cron": "0 9 * * 1"
}
''';

const _packAgents = r'''## This is a Casama pack

`com.casama/` turns this plugin into a pack. Other Agent Plugins clients ignore it.

- `com.casama/pack.json`: format "casama.pack", version 1, icon, summary, inputs (questions),
  needs.apps, includes, workspace_skills, examples.
- `com.casama/bots/<id>.json`: a bot (name, persona, autonomy ask_always|ask_risky, skills by
  name, routines by file name, tools by server key). Up to 5.
- `com.casama/routines/<id>.json`: name, instructions_md, schedule_cron (5 fields).
- `com.casama/apps/<id>/app.json`, `com.casama/looks/{themes,schemes,wallpapers}/<id>.json`: the
  gallery's formats plus a `name`.
- `{{key}}` in personas, starters, instructions and schedules is filled from the answers.
- Check with `npx @casama/plugin-check . --strict`. Docs: https://docs.casama.ai/develop/packs
''';

// --- skill ------------------------------------------------------------------------------------

class _InitSkillCommand extends _InitKindCommand {
  _InitSkillCommand(super.ctx);
  @override
  String get name => 'skill';
  @override
  String get what =>
      'One Agent Skills skill: a folder with SKILL.md, named after the folder.';

  @override
  String slugFromName(String given) {
    if (!_skillName.hasMatch(given)) {
      throw UsageException(
        '"$given" isn\'t a valid skill name: lowercase letters, digits, - and _, up to 63, '
        'starting with a letter or digit. Try "${slugify(given)}".',
        usage,
      );
    }
    return given;
  }

  @override
  Map<String, String> files(String dir, String slug, String display) {
    final v = {'__NAME__': slug, '__TITLE__': _titleOf(slug)};
    return {
      'SKILL.md': _fill(_skillMd, v),
      'AGENTS.md': _fill(_skillAgents, v),
    };
  }

  @override
  List<String> nextSteps(String dir, String slug) => [
    '1. Write the instructions in $dir/SKILL.md, and a description that says when to use it.',
    if (p.basename(p.normalize(p.absolute(dir))) != slug)
      '   The folder must be named "$slug" (its name in SKILL.md) when you import it.',
    '2. Add it to a bot: put the folder at <bot>/skills/$slug/ in a `casama files export` folder,',
    '   then `casama files import <folder> --dry-run` and `casama files import <folder>`.',
    '   Or paste it in the app: Settings > Skills > New skill. Or ship it in a plugin\'s skills/.',
  ];
}

// --- bot --------------------------------------------------------------------------------------

class _InitBotCommand extends _InitKindCommand {
  _InitBotCommand(super.ctx);
  @override
  String get name => 'bot';
  @override
  String get what =>
      'A bot template (.casama-bot.json): instructions, a skill and a routine to import.';

  @override
  String slugFromName(String given) {
    if (given.length > 80) {
      throw UsageException('A bot name is up to 80 characters.', usage);
    }
    return super.slugFromName(given);
  }

  @override
  Map<String, String> files(String dir, String slug, String display) {
    final template = {
      'format': 'casama.bot',
      'version': 1,
      'name': display,
      'description':
          'One line for people browsing templates: what $display does.',
      'persona_md':
          'You are $display. Describe the job here: who you help, what you do, and how you '
          'sound.\n\n- Be brief and plain.\n- Ask before anything you can\'t undo.',
      'autonomy': 'ask_risky',
      'avatar': 'mascot:cool',
      'skills': [
        {
          'name': 'daily-summary',
          'description': 'Write a short summary of the day. Use when asked for a recap or a daily summary.',
          'body_md':
              '1. Gather what happened today.\n2. Write three short sections: Done, In progress, '
              'Next.\n3. Keep it under 150 words.',
        },
      ],
      'routines': [
        {
          'name': 'Daily summary',
          'instructions_md': 'Write the daily summary with the daily-summary skill and send it to me.',
          'schedule_cron': '0 17 * * 1-5',
        },
      ],
      'connections': <Object>[],
    };
    return {
      '$slug.casama-bot.json':
          '${const JsonEncoder.withIndent('  ').convert(template)}\n',
      'AGENTS.md': _fill(_botAgents, {'__FILE__': '$slug.casama-bot.json'}),
    };
  }

  @override
  List<String> nextSteps(String dir, String slug) => [
    '1. Edit $dir/$slug.casama-bot.json: persona_md, skills and routines.',
    '2. Import it: in the app, Bots > Import a bot, and pick the file;',
    '   or POST /v1/bots/import (https://docs.casama.ai/develop/bot-templates.md).',
  ];
}

// --- routine ----------------------------------------------------------------------------------

class _InitRoutineCommand extends _InitKindCommand {
  _InitRoutineCommand(super.ctx);
  @override
  String get name => 'routine';
  @override
  String get what =>
      'A routine file (<name>.md): a schedule and instructions, for `casama files import`.';

  @override
  String slugFromName(String given) {
    if (given.length > 120) {
      throw UsageException('A routine name is up to 120 characters.', usage);
    }
    return super.slugFromName(given);
  }

  @override
  Map<String, String> files(String dir, String slug, String display) => {
    '$slug.md': _fill(_routineMd, {'__TITLE__': _yaml(display)}),
    'AGENTS.md': _fill(_routineAgents, {'__FILE__': '$slug.md'}),
  };

  @override
  List<String> nextSteps(String dir, String slug) => [
    '1. Edit $dir/$slug.md: the schedule (cron), time zone and instructions.',
    '2. Add it to a bot: copy it to <bot>/routines/$slug.md in a `casama files export` folder,',
    '   then `casama files import <folder> --dry-run` and `casama files import <folder>`.',
  ];
}

// --- templates --------------------------------------------------------------------------------

const _docsAndTools = '''
## Docs and tools

- Every Casama doc, for agents: https://docs.casama.ai/llms.txt (each page also has a `.md`
  version, such as the one linked above).
- Casama's agent kit for Claude Code: `/plugin marketplace add stackwares/casama`, then
  `/plugin install casama-dev@casama`.
- Casama's docs as an MCP server: `https://api.casama.ai/mcp/docs`.
''';

const _pluginJson = r'''{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "__NAME__",
  "version": "0.1.0",
  "description": "Describe what __NAME__ adds to a bot, in one sentence.",
  "license": "MIT"
}
''';

const _pluginMcpJson = r'''{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json",
  "mcpServers": {
    "main": {
      "type": "stdio",
      "command": "node",
      "args": ["${PLUGIN_ROOT}/server/server.mjs"],
      "env": { "DATA_DIR": "${PLUGIN_DATA}" }
    }
  }
}
''';

const _pluginServer = r'''#!/usr/bin/env node
// __NAME__: a minimal MCP server over stdio, with no dependencies (newline-delimited JSON-RPC 2.0).
// Casama runs it on the bot's computer (Ubuntu, Node.js 24) and doesn't run npm install, so
// bundle anything you add (esbuild --bundle --platform=node). stdout is the MCP channel: log to
// stderr. Keep state in DATA_DIR (PLUGIN_DATA), which survives updates.

import { createInterface } from "node:readline";

const tools = [
  {
    name: "hello",
    description: "Say hello to someone by name.",
    inputSchema: {
      type: "object",
      properties: { name: { type: "string", description: "Who to greet" } },
      required: ["name"],
    },
    // readOnlyHint: true is low risk, so it runs without asking. destructiveHint: true is high.
    annotations: { title: "Say hello", readOnlyHint: true },
  },
];

function call(name, args) {
  if (name === "hello") return `Hello, ${args.name}! This is __NAME__.`;
  throw new Error(`Unknown tool ${name}`);
}

function handle(msg) {
  const { id, method, params } = msg;
  switch (method) {
    case "initialize":
      return {
        protocolVersion: params?.protocolVersion ?? "2025-06-18",
        capabilities: { tools: {} },
        serverInfo: { name: "__NAME__", version: "0.1.0" },
      };
    case "ping":
      return {};
    case "tools/list":
      return { tools };
    case "tools/call":
      try {
        return { content: [{ type: "text", text: call(params.name, params.arguments ?? {}) }] };
      } catch (err) {
        // Tool failures go back as a result the model can read, not as a protocol error.
        return { content: [{ type: "text", text: String(err.message ?? err) }], isError: true };
      }
    default:
      if (id === undefined) return undefined; // a notification: nothing to answer
      throw Object.assign(new Error(`Method not found: ${method}`), { code: -32601 });
  }
}

const send = (m) => process.stdout.write(`${JSON.stringify(m)}\n`);

createInterface({ input: process.stdin }).on("line", (line) => {
  if (!line.trim()) return;
  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    return send({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "Parse error" } });
  }
  try {
    const result = handle(msg);
    if (msg.id !== undefined && result !== undefined) send({ jsonrpc: "2.0", id: msg.id, result });
  } catch (err) {
    send({ jsonrpc: "2.0", id: msg.id ?? null, error: { code: err.code ?? -32603, message: err.message } });
  }
});
''';

const _pluginSkill = r'''---
name: __SKILL__
description: Greet someone with the hello tool. Use when someone asks for a greeting or wants to try the __NAME__ plugin.
---

When someone asks for a greeting:

1. Ask for their name if you don't know it.
2. Call the `hello` tool with it.
3. Reply with what the tool returned, and nothing else.
''';

const _pluginReadme = r'''# __NAME__

A plugin for [Casama](https://casama.ai) in the open [Agent Plugins 1.0](https://agent-plugins.org)
format: a skill plus a small MCP server.

| File | What it is |
| --- | --- |
| `plugin.json` | The manifest |
| `mcp.json` | The MCP server, run on the bot's computer |
| `server/server.mjs` | The server: plain Node.js, no dependencies |
| `skills/__SKILL__/SKILL.md` | A skill that uses the server's tool |
| `AGENTS.md` | Notes for coding agents working on this plugin |

## Try it

```sh
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | node server/server.mjs
```

## Check it

The workflow in `.github/workflows/plugin-check.yml` runs Casama's checker on every push. To run
it yourself (Node 20+):

```sh
npx @casama/plugin-check . --strict
```

## Install it

Push this folder to a public GitHub repository. In Casama, open a bot's settings → **Plugins** →
**Add a plugin**, and paste the repository's link.

See the [plugins guide](https://docs.casama.ai/develop/plugins) for every field and rule.
''';

const _pluginAgents =
    r'''# AGENTS.md

This is `__NAME__`, a plugin for Casama (https://casama.ai) in the open Agent Plugins 1.0 format.
People install it on a bot by pasting its public GitHub link in the bot's settings, under
**Plugins**. Full guide: https://docs.casama.ai/develop/plugins.md

## Layout

- `plugin.json`: the manifest.
- `mcp.json`: MCP servers. `stdio` servers run on the bot's sandboxed Linux computer.
- `server/server.mjs`: a dependency-free Node MCP server (newline-delimited JSON-RPC 2.0 on stdio).
- `skills/<name>/SKILL.md`: one folder per skill; the skill's other files go with it.

## Rules

- `plugin.json`: keep `$schema` at `https://agent-plugins.org/schemas/1.0.0/plugin.schema.json`.
  Allowed fields: `$schema`, `name`, `version`, `description`, `author` (`name`, `email`, `url`),
  `homepage`, `repository`, `license`, `keywords`, `extensions`. Anything else is ignored with a
  warning, which fails the strict check. Put Casama settings under `extensions["com.casama"]`.
- `name`: lowercase letters, digits, dots and dashes, up to 64, no `--` or `..`. Never change it
  after publishing: an update with a new name is refused. Bump `version` with each release.
- `mcp.json`: only `$schema` (`https://agent-plugins.org/schemas/1.0.0/mcp.schema.json`) and
  `mcpServers`. A `stdio` server has only `type`, `command`, `args`, `env`, `cwd`; `command` is
  one program (`node`, `python3`) or a `./path` inside the plugin, never a shell line.
  `${PLUGIN_ROOT}` and `${PLUGIN_DATA}` work in `args`, `env` values and `cwd` only. Remote
  servers (`streamable-http`, `sse`) have only `type`, `url` (https), `headers`.
- Secrets never go in `env` or `headers`. Declare them in `plugin.json` under
  `extensions["com.casama"].secrets` (`name` in UPPER_CASE, `description`, `server`, and `env`
  for stdio or `header` for remote servers). Casama asks for them at install.
- Skills: the folder name equals `name` in the SKILL.md front matter (lowercase letters, digits,
  `-` and `_`, up to 63). `description` is required, one line saying when to use the skill; the
  first 300 characters are kept. Up to 60 other files, 1 MB each, 5 MB in all, named with
  letters, digits, `.`, `_`, `-` and `/`.
- The bot's computer: Ubuntu 24.04, Node.js 24, Python 3, bash, git, curl, jq. Casama doesn't run
  `npm install` or `pip install`: bundle the server into one file
  (`esbuild --bundle --platform=node`) or commit what it needs. The server has 30 seconds to
  answer `initialize`. stdout is the MCP channel, so log to stderr. Keep state in `PLUGIN_DATA`.
- Annotate every tool honestly: `readOnlyHint: true` is low risk (runs without asking),
  `destructiveHint: true` is high risk, neither is medium.
- Limits: 400 files and 10 MB per plugin, no symlinks, public GitHub repositories only.

## Check

- CI: `.github/workflows/plugin-check.yml` runs `stackwares/casama/.github/actions/plugin-check@main`,
  which fails when Casama would refuse the plugin or skip anything in it.
- Locally (Node 20+): `npx @casama/plugin-check . --strict`. It must exit 0. Commit new
  files first: in a git checkout it checks what git tracks, as GitHub would serve it.
- Talk to the server by hand:
  `printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | node server/server.mjs`

''' +
    _docsAndTools;

const _pluginWorkflow = '''name: Check plugin
on: [push, pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: stackwares/casama/.github/actions/plugin-check@main
        with:
          path: . # the plugin folder
''';

const _skillMd = r'''---
name: __NAME__
description: Say what this skill does and when the bot should use it, in one line.
---

# __TITLE__

1. Write the steps the bot should follow, one per line.
2. Name any files in this folder the steps use, such as `template.md`.
3. Say what a good result looks like.
''';

const _skillAgents =
    r'''# AGENTS.md

This folder is `__NAME__`, one skill for Casama (https://casama.ai) in the open Agent Skills
format. A bot sees the skill's name and description on every run and loads the full instructions
when a task matches. Guide: https://docs.casama.ai/guide/skills.md. As a file in a workspace:
https://docs.casama.ai/develop/workspace-files.md

## Rules

- `SKILL.md` starts with front matter between `---` lines, then the instructions in Markdown
  (up to 50,000 characters).
- `name`: lowercase letters, digits, `-` and `_`, starting with a letter or digit, up to 63
  characters. It must equal the folder's name.
- `description`: required, one line. The bot reads it to choose a skill, so say when to use it.
  Only the first 300 characters are kept. Quote it if it contains `:` or `#`.
- Optional Casama fields: `enabled` (`true` or `false`) and `id` (written by export; leave it out).
- Every other file in this folder (this AGENTS.md too) goes with the skill to the bot's computer,
  at `~/skills/__NAME__/`. Up to 60 files, 1 MB each, 5 MB in all, named with letters, digits,
  `.`, `_`, `-` and `/`. Start scripts with their interpreter (`bash scripts/x.sh`,
  `python3 tool.py`): imported files aren't executable. Scripts run only on the bot's computer.

## Check

There's no separate checker for one skill. Put this folder at `<bot>/skills/__NAME__/` (or
`workspace/skills/__NAME__/` for every bot) in a folder from `casama files export`, then run
`casama files import <folder> --dry-run`: it reports any problem with the file in `errors`. The
same skill also works inside a plugin's `skills/` folder.

''' +
    _docsAndTools;

/// The AGENTS.md written next to a bot template [file] (also by `casama init --from-gallery`).
String botAgentsMd(String file) => _fill(_botAgents, {'__FILE__': file});

const _botAgents =
    r'''# AGENTS.md

`__FILE__` is a Casama (https://casama.ai) bot template: one JSON file, format `casama.bot`
version 1, that people import to get a ready bot with its instructions, skills and routines.
Format: https://docs.casama.ai/develop/bot-templates.md

## Rules

- Required: `format` (`"casama.bot"`), `version` (`1`), `name` (1 to 80 characters),
  `persona_md` (the bot's instructions, up to 20,000 characters) and `autonomy` (`ask_always`,
  `ask_risky` or `autonomous`).
- Optional: `description` (up to 300), `avatar` (`mascot:cool`, `mascot:focused`,
  `mascot:giggly`, `mascot:lovey`, `mascot:shy`, `mascot:sleepy`, `mascot:starry`,
  `mascot:thinker`, `mascot:winky`, `mascot:wow`, or `null`), `skills`, `routines`,
  `connections`, `memories`. No other fields.
- `skills` (up to 30): `name` (lowercase letters, digits, `-` and `_`, up to 63),
  `description` (1 to 300, says when to use it), `body_md` (up to 50,000), and optional `files`
  (up to 60: `path`, `content_base64`, `executable`; 1 MB each, 5 MB per skill).
- `routines` (up to 20): `name` (1 to 120), `instructions_md` (1 to 20,000) and `schedule_cron`
  (a valid 5-field cron expression). They run in the importing person's time zone.
- `connections` (up to 30): `{ "kind": "mcp" | "openapi" | "composio" | "a2a", "name": "..." }`,
  names only. `memories` (up to 200): `kind` (`fact`, `episode`, `summary`, `preference`) and
  `content` (1 to 8,000).
- Never put keys, secrets, tokens, model choices or chats in the file: it's meant to be shared.

## Check

- It must be valid JSON: `jq -e '.format == "casama.bot" and .version == 1' __FILE__`.
- Import it to test: in the app, **Bots → Import a bot** shows a preview before anything is
  created. Or `POST /v1/bots/import`, which answers `validation_failed` (or `invalid_cron`,
  `skill_too_large`, `skill_bad_path`) and creates nothing when the file is wrong.

''' +
    _docsAndTools;

const _routineMd = r'''---
name: __TITLE__
schedule: 0 9 * * 1
timezone: UTC
trigger: schedule
enabled: true
notify: true
---

Write what the bot should do each time this runs. Say what to check, what to do with it, and what
to send you when it's done.
''';

const _routineAgents =
    r'''# AGENTS.md

`__FILE__` is a Casama (https://casama.ai) routine file: front matter between `---` lines, then
the instructions the bot follows each time it runs. Format:
https://docs.casama.ai/develop/workspace-files.md. Routines: https://docs.casama.ai/guide/routines.md

## Rules

- `name` (required, up to 120 characters). Quote it if it contains `:` or `#`.
- `trigger`: `schedule` (default) or `once` in a file you write. `calendar_event`, `message` and
  `device` need their settings under a key of that name; files can't create `webhook` or
  `github` routines.
- `schedule`: a 5-field cron expression for `schedule` triggers (`0 9 * * 1` is Mondays at
  9:00); `null` for every other trigger. `once` routines take `run_at` instead
  (`2027-01-15T09:00:00.000Z`).
- `timezone`: an IANA time zone such as `America/Chicago` (default `UTC`).
- `enabled`, `notify`: `true` (default) or `false`.
- `ends_at` (a date and time) and `max_runs` (1 to 10,000) end a repeating routine; `null` or
  left out means no end. Not for `once`.
- `id`: written by export; leave it out for a new routine.
- The instructions after the front matter are required, up to 20,000 characters.

## Check

Copy the file to `<bot>/routines/__FILE__` in a folder from `casama files export`, then run
`casama files import <folder> --dry-run`. It lists problems (bad cron, unknown time zone, missing
name or instructions) in `errors` and exits 1; nothing changes on a dry run.

''' +
    _docsAndTools;
