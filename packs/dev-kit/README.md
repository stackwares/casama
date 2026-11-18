# Dev kit

A Casama pack: a **Reviewer** bot with a pull-request review skill and a weekday digest of open
pull requests. It adds the gallery's code review and systematic debugging skills, and asks you to
connect GitHub.

Its small tool server (`server/github.mjs`, plain Node, no key) reads public repositories'
pull requests, and `com.casama/cards/` shows one as a Details card and a list as Results
(docs.casama.ai/develop/plugins#cards-for-your-tools). GitHub allows about 60 calls an hour
without signing in; for private repositories the bot uses its GitHub connection.

Check it: `npx @casama/plugin-check packs/dev-kit --strict`
