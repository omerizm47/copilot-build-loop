# copilot-build-loop

A five-agent plan, implement, review, accept loop for GitHub Copilot in VS Code, plus a personal standards file that every agent is held to.

You invoke one agent, `build-loop`. It surveys the request into milestones, then for each milestone it runs a planner, an implementer, and an adversarial reviewer until the reviewer passes it. When every milestone is done, a separate acceptance agent judges the delivered result against your original request and the standards file, without ever seeing the plan. It keeps a journal on disk so a run survives context loss and can be resumed.

## The agents

| File | Role | Tools |
| --- | --- | --- |
| `build-loop.agent.md` | Orchestrator. Writes no code. Runs the milestone loop, keeps the journal, enforces the cycle and re-plan budgets. | `agent`, `todo`, `read`, `search`, `edit` |
| `planner.agent.md` | Splits the goal into milestones (SURVEY mode) or plans one milestone in detail (MILESTONE mode). Read-only. | `read`, `search`, `web` |
| `implementer.agent.md` | Executes the plan or a fix list exactly. Runs fast checks. Also does checkpoint commits and file-scoped reverts. | `read`, `edit`, `search`, `execute`, `todo` |
| `reviewer.agent.md` | Adversarial critic. Runs the tests itself, checks each acceptance criterion, detects regressions. Returns PASS or CHANGES_REQUIRED with a numbered fix list. Read-only. | `read`, `search`, `execute` |
| `acceptance.agent.md` | Final intent gate. Judges the result against the original request and the standards file only. Returns ACCEPTED or REJECTED. Read-only. | `read`, `search`, `execute` |

Only `build-loop` is user-invocable. The other four are marked `user-invocable: false` and run as subagents, so they do not clutter the agent dropdown.

`standards.instructions.md` is an always-on instruction file (`applyTo: "**"`). It holds the numbered working rules: writing style, scope discipline, PR and push approval, live end to end validation, and destructive action limits. The acceptance agent checks the finished work against those numbers and cites any it finds broken.

## Requirements

VS Code 1.132.0 or later. Custom `.agent.md` agents are a recent feature and older builds ignore these files.

## Install

Copy the contents of `prompts\` into the VS Code user prompts folder:

| Platform | Path |
| --- | --- |
| Windows | `%APPDATA%\Code\User\prompts` |
| macOS | `~/Library/Application Support/Code/User/prompts` |
| Linux | `~/.config/Code/User/prompts` |

On VS Code Insiders, replace `Code` with `Code - Insiders`. If you use a custom profile, the path is `User\profiles\<profile-id>\prompts` instead of `User\prompts`.

On Windows you can run the script instead:

```powershell
.\install.ps1
```

It copies the six files, prints each one, and skips any existing file whose contents differ. Pass `-Force` to overwrite those, or `-Destination <path>` to install somewhere else (an Insiders folder, a profile folder, or a repo's `.github/agents`). It never deletes anything.

Restart VS Code or reload the window after installing so the new agents are picked up.

## Usage

1. Open the project you want to work on.
2. Open Chat and pick `build-loop` in the agent dropdown.
3. Describe the change you want, plus any constraints.

It will ask questions only when the planner genuinely cannot proceed, then run milestones until they pass review or are blocked, then run the acceptance gate.

The run journal is written to `.build-loop/journal.md` in the project you are working on. It holds the goal, milestone states, open findings, decisions, and lessons, and it is what lets a run resume after context loss. Add `.build-loop/` to that project's `.gitignore` if you do not want it committed.

## Per-repo install

Instead of (or in addition to) the user prompts folder, you can commit the agents into a repository:

```
.github/agents/build-loop.agent.md
.github/agents/planner.agent.md
.github/agents/implementer.agent.md
.github/agents/reviewer.agent.md
.github/agents/acceptance.agent.md
.github/instructions/standards.instructions.md
```

Everyone who clones the repo gets the same loop, and the GitHub Copilot coding agent picks them up too. When a repo also has `AGENTS.md` or `.github/copilot-instructions.md`, the project rules there take precedence over the personal standards file where the two conflict.
