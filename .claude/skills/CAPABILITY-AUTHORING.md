# Authoring a capability when nothing existing fits

`RUNTIME-AGENT.md` says *what* the loop is. This file is the *how* — the
mechanics, the constraints of a real installation, and one fully worked
multi-provider example that shipped.

Read this before authoring; it exists so the next session does not
re-derive the same facts by trial and error.

---

## 1. Resolve intent in this order — stop at the first that fits

| # | Path | Command |
|---|---|---|
| 1 | Existing capability | `runtime capability validate\|execute <name>` |
| 2 | Published provider operation | `runtime <provider> <operation> …` |
| 3 | Allowed binary, no provider covers it | `runtime command run <binary> …` |
| 4 | Author a new capability | write Markdown → `validate` → `github file put` |
| 5 | Nothing covers it | **report the gap** — never bypass |

Authoring (4) is expected, not a last resort. Bypassing `runtime` never is.

### Partial fit — you cannot compose, so record the lineage

The common case is that three existing capabilities each cover *part* of the
intent. The instinct is to have the new capability call them. **It cannot.**
Verified by probe:

```text
- capability: github/github-file-push.md
  → line 4: field capability not found in type capability.Step

- binary: runtime
  → workflow[0]: binary "runtime" is not in allowed_binaries
```

There is no `capability:` step type and no recursion back into `runtime`.
A capability composes **providers and binaries only**.

So when the fit is partial, choose deliberately:

| Situation | Do this |
|---|---|
| The overlapping part is **cleanly separable** (no data dependency mid-sequence) | Leave it to the existing capability and invoke it separately, before or after |
| The overlapping steps must **interleave** with new ones | Inline them — and cite the source capability by name in the prose |
| You inline anything | Write a **Lineage** section listing what you re-derived, so the duplication is visible when the grammar gains composition |

Inlining costs duplication; chaining costs atomicity — `execute` stops at the
first failing step **within one capability**, so a four-capability chain has
three places a failure will not stop what follows. Prefer one capability when
the steps share a working copy or must not half-apply.

The underlying gap (a `capability:` step type) is an **architectural** change:
raise it against `engineering-runtime` as an ADR — input scoping, nested
failure semantics, cycle detection, audit nesting, recursive validation — do
not improvise it in a capability file.

---

## 2. Discovery — local contracts, then help

```text
runtime version                  # what binary am I talking to
runtime capability list          # what this install can resolve
runtime <provider> --help        # the authoritative operation list
```

Read `<Runtime Home>/RUNTIME-AGENT.md` and `manifest.json` first with your
file-read tool. If they are missing, restore from this binary and stop — do
not fetch `/metadata/*`. Do not `cat`/`ls`, and do not `runtime files read`
those contracts: they are File Engine protected.

Then read:

| Path | Use |
|---|---|
| `~/.engineering-runtime/specs/capability-spec.md` | the grammar — the parser rejects any key not in it |
| `~/.engineering-runtime/specs/<provider>/` | per-provider authoring rules |
| configured capability source (`runtime capability list`) | examples; a Home `capabilities/` copy is a non-authoritative cache |

---

## 3. Grammar — the whole of it

```yaml
version: v1
inputs:
  <name>:
    description: <text>
    required: true|false
workflow:
  - provider: <registered provider>   # exactly one of provider: or binary:
    args: [<operation>, <args>…]
  - binary: <allowed binary>
    args: [<args>…]
```

Those are the **only** keys. A plausible-but-wrong one (`steps:`,
`transport:`, `command:`) is a parse error naming the line, not a silently
ignored field. There are **no conditionals, no loops, no branches** — which
is what makes capabilities deterministic, and also why they are rarely
idempotent (see §6).

`validate` proves well-formedness and that every operation resolves for this
binary. It does **not** prove source admission or permission to invoke. Push
only after it succeeds, via `runtime github file put` (UTF-8 `content=`;
never `git`/`gh`/`curl`/`github api PUT …/contents/`). Credentials, policy
and network still apply at execute time.

---

## 4. Verified mechanics (probed this session, runtime 0.4.0)

| Question | Answer | How it was established |
|---|---|---|
| Multi-line file content as an arg? | **Yes** — YAML block scalar `- \|`, indentation preserved exactly | probe capability, written then read back |
| `${input}` inside a block scalar? | **Yes**, substituted normally | same probe |
| Do Actions `${{ github.ref }}` expressions collide with substitution? | **No** — passed through byte-identical, including `${{ secrets.* }}` | dedicated probe |
| Undeclared `${foo}`? | Left **verbatim** in the output — it silently becomes literal text in your committed file | same probe |
| Does `files write` create parent directories? | **No** — `no such file or directory` | direct probe |
| Working directory for `binary:` steps? | None. The Command Engine inherits wherever `runtime` was invoked — **always pass `git -C <dir>`** | documented in `github-git-clone-commit-push.md` (cites `internal/engine/command.go`); relied on in a successful run |
| Repo for `cli`-backed `gh` operations? | Resolved from the **current** directory, i.e. usually the wrong repo — **always pass `--repo <owner>/<repo>`** | run output |
| On step failure? | Execution **stops**; prior steps stay applied | policy denial at step 11 of 20 |

**Probe before you build.** Two throwaway capabilities in the scratchpad
answered the four questions above in under a minute and prevented a
20-step capability from failing on a guess. Do this.

---

## 5. Constraints of this installation

Re-verify with `config validate` / `policy-config.yaml` — do not trust this
table blindly, but start from it.

**`files` provider — 5 operations, no `mkdir`.** `read`, `write`, `append`,
`delete`, `list`. `write` will not create parents. There is no operation
that creates a directory. The runtime is a deterministic executor, so it also has **no generic encoder**
— no templating, no string transforms. `github file put` is the exception that
proves the rule: the **provider** UTF-8/base64-encodes `content`. Do not
hand-build that encoding in a capability. Anything else needing transformation
must arrive as an input or a literal.

**Policy denials that shape design:**

| Rule | Effect |
|---|---|
| `providers.files.denied: [delete]` | the File Engine cannot remove files at all |
| `providers.github.denied: [api DELETE]` | no repo/resource deletion via the escape hatch — demo repos cannot be torn down by the runtime |
| `command_policy.rules.git.denied` | `push --force`, `push -f`, `reset --hard`, `clean -fd`, `filter-branch`, `update-ref -d` — matched anywhere in the arg run, so `git -C x push --force` is caught too |
| `command_policy.denied_binaries` | `rm`, `sudo`, `chmod`, `curl`, `wget`, `ssh` — refused even if allow-listed |

`allowed_binaries` lists 21 tools but only the **installed** ones can run;
here that is `gh` and `git`. Everything else (`kubectl`, `terraform`, `helm`,
cloud CLIs) resolves ✗ → report the gap rather than attempting it.

**When policy denies a step, adapt — do not route around the intent.** Ask
whether a *different governed operation* legitimately covers the need. Swapping
a denied `files delete` for `git rm` is fine: git removal is version-controlled
and recoverable, and the git rule enumerates irreversible operations without
including it. Disabling policy, or reaching for a shell, is not.

---

## 6. Two patterns worth reusing

**Seed-then-clone — creating nested directories without `mkdir`.**

Git stores *paths*, not directories, so the GitHub Contents API creates
`src/main/java/com/example/demo/` implicitly when it commits a file there.
So: push a tiny placeholder to each nested path → clone → the directories now
exist on disk → the File Engine writes freely into them → `git rm` the
placeholders so they never reach the final tree.

This also keeps the unavoidable base64 trivial. The Contents API demands
base64 and the runtime cannot encode, so the only literal needed is the four
bytes `seed` = `c2VlZA==`. All real content is written as **plain text** after
the clone, where no encoding is involved. Never hand-encode a large file.

**Assume non-idempotence, and say so.** With no conditionals, a create step
fails on re-run — the Contents API refuses a create for an existing path
(it wants the blob's `sha`). Document it in the capability, and design demos
around a fresh target rather than pretending re-runs are safe.

---

## 7. Worked example

[`engineering-runtime-capabilities/capabilities/github/java-service-scaffold-and-ship.md`](../../../engineering-runtime-capabilities/capabilities/github/java-service-scaffold-and-ship.md)

Intent: *"scaffold a Java service, push it, and run its pipeline."*
No existing capability covered it → authored one. 18 steps, one run, all green.

| Steps | Engine | Transport | Doing |
|---|---|---|---|
| 1–3 | github provider | `rest` | seed `.gitkeep` at three nested paths |
| 4 | Command Engine `git` | binary | clone — brings those directories onto disk |
| 5–10 | **files provider** | `file` | write pom, `App.java`, properties, `java-ci.yml`, README, `.gitignore` |
| 11 | Command Engine `git` | binary | `git rm` the seeds (`files delete` is policy-denied) |
| 12 | files provider | `file` | list the working copy — confirmation before committing |
| 13–15 | Command Engine `git` | binary | add / commit / push |
| 16–18 | github provider | `cli` | `workflow list` → `workflow run` → `run list` |

Four transports; the capability names none of them. Providers choose.

What it cost to get there: one probe for multi-line content, one for `${{ }}`,
one direct check that `files write` won't create parents, one policy denial
at step 11 that forced a redesign, and a leftover half-scaffolded repo that
policy (correctly) would not let the runtime delete.

**Where new capabilities belong:** `engineering-runtime-capabilities/capabilities/<provider>/`,
not this repo and not the runtime binary. Execute by path, or by name once
`RUNTIME_CAPABILITIES_DIR` points at that clone (unset here, so Runtime Home
`~/.engineering-runtime/capabilities` is the default resolution root).

---

## 8. Checklist before declaring a capability done

- [ ] `runtime capability validate <path>` passes
- [ ] every required input is documented, and none is a guessed placeholder
- [ ] no hardcoded org/project/namespace — Runtime Context or an input
- [ ] no hardcoded token, credential, or auth flow
- [ ] no `transport:` anywhere, and no dependence on how an op is delivered
- [ ] every `binary: git` step passes `-C <workdir>`
- [ ] every `gh`-backed step passes `--repo`
- [ ] checked against `policy-config.yaml` *before* running
- [ ] non-idempotent steps called out in the prose
- [ ] gaps found (missing operations) written down, not silently worked around

Last gap raised: **`files` needs `mkdir`** (or `write --parents`). It would cut
the worked example by five steps and remove the base64 literal entirely. Per
capability-spec rule 5, working around a missing primitive is the signal to
add the operation.
