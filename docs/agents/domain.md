---
name: domain
description:
  How the engineering skills consume this repository's domain documentation.
---

# Domain docs

How the engineering skills consume this repository's domain documentation when
exploring the codebase.

## Before exploring, read these

- `CONTEXT.md` at the repository root, the glossary.
- `docs/adr/`, reading the ADRs that touch the area you are about to work in.

If either does not exist, proceed silently. Do not flag the absence or suggest
creating them upfront: `/domain-modeling`, reached through `/grill-with-docs`
and `/improve-codebase-architecture`, creates them lazily when terms or
decisions actually get resolved.

## Layout

Single-context: one glossary and one ADR directory for the whole repository.
There is no `CONTEXT-MAP.md`; a multi-context layout only makes sense for a
monorepo, which this is not.

```text
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-<slug>.md
│   └── 0002-<slug>.md
└── docs/architecture.md   ← flake layout, imported by CLAUDE.md
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal,
a hypothesis, a test name), use the term as `CONTEXT.md` defines it. Do not
drift to synonyms the glossary explicitly avoids.

If the concept you need is not in the glossary yet, that is a signal: either you
are inventing language the project does not use (reconsider), or there is a real
gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than
silently overriding it:

> _Contradicts ADR-0003 (…), but worth reopening because…_
