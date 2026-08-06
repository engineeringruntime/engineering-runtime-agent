# CLAUDE.md — entry point

**The contract is [`RUNTIME-AGENT.md`](RUNTIME-AGENT.md). Read it now — it
governs this session.**

This file exists because Claude Code looks for this filename. It is a pointer,
not a second copy: the governing text is deliberately kept in a **vendor-neutral**
file so one contract serves every assistant, and no vendor is privileged by the
repository layout.

| You are using | Read | Mechanical enforcement |
|---|---|---|
| **Any assistant** | [`RUNTIME-AGENT.md`](RUNTIME-AGENT.md) — paste into its instructions | **None** — prose contract only |
| Claude Code | This file → `RUNTIME-AGENT.md`, plus `.claude/hooks/` | Hooks **block** non-`runtime` Bash |
| Cursor | `.cursor/rules/runtime-agent.mdc` → `RUNTIME-AGENT.md`, plus `.cursor/hooks.json` | `beforeShellExecution` **denies** non-`runtime` shell |

Also read `.claude/skills/` before authoring a capability.

Customers consuming this repo as a product: start at
[`README.md`](README.md), not here.
