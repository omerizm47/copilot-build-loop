# copilot-build-loop

A five-agent plan, implement, review, accept loop for GitHub Copilot in VS Code, plus a personal standards file that every agent is held to.

You invoke one agent, `build-loop`. It surveys the request into milestones, then for each milestone it runs a planner, an implementer, and an adversarial reviewer until the reviewer passes it. When every milestone is done, a separate acceptance agent judges the delivered result against your original request and the standards file, without ever seeing the plan. It keeps a journal on disk so a run survives context loss and can be resumed.

## The agents

| File | Role | Tools |
| --- | --- | --- |
| `build-loop.agent.md` | Orchestrator. Writes no code. Runs the milestone loop, keeps the journal, enforces the cycle, re-plan, and split budgets. | `agent`, `todo`, `read`, `search`, `edit` |
| `planner.agent.md` | Splits the goal into milestones (SURVEY mode) or plans one milestone in detail (MILESTONE mode). Read-only. | `read`, `search`, `web` |
| `implementer.agent.md` | Executes the plan or a fix list exactly. Runs fast checks. Also does checkpoint commits, file-scoped reverts, and an approved push. | `read`, `edit`, `search`, `execute`, `todo` |
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

It copies the six files, prints each one, and skips any existing file whose contents differ. Pass `-Force` to overwrite those, or `-Destination <path>` to install into a different prompts folder (an Insiders folder or a profile folder). It never deletes anything.

The script puts all six files in one folder, so it cannot do a per-repo install, where the standards file belongs in a different folder from the five agents. Copy those by hand into the layout under Per-repo install.

Restart VS Code or reload the window after installing so the new agents are picked up.

## Usage

1. Open the project you want to work on.
2. Open Chat and pick `build-loop` in the agent dropdown.
3. Describe the change you want, plus any constraints. A time limit has to go in this first message: the loop reads the limit once, from the request that starts the run, and a limit you add later is ignored without warning. See Time budget for the phrasing that works.

It will ask questions only when the planner genuinely cannot proceed, then run milestones until they pass review or are blocked, then run the acceptance gate.

The loop commits as it goes. Every time a milestone passes review it makes a local commit on your current branch, `checkpoint: <milestone name>`, staging only the files that milestone changed. It never pushes and never opens a pull request without asking you for that specific action first. When you do approve a push it pushes that one branch and stops there: it never force pushes, and it never opens a pull request. Commit or stash anything you do not want caught up in that before you start a run.

If a run looks stuck or frozen, say so in chat: that is a signal the loop acts on, and it abandons the outstanding subagent call, splits the step, and continues.

The run journal is written to `.build-loop/journal.md` in the project you are working on. It holds the goal, milestone states, open findings, decisions, and lessons, and it is what lets a run resume after context loss. To resume, open a fresh chat on the same project, pick `build-loop` again, and send the same request: it reads the journal and picks up at the first unfinished milestone. That matters more under a budget, because a resumed run keeps the original deadline only when the journal's GOAL matches the request you send, so if you retype something different you are asked whether to resume or start fresh. Add `.build-loop/` to that project's `.gitignore` if you do not want it committed.

## Time budget

State a limit in the request that starts the run and the loop sizes the plan to fit. "You have 3 hours", "finish it in 30 minutes", and "by 6pm" all work. The planner gets one milestone per 30 minutes of the remaining time, never fewer than one and never more than its usual cap of 8, and cuts optional surface first when the goal does not fit. You get told what was cut: the cut goes into the journal's DECISIONS as it is made, and the final report names it on the OUTSTANDING line, so you can see what a shorter budget bought you without reading the plan. It keeps a reserve at the end of the budget, 10 minutes or 10 percent of the span, whichever is larger, and stops starting new work once it is inside that reserve. The reserve exists because the next call the loop would start can itself run for tens of minutes, so a gate on zero would overshoot the deadline by a whole call.

The clock is anchored once, on the run's first call, and is never re-anchored. Time lost to a session restart comes out of the budget: a resumed run works against the original deadline rather than getting the lost time back. The limit is read once too, from the request that starts the run, so a limit you add partway through is not picked up and you get no warning that it was ignored. If that first call fails to return a time, the only thing today that drops a stated limit, the run goes ahead unbounded and the final report says `budget dropped: <what you asked for> :: <what dropped it>` instead of `unbudgeted`, so a run whose limit never took effect never looks like a run you left open ended.

The phrase has to name a duration or a clock time. "Before the demo tomorrow" bounds the run but gives the loop nothing to compute a deadline from, so that phrase is discarded on its own. Each time phrase is judged separately, and the run is budgeted as long as one of them names a duration or a clock time, however many others are thrown out. The run is unbudgeted only when none of them does.

With no limit stated, no scope is cut, no cap is lowered, nothing stops the run on time, and it runs exactly as long as it would have. That is genuinely long: up to 8 milestones against a global ceiling of 40 review cycles, which can mean hours. The implementer and the reviewer still report their clock time, the planner and the acceptance agent never report one at all, and the final report still carries `TIME: unbudgeted`, but nothing in the loop acts on any of it and the journal's time fields sit unused.

A budget reduces scope, never rigor. Every milestone is still reviewed, the acceptance gate still runs, no safety check is skipped, and a CHANGES_REQUIRED verdict is never talked into a pass. A run that hits the limit with work outstanding reports as blocked and names what was left undone. It never reports as finished.

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
