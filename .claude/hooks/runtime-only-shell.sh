#!/usr/bin/env bash
# Claude Code PreToolUse (Bash): deny non-runtime commands.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY="$ROOT/scripts/runtime-shell-policy.sh"

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

if result=$("$POLICY" "$command"); then
  exit 0
fi

reason=${result#DENY|}
reason="${reason}

See CLAUDE.md — reason only about which runtime commands achieve the request."

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
