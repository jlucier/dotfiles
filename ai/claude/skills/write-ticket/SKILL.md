---
name: write-ticket
description: Write detailed Jira/ticket descriptions for engineering tasks. Use when the user wants a ticket description that gives an engineer context and pointers without fully prescribing the implementation.
---

# Write Ticket Description

Point the implementer at the right files and concepts; let them write the code.

## Process

1. **Explore.** Find the modules, the contracts they expose, and the test patterns for similar work. Trace the layering (e.g. ORM model → schema → endpoint handler, v1 and v2 if both exist → tests).
2. **Calibrate.** Prescribe contracts (what another system/UI depends on) and correctness-sensitive logic; leave decomposition, state/timer placement, and test design open. If the requester is the lead, ask which calls to make vs. leave open; collect left-open items into one **Open for discussion** section.
3. **Draft → review with the requester → create** via the Atlassian MCP (`createJiraIssue`). Set `parent` to the epic when nested; confirm project key and issue type.

## Format

```
**[Context]** — why the work is needed and the expected behavior. Specific about types, nullability, defaults, frontend implications.
**Where to look:** — file paths + class/function names, grouped by layer. Drop when the assignee knows the code; use inline file:line instead.
**Things to consider:** — validation, backwards compat, edge cases, interaction with other features.
**Open for discussion:** — decisions deliberately left to the implementer.
```

## Style

- Specific about location, vague about implementation. "See `BaseCatalogItemSchema` in `path/to/schema.py`" beats "add a `color` field."
- Cover both v1 and v2 when both exist; name the test files and point at their existing patterns.
- No exact code, no migration-generation mention (handled separately).
- Flag fields that live in more than one place (ORM model + serialization schema).
- Direct and concise; not corporate.

## Example

"Add display_name to a catalog item":

> A catalog item needs a customizable display name, separate from its internal name. Nullable string, default null; the frontend falls back to the internal name when unset.
>
> **Where to look:**
> - ORM model: `src/db/app/models/catalog/item.py` — `CatalogItem`
> - Input schemas: `projects/api/views/catalog/schema.py`
> - Serialization: `projects/api/models/schema/objects.py` — `CatalogItemSchema`
> - Endpoints: `projects/api/views/catalog/item.py` — v1 and v2 create/update
