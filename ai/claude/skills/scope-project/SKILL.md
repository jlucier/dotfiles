---
name: scope-project
description: Collaboratively scope engineering work into a tactical project plan. Use when the user wants to "think through", "scope", "plan", or "work out the shape of" a project before implementation. Output is a markdown plan saved to disk — not code, not tickets. Often feeds into write-ticket.
---

# Scope a Project

Produce one markdown plan dense enough that downstream engineers don't make architectural calls in flight. Not code, not tickets. Be a thought partner — push back. Succinct, engineer-to-engineer, no timetables.

## Workflow

Don't collapse the phases — pause for alignment with the user between each.

1. **Intake.** Gather context — a brief at `~/notes/projects/<slug>/` (`brief.md`, `notes.md`, or any non-plan `.md`), context in the message, or request one if there's none. Report what you picked up, what's ambiguous, what smells off.
2. **Recon.** Parallel tool calls and `Agent` forks over non-overlapping scopes. Hunt the failure classes that bite: patterns the design accidentally duplicates, hidden coupling, validation/contract gaps that fail silently in prod, wrong schema-state assumptions, loose typing at JSONB boundaries. Report findings with file:line; ask the questions recon raised.
3. **Negotiate.** Surface forks one or two at a time — alternatives, trade-off, a recommendation. Iterate. Propose a multi-file split if warranted and confirm before writing.
4. **Write.** Plan(s) in the brief's directory. Format is a guide — drop sections with nothing load-bearing to say.

## Format

```markdown
# <Project name>
## Context — why this exists, what forces it, what's already settled elsewhere.
## Guiding principles — 2–4 bold-led rules for forks the plan didn't foresee.
## Core abstraction (when applicable) — contract table (member/type/purpose); **Explicitly NOT in scope**.
## Per-component sections — one per file/module: path + lines, what changes, signatures, "reuse X at file:line". Specific location, vague implementation.
## Items worth flagging — behavior flips, hidden coupling, invariants, easy-to-miss duplication. Default: "ensure a test covers this." Bold critical items.
## Implementation order — numbered steps, one-line rationale; checkpoint (not release) boundaries; call out the behavior-flip step.
## Open questions — numbered; each with the cheapest way to resolve it.
```

Multi-doc plans: number files in tackling order (`00_overview.md`, `01_<topic>.md`). Write the overview first (one-line purpose per doc, sequencing, settled cross-doc decisions); confirm the split, then write the rest.

## Principles

- file:line everywhere; quote the codebase, don't paraphrase.
- No testing section unless test strategy is itself a real decision.

## Skip when

- Already implementing — answer the question, don't re-scope.
- Small enough for write-ticket.
- "Just implement / prototype."
