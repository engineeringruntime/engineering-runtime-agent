# engineering-runtime-ai-agent

**The Runtime Agent contract.** It constrains an AI assistant to achieve
engineering tasks **only** through the `runtime` binary — Runtime Commands and
Engineering Capabilities — never by calling `gh`, `kubectl`, `terraform`, cloud
CLIs, raw REST, or arbitrary shell.

That constraint is the point. Everything the assistant does then passes through
Bootstrap → Context → Policy → Auth → Execution → **Audit**, so the work is
governed and traceable instead of being whatever the model decided to type.

> AI reasons. Capabilities describe intent. Runtime executes. Deterministically.

---

## Use this in your own project

**[`RUNTIME-AGENT.md`](RUNTIME-AGENT.md) is a pointer**, not a forked contract.
The canonical operational rules live in `engineering-runtime/RUNTIME-AGENT.md`
and, after `runtime bootstrap`, in `<Runtime Home>/RUNTIME-AGENT.md`. The
installed Home copy is version-exact and wins if this checkout disagrees.

| Copy into your project | What it does |
|---|---|
| **[`RUNTIME-AGENT.md`](RUNTIME-AGENT.md)** | **The contract.** Required — everything else points at it |
| `CLAUDE.md` | Entry point Claude Code looks for; points at the contract |
| `.claude/hooks/` + `.claude/settings.json` | Claude Code hooks that **block** non-`runtime` Bash |
| `.cursor/rules/` + `.cursor/hooks.json` + `.cursor/hooks/` | Cursor rule and `beforeShellExecution` denial |
| `scripts/runtime-shell-policy.sh` | The shared allow/deny logic both hook systems call |
| `.claude/skills/` | Reference for authoring capabilities |

Using an assistant with no hook system? **Paste the Runtime Home
`RUNTIME-AGENT.md` into its instructions or system prompt**, not this
repository's pointer. That is the baseline, and it describes the binary you
actually have.

### What each assistant can actually enforce

The difference is mechanical, not a matter of quality — be clear-eyed about it:

| Assistant | Setup | Enforcement |
|---|---|---|
| **Any assistant** | Paste `RUNTIME-AGENT.md` into its instructions | **None.** The contract is prose the model chooses to follow. It can be ignored, and nothing here stops it |
| Claude Code | `CLAUDE.md` + `.claude/hooks/` | **Blocks** non-`runtime` Bash before it runs |
| Cursor | `.cursor/rules/` + `.cursor/hooks.json` | **Denies** non-`runtime` shell via `beforeShellExecution` |

**Only the hook-based rows are enforcement.** Everywhere else the contract is a
strong instruction, and an assistant that ignores it will not be stopped by this
repository. Treat the prose contract as guidance and the hooks as a control.

That is a statement of fact about hook systems, not a recommendation of a
vendor. Any tool that grows a pre-execution hook can enforce the same contract.

---

## Getting the runtime itself

The contract is useless without the binary. No GitHub account or token needed:

```bash
curl -fsSL https://raw.githubusercontent.com/kishore-gutta/engineering-runtime-releases/main/install.sh | sh
runtime version
```

Then bootstrap once:

```bash
runtime bootstrap
```

See **[Start with AI](https://docs.engineeringruntime.com/get-started/start-with-ai/)**
for the prompt to paste and what to expect back.

---

## What lives here

| Path | Role |
|---|---|
| `RUNTIME-AGENT.md` | **Pointer** to the canonical contract in `engineering-runtime` / the installed Runtime Home |
| `CLAUDE.md` | Claude Code entry point → points at the contract |
| `.cursor/rules/runtime-agent.mdc` | Always-on Cursor rule → points at the contract |
| `.claude/hooks/` + `.claude/settings.json` | Claude Code: Bash must be `runtime…` |
| `.cursor/hooks.json` + `.cursor/hooks/` | Cursor: `beforeShellExecution` denies non-runtime |
| `scripts/runtime-shell-policy.sh` | Shared allow/deny policy for shell |
| `.claude/skills/` | How the agent discovers commands/capabilities and hands off |
| `.claude/skills/CAPABILITY-AUTHORING.md` | Authoring playbook — grammar, mechanics, worked example |

This repo **does not execute engineering work**. It has no engines, no
providers, no `main.go`. Execution always belongs to
[`engineering-runtime`](https://github.com/kishore-gutta/engineering-runtime).

---

## How an agent is supposed to work

1. **Discover locally** — `runtime version`; read Runtime Home
   `RUNTIME-AGENT.md`, `manifest.json`, and `specs/`; confirm with
   `runtime <provider> --help`. If those contracts are missing, restore them
   from this binary and stop. Do not fetch `/metadata/*`.
2. **Learn the shape** from the configured capability source
   (`runtime capability list`). A Home `capabilities/` copy is a
   non-authoritative cache.
3. **Author** Markdown into that source, never silently into Runtime Home.
4. **Validate** with `runtime capability validate <path>` until clean. That
   proves grammar and this binary's operations, not source admission or
   permission to run.
5. **Push** with `runtime github file put` (UTF-8 `content=`; never `git`,
   `gh`, `curl`, or `github api PUT …/contents/`).
6. **Verify** with `runtime audit tail`. Execute only when the user asked to
   run it.

Reusable capabilities belong in
[`engineering-runtime-capabilities`](https://github.com/kishore-gutta/engineering-runtime-capabilities).
CI demos belong in
[`engineering-runtime-ci`](https://github.com/kishore-gutta/engineering-runtime-ci).

---

## Why this exists (contributors)

[ADR-003](../engineering-runtime/docs/04-design-decisions/adr-003-ai-interface.md)
requires AI to act as a Runtime Agent: understand intent, discover and resolve
capabilities, build a runtime request, and hand off. Without a dedicated,
enforced contract, AI sessions drift into direct tool use and bypass
Bootstrap → Context → Policy → Auth → Execution → Audit.

```
Engineer → Natural Language → Runtime Agent (this repo)
                                      ↓
                            Engineering Runtime
                 (Bootstrap → Context → Policy → Auth →
                          Execution → Audit)
                                      ↓
                            Engineering Platforms
```

Working **on** this repo rather than consuming it? Read
[`RUNTIME-AGENT.md`](RUNTIME-AGENT.md) and `.claude/skills/`.

## Non-goals

- Shipping or forking the runtime binary
- Embedding platform CLIs or SDKs
- Becoming an AI-vendor-specific product — the contract is vendor-neutral by
  construction, and no assistant is privileged by the repository layout

## License

MIT — see [LICENSE](./LICENSE).
