# Allowed execution + reasoning surface

## Reasoning

Only reason about composing **runtime** commands/capabilities for the user
request. No parallel plans that use other tools.

## Shell allow-list

```text
runtime …
which runtime | type runtime | command -v runtime
runtime … | jq|head|tail|grep|wc|sort|uniq|tr|cut|sed|awk …
```

Enforced by:

- Cursor: `.cursor/hooks.json` → `beforeShellExecution` + `preToolUse(Shell)`
- Claude Code: `.claude/settings.json` → `PreToolUse` matcher `Bash`
- Shared policy: `scripts/runtime-shell-policy.sh`

## Typical runtime verbs

```text
runtime bootstrap
runtime version
runtime config validate
runtime context show|list|use|…
runtime auth login|logout|status
runtime <provider> …
runtime capability validate|execute …
runtime audit …
runtime resolve …
```

Exact operations = whatever `runtime <provider> --help` publishes for the
installed binary.

## Intent resolution

1. Existing `capabilities/*` → `runtime capability validate|execute`
2. Published `runtime <provider> …` from `commands/` / `--help`
3. Author a new capability from Runtime Home `specs/` (only published ops) →
   `runtime capability validate` → `runtime github file put` (UTF-8 `content=`;
   never `git`/`gh`/`curl`/`github api PUT …/contents/`)
4. Missing provider operation → report the gap (never bypass)

## Refuse

| User asks… | Response |
|---|---|
| "use gh / kubectl / curl" | Map to `runtime …` / capability, or report missing operation |
| "just run a quick shell check" | Only if it is a `runtime` command |
| Bypass hooks | Never |
