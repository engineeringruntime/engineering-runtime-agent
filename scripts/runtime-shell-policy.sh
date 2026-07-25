#!/usr/bin/env bash
# Shared allow/deny policy for shell commands in this repo.
# Usage: runtime-shell-policy.sh "<command>"
# Exit 0 + prints "ALLOW"  → permitted
# Exit 1 + prints "DENY|<reason>" → blocked
set -euo pipefail

command=${1:-}
if [ -z "$command" ]; then
  printf 'ALLOW\n'
  exit 0
fi

deny() {
  printf 'DENY|%s\n' "$1"
  exit 1
}

stripped=$(printf '%s' "$command" | sed -E 's/^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*//')

FORBIDDEN_RE='(^|[[:space:];|&`$()])(gh|kubectl|oc|helm|terraform|opentofu|gcloud|az|aws|docker|podman|skopeo|flux|argocd|curl|wget|git|npm|pnpm|yarn|pip|python|python3|node|go|ruby|perl|ssh|scp|rsync)([[:space:];|&`$()]|$)'

if printf '%s' "$command" | grep -Eiq "$FORBIDDEN_RE"; then
  deny "Engineering work must go through runtime only. Denied: ${command}. Use \`runtime …\` or \`runtime capability execute …\`."
fi

if printf '%s' "$stripped" | grep -Eqi '^(command[[:space:]]+-v|type|which)[[:space:]]+runtime([[:space:]]|$)'; then
  printf 'ALLOW\n'
  exit 0
fi

if printf '%s' "$stripped" | grep -Eq '[;`]|\|\||&&|\$\('; then
  deny "No shell chaining/subshells. Invoke \`runtime\` directly. Denied: ${command}"
fi

if printf '%s' "$stripped" | grep -Eqi '^([./]+)?runtime([[:space:]]|$)'; then
  if printf '%s' "$stripped" | grep -Eq '[|]'; then
    rest=${stripped#*|}
    old_ifs=$IFS
    IFS='|'
    # shellcheck disable=SC2086
    set -- $rest
    IFS=$old_ifs
    for stage in "$@"; do
      stage_cmd=$(printf '%s' "$stage" | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' | awk '{print $1}')
      case "$stage_cmd" in
        jq|head|tail|grep|egrep|fgrep|wc|sort|uniq|tr|cut|sed|awk) ;;
        *)
          deny "After runtime, only jq/head/tail/grep/wc/sort/uniq filters are allowed. Denied: ${command}"
          ;;
      esac
    done
  fi
  printf 'ALLOW\n'
  exit 0
fi

deny "Shell may only invoke \`runtime\` (or which/type/command -v runtime). Denied: ${command}"
