# Runtime Agent contract — pointer

**This repository does not own the operational contract.**

The canonical source is `engineering-runtime/RUNTIME-AGENT.md`, embedded in
the `runtime` binary and written to the Runtime Home as
`<Home>/RUNTIME-AGENT.md` on install and on every version change.

For an installed binary, **the Runtime Home copy is version-exact and wins**.
An older checkout of this file, or of any adapter that points at it, must not
override it.

```bash
runtime bootstrap
# then read:
#   ${RUNTIME_HOME:-$HOME/.engineering-runtime}/RUNTIME-AGENT.md
#   ${RUNTIME_HOME:-$HOME/.engineering-runtime}/manifest.json
```

`manifest.json` is the providers list for **this** binary. It is generated from
the same registry that executes. There are two providers: `files` and
`github`. Everything else in `commands/` is a Command Engine pass-through.

Tool-specific adapters (`CLAUDE.md`, `.cursor/rules/`, `.claude/skills/`) exist
only because those tools look for particular filenames. They point here; they
must not restate or fork the operational rules. When they disagree with the
installed Home copy, the Home copy wins.

Paste the **Home** `RUNTIME-AGENT.md` into an assistant that has no hook system.
Do not paste this pointer in its place.
