---
name: add-task
description: Add a task card to the Obsidian Trello board (~/notes/trello/tickets/).
argument-hint: "[task — note any stage/tags/metadata you want, else defaults apply]"
---

Create `~/notes/trello/tickets/<short title>.md`:

```
---
stage: "P1"
archived: false
done: false
created: <YYYY-MM-DD>
tags:
  - <Eng|Hardware|Mgmt>
---

<body>
```

Infer `tags` from context. Default `stage` to P1 unless I say otherwise (P2/P3/Meeting Follow Ups).
