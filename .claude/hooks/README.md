# Claude Code hooks — Runtime Agent enforcement

| Event | Matcher | Script |
|---|---|---|
| `PreToolUse` | `Bash` | `runtime-only-shell.sh` |

Denies any Bash that is not `runtime` (or locate-runtime / stdout filters).
Shared policy: `../../scripts/runtime-shell-policy.sh`.

Registered in [`../settings.json`](../settings.json).
