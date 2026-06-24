---
name: interview-prep
description: >
  Use this skill whenever a candidate CV or resume is involved and the user wants to prepare for an interview, generate questions, or create interview notes. Triggers when: a resume/CV file (PDF or otherwise) is attached or referenced and the user mentions interviews, hiring, candidates, or roles; the user asks to "write questions from" or "prep for" an interview; the user wants to populate or create an interview notes file for a specific candidate. Also use when the user asks to review a CV against a role level or summarize a resume for hiring purposes. If a resume is attached and there's any hiring context, use this skill.
---

# Interview Prep Skill

Produce a short, practical interview prep document from a CV. The goal: give the interviewer a quick read on who this person is, pick the 2–3 areas most worth drilling into, and give them a handful of sharp opening questions per area.

## Steps

1. **Read the CV.** Focus on the most recent 3–5 years. Note career highlights — biggest projects, most relevant experience, anything unusual.

2. **Check for hiring context.** Look for an existing hiring directory with interview guides, TL question banks, or past interview notes. Use these to calibrate tone and depth.

3. **Research the employer if needed.** A quick web search on an unfamiliar company can sharpen the questions significantly.

4. **Write the doc.** Three sections:

   **Primer** — 3–5 bullets on who the person is. What's their arc? What's their strongest area? Any flags or gaps worth probing?

   **Recommended focus areas** — Pick 2–3 topics. Prioritise: most recent role, most relevant to the job they're interviewing for, or a clear career highlight. For each, one sentence on why it's worth the time.

   **Questions** — For each focus area, 3–5 opening questions. These should crack the project open so the interviewer can then drill down naturally. Anchor to specifics from the CV. Ask about decisions made, tradeoffs, and what broke — not just what they built.

5. **Write to the interview notes file.** Append to an existing file or create one at `hiring/interviews/YYYYMMDD - Name.md`.

## Output format

```
## Primer
- [bullet]
- [bullet]

## Focus Areas

### [Area 1] — [one-line rationale]
- Question
- Question
- Question

### [Area 2] — [one-line rationale]
- Question
- Question

## Notes
```

Keep it tight. The interviewer should be able to read the whole thing in 2 minutes.
