---
name: code-review
description: Review a code change for bugs first, then clarity and tests, and report findings ranked by severity with file and line.
---

# Code review

1. Find out what the change is meant to do (the ticket, PR description or the person's words). Review against that.
2. Read the whole diff once. Then look for, in this order:
   - Bugs: wrong logic, unhandled errors, off-by-one, races, missing awaits, null cases.
   - Security: untrusted input reaching queries, shells or HTML; secrets in code or logs; missing permission checks.
   - Behavior changes nobody asked for.
   - Missing or weak tests for the new behavior.
   - Clarity: names, dead code, duplication.
3. Report findings most severe first, each as `path:line - what is wrong - why it matters - a suggested fix`.
4. Say plainly when you found nothing serious. Don't pad the review with style nits unless asked.

If you can run the tests on your computer, run them and include the result.
