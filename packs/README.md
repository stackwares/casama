# First-party packs

Packs made by Casama, published in the plugin directory (docs/PLUGINS-AND-PACKS-PLAN.md, decision
12). Each folder is an Agent Plugins plugin with a `com.casama/` folder.

- `founder-kit/`: a chief of staff bot, investor updates, a morning plan and a Friday review.
- `dev-kit/`: a pull request reviewer, debugging help and a weekday digest of open pull requests.
- `meetings-handled/`: tomorrow's meeting prep, notes with action items and follow-ups.

Check them all: `for d in packs/*/; do npx @casama/plugin-check "$d" --strict; done`

To list one in the directory, add it to `gallery/plugins.json` pinned to a pushed commit (the
gallery checker refuses a commit GitHub doesn't have).
