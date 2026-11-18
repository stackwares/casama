# @casama/plugin-check

Check an [Agent Plugins 1.0](https://agent-plugins.org) package (`plugin.json`, `mcp.json`,
`skills/`) the way [Casama](https://casama.ai) checks it when someone installs it from GitHub. It
runs the same code Casama runs, plus a few tips for things that install fine but would fail on the
bot's computer.

```sh
npx @casama/plugin-check            # the current folder
npx @casama/plugin-check my-plugin --strict
npx @casama/plugin-check . --json
```

- Exits 1 when Casama would refuse the plugin.
- `--strict` also fails when Casama would skip or ignore something (a skill, a server, a field).
  Use it in CI.
- `--json` prints the result, including the servers, secrets and network hosts Casama found.
- It lists which tools have cards (`com.casama/cards/<tool>.json`); a card with an unknown component
  or a binding Casama can't fill is skipped with a warning.

In a GitHub workflow:

```yaml
- uses: stackwares/casama/.github/actions/plugin-check@main
  with:
    path: .
```

From code:

```ts
import { checkPluginFolder } from "@casama/plugin-check";

const r = checkPluginFolder("./my-plugin");
if (!r.ok) console.error(r.errors);
```

Inside a git repository it checks the files as committed, the way Casama will see them.

Writing a plugin: [docs.casama.ai/develop/plugins](https://docs.casama.ai/develop/plugins). Start one
with `casama init plugin`, or copy
[`examples/hello-plugin`](https://github.com/stackwares/casama/tree/main/examples/hello-plugin).
