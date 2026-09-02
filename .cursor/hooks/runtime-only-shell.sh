#!/usr/bin/env bash
# Cursor beforeShellExecution / preToolUse(Shell): deny non-runtime commands.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
POLICY="$ROOT/scripts/runtime-shell-policy.sh"

input=$(cat)
# Cursor shell hooks use .command; preToolUse may use .tool_input.command
command=$(printf '%s' "$input" | jq -r '.command // .tool_input.command // empty')

if [ -z "$command" ]; then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

if result=$("$POLICY" "$command"); then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

reason=${result#DENY|}
jq -n \
  --arg agent "$reason" \
  --arg user "Blocked: only \`runtime\` shell commands are allowed in engineering-runtime-agent." \
  '{permission:"deny", agent_message:$agent, user_message:$user}'
exit 0
