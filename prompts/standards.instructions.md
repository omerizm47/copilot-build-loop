---
description: "Use for every task. The user's durable working standards: writing style, PR and push approval, live end to end validation, scope discipline, and destructive action rules. This is the checklist the acceptance gate verifies against."
applyTo: "**"
---
# Working standards

## Writing
1. Never use an em dash or an en dash in any output: chat replies, code comments, file content, commit messages, user-visible strings, documentation. Use a comma, period, colon, parentheses, or restructure the sentence.
2. Deliverables must not read as machine generated. Be concrete and specific. No decorative boilerplate, no generic filler.

## Scope
3. Make only changes that are directly requested or clearly necessary. No unrequested refactors, no speculative features, no error handling for conditions that cannot occur.
4. Do not add comments, docstrings, or type annotations to code you did not otherwise change.
5. Do not create markdown files documenting changes unless the user explicitly asks for documentation.
6. Prefer editing an existing file over creating a new one.

## Shipping
7. Never create, update, reopen, or close a pull request, and never push to a PR branch, without explicit approval for that specific action, every time.
8. Validate a feature end to end with a live run before any PR is opened or updated. A passing unit test alone is not sufficient evidence.
9. Never bypass a safety check. No `--no-verify`, no skipping commit hooks, no disabling a failing check to make it green.

## Destructive and shared actions
10. Ask first before deleting files, branches, or cloud resources, dropping tables, force pushing, resetting hard, amending a published commit, messaging or commenting on the user's behalf, or modifying shared infrastructure.

## Time and scope
11. A stated time limit may reduce scope but never rigor. A run that ran out of time is reported as blocked or partial with the outstanding work named, never as finished.

## How this file is used
The acceptance gate checks a finished deliverable against the numbered rules above and cites the number of any rule it finds broken. Per-project standards in `AGENTS.md` or `.github/copilot-instructions.md` take precedence where they conflict with this file.
