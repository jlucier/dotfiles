---
name: pr-review
description: Review a PR or the local state of a repo with parallel subagents, then merge their findings into one short list. Use for any code review or PR review request. Posts to GitHub as a pending review after approval.
argument-hint: "[PR number or URL, branch, or commit range. Defaults to local changes against main]"
---

Review a change set from several perspectives with subagents, then give the user one short list of feedback worth passing to the implementer.

## 1. Run the reviewers

Use subagents in parallel per perspective. Give each instructions on the code to review (diff, PR, branch, etc.), and its own section below. Tell each to read the surrounding code as needed, cite `file:line`, and return problems only.

**Correctness.** This matters most. Trace the changed code paths and ask whether they do what was intended under all circumstances: error paths, boundary values, concurrency, partial failure, bad input. Scrutinize hardest where a bug costs the most: embedded code, security-critical API code (auth, permissions, input handling), and real-time application code.

**Simplicity.** Can anything be simplified? Is anything vestigial: dead code, unused options, leftovers from an earlier approach, abstraction with one caller? Is there a large volume of code solving an inconsequential problem? Also check modularity and whether the change follows the existing patterns in the codebase.

**Tests.** Apply the `test-review` skill (`../test-review/SKILL.md` next to this file). Include how well the tests cover the high-risk paths the change touches.

**Performance.** Run this one only when the change touches performance-critical, real-time or embedded code. Look for memory leaks and overuse, regressions against the prior implementation, work in the hot path that could move out of it, allocation or blocking calls where they do not belong.

## 2. Merge the findings

Check each finding against the code and drop the ones that do not hold up. Merge duplicates. Reevaluate the findings for their impact and cut nitpicks or inconsequential notes which would distract for more important ones. Keep the list to a manageable size this way.

## 3. Report

Write each finding so it makes sense without perfect context of the code, and is easily understood at an architectural level (e.g. The new <blank> pipeline has a potential crash when <B> occurs before <A>).

- Open with one or two sentences on what the change does
- Follow with an ordered list of findings, most important first. Each item is one to three sentences: where it is, what the problem is, and why it matters. Mark it as a bug, a risk, a simplification or style. Add `file:line` so the user can dig in.
- Say so when you are unsure a finding is real.

Expect some back and forth. Do not post anything externally.

## 4. Post to GitHub

After approval, add the agreed feedback to a pending review. Do not submit it unless the user says to.

- Put each finding that maps to a line in an inline comment.
- Put only higher-level feedback in the main review comment. Do not restate the inline comments there. Leave the body empty if there is nothing higher-level to say.
- The comments go out under the user's name. Write them in plain, direct prose addressed to the implementer.

Create the review without an `event` field, which leaves it pending:

```
gh api repos/{owner}/{repo}/pulls/<number>/reviews --input review.json
```

```json
{
  "body": "<higher-level feedback>",
  "comments": [{ "path": "src/foo.c", "line": 42, "side": "RIGHT", "body": "..." }]
}
```

If the user already has a pending review on the PR, ask before changing it.
