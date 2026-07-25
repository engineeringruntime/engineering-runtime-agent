# Skills map — engineering-runtime-ai-agent

| File | Answers |
|---|---|
| [`RUNTIME-AGENT.md`](./RUNTIME-AGENT.md) | How to turn intent into `runtime` requests (discover → resolve → execute) |
| [`ALLOWED-SURFACE.md`](./ALLOWED-SURFACE.md) | What Bash/`runtime` surface is in-bounds vs forbidden |
| [`CAPABILITY-AUTHORING.md`](./CAPABILITY-AUTHORING.md) | How to actually author one when nothing fits — grammar, verified mechanics, policy constraints, a worked 18-step example |

Read the first two at session start, together with the root
[`CLAUDE.md`](../../CLAUDE.md). Read the third before authoring a capability —
it records what previous sessions probed, so you don't rediscover it.
Hooks in [`.claude/hooks/`](../hooks/) enforce the Bash boundary mechanically.
