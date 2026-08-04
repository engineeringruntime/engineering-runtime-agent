# engineering-runtime-ai-agent

**AI ↔ Engineering Runtime interface.** This repository is the **Runtime Agent** layer: it forces Claude (or any AI coding agent) to achieve engineering tasks **only** through the `runtime` binary — Runtime Commands and Engineering Capabilities — never by calling `gh`, `kubectl`, `terraform`, cloud CLIs, raw REST, or arbitrary shell.

```
Engineer → Natural Language → Runtime Agent (this repo)
                                      ↓
                            Engineering Runtime
                 (Bootstrap → Context → Policy → Auth →
                          Execution → Audit)
                                      ↓
                            Engineering Platforms
```

This repo does **not** execute engineering work. It has no engines, no providers, no `main.go`. Execution always belongs to [`engineering-runtime`](https://github.com/kishore-gutta/engineering-runtime).

## Why this exists

[ADR-003](../engineering-runtime/docs/04-design-decisions/adr-003-ai-interface.md) requires AI to act as a Runtime Agent: understand intent, discover/resolve capabilities, build a runtime request, and hand off. Without a dedicated, enforced contract, AI sessions drift into direct tool use and bypass Bootstrap → Context → Policy → Auth → Execution → Audit.

This repo is that contract — human-readable (`CLAUDE.md`, skills) plus mechanical enforcement (Claude Code hooks that block non-`runtime` shell).

> AI reasons. Capabilities describe intent. Runtime executes. Deterministically.

## What lives here

| Path | Role |
|---|---|
| `CLAUDE.md` | Governing contract — reason only about runtime commands |
| `.claude/skills/` | How the agent discovers commands/capabilities and hands off |
| `.claude/skills/CAPABILITY-AUTHORING.md` | Authoring playbook — grammar, probed mechanics, policy constraints, worked example |
| `scripts/runtime-shell-policy.sh` | Shared allow/deny policy for shell |
| `.claude/hooks/` + `.claude/settings.json` | Claude Code: Bash must be `runtime…` |
| `.cursor/hooks.json` + `.cursor/hooks/` | Cursor: `beforeShellExecution` / Shell `preToolUse` deny non-runtime |
| `.cursor/rules/` | Always-on Cursor rule: runtime-only reasoning + shell |

## Prerequisites

1. Install the `runtime` binary from [`engineering-runtime-releases`](https://github.com/kishore-gutta/engineering-runtime-releases) (or build from `../engineering-runtime`).
2. Ensure `runtime` is on `PATH` and bootstrap has run at least once:
   ```bash
   runtime bootstrap
   runtime version
   ```
3. Open this repo in Claude Code / Cursor so `CLAUDE.md` and hooks apply.

## How an agent is supposed to work

1. **Understand intent** from the engineer (natural language).
2. **Discover** what the installed runtime can do — prefer Runtime Home contracts after bootstrap:
   - `${ENGINEERING_RUNTIME_HOME:-$HOME/.engineering-runtime}/commands/`
   - `${ENGINEERING_RUNTIME_HOME:-$HOME/.engineering-runtime}/specs/`
   - `runtime <provider> --help`
3. **Resolve** an existing capability (company store, `RUNTIME_CAPABILITIES_DIR`, or Runtime Home `capabilities/`) — or author a new Markdown capability that only uses published provider operations.
4. **Hand off** with `runtime capability validate|execute …` or a direct `runtime <provider> …` operation. Never bypass the runtime.

Reusable capabilities belong in [`engineering-runtime-capabilities`](https://github.com/kishore-gutta/engineering-runtime-capabilities). CI demos belong in [`engineering-runtime-ci`](https://github.com/kishore-gutta/engineering-runtime-ci). Architecture docs live in [`engineering-runtime/docs`](https://github.com/kishore-gutta/engineering-runtime/tree/main/docs) and the published site [`engineering-runtime-series`](https://github.com/kishore-gutta/engineering-runtime-series).

## Non-goals

- Shipping or forking the runtime binary
- Embedding platform CLIs or SDKs
- Becoming an AI-vendor-specific product (Claude is one Runtime Agent client; the contract is vendor-neutral)

## License

MIT — see [LICENSE](./LICENSE).
