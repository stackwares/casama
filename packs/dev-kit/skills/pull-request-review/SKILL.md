---
name: pull-request-review
description: Review a GitHub pull request for bugs, risks and missing tests, and draft review comments.
---

When asked to review a pull request:

1. Read the pull request's description, the changed files and the checks with the GitHub tools.
   If you can't reach it, ask for the link or the diff.
2. Look for, in this order: bugs and wrong behaviour, security problems (secrets, injection,
   missing permission checks), data loss, missing or weak tests, then readability.
3. Write the review as: a one-line verdict (ready, small changes, needs work), then numbered
   findings with the file and line, why it matters and a suggested fix. Skip style nits unless
   asked.
4. Draft comments, but post them on GitHub only after the person says so.
