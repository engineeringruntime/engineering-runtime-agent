# Cursor hooks — runtime-only shell

| Event | Script | Effect |
|---|---|---|
| `beforeShellExecution` | `runtime-only-shell.sh` | `permission: deny` unless command is `runtime…` |
| `preToolUse` (matcher `Shell`) | same | Backup gate for Shell tool |

`failClosed: true` — hook failure blocks the command.

Policy lives in `../../scripts/runtime-shell-policy.sh` (shared with Claude Code).

After changing hooks, confirm they load in Cursor **Settings → Hooks**. Restart
Cursor if a new `hooks.json` does not appear.
