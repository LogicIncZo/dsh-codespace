# dsh Codespace — OpenCode Zen + Z.AI

A GitHub Codespaces template that boots [dsh](https://www.npmjs.com/package/@deepseek-ai/dsh)
(DeepSeek Harness, developer preview) with two provider routes wired:

| Route | What | Key (Codespaces secret) |
|---|---|---|
| `zen` | [OpenCode Zen](https://opencode.ai/zen) gateway — `https://opencode.ai/zen/v1`, OpenAI chat-completions; model list fetched live at setup | `OPENCODE_ZEN_API_KEY` |
| `zai` | Z.AI GLM Coding Plan (dsh's built-in `zai` catalog) | `ZAI_API_KEY` |

Default model: `zai` / `glm-5.3-flash`. The Zen list is pulled from the live
`/models` endpoint during setup (baked snapshot as fallback) and refreshed by
rerunning the generator.

## Use it

1. **Use this template** → create a new repository.
2. Add two **Codespaces secrets** (user-level, so every repo from this template gets them):
   [Settings → Codespaces → Secrets](https://github.com/settings/codespaces) → `OPENCODE_ZEN_API_KEY`, `ZAI_API_KEY`.
3. Open a Codespace on your new repo. `postCreateCommand` installs dsh, generates
   `~/.dsh/cc-models.yml`, and adds two wrappers to `~/.local/bin`.

## Commands

```bash
dshcc                            # interactive TUI with both provider routes
dshrun "fix the failing tests"   # one-shot headless task (danger-full-access by default)
bash scripts/smoke.sh            # live check: one trivial task per provider
```

Plain dsh works too:

```bash
dsh tui --patch ~/.dsh/cc-models.yml
DSH_PERMISSION_MODE=danger-full-access dsh --profile headless --patch ~/.dsh/cc-models.yml "task"
```

Switch the default model/provider, then regenerate the patch:

```bash
DSH_DEFAULT_PROVIDER=zen DSH_DEFAULT_MODEL=glm-5.3-flash bash scripts/gen-models-patch.sh
```

Refresh the Zen model list (id-only entries; route-level `defaultContextWindow: 262144`
is dsh's fallback — override per-model in the generated YAML if you need exact sizes):

```bash
bash scripts/gen-models-patch.sh   # live fetch when OPENCODE_ZEN_API_KEY is set
```

## Notes

- `DSH_PERMISSION_MODE=danger-full-access` is set container-wide because headless
  dsh has no approval channel and a Codespace is disposable. Tighten it in
  `.devcontainer/devcontainer.json` if you prefer.
- dsh is in developer preview (`@deepseek-ai/dsh` on npm); setup installs the
  latest published version.
- **Zen free-tier models don't work from dsh.** `big-pickle`, `*-free` etc. return
  `403 FreeTierError: free tier can only be used from within OpenCode` — they're kept
  in the generated list (marked with a comment) for completeness, but pick paid ids
  (`glm-5.3-flash`, `deepseek-v4.1-flash`, …) for actual runs.
- **Zen is pay-per-use.** A valid key with an empty balance fails with
  `402 Insufficient account funds`; top up at opencode.ai/zen. The Z.AI route
  rides your GLM Coding Plan subscription instead.
- Keys live only in Codespaces secrets — nothing is baked into the image or repo.
- dsh ships telemetry to DeepSeek's OTLP collector by default
  (`DSH_TELEMETRY_MODE=FEEDBACK_ONLY`); set `DSH_TELEMETRY_OTLP_URL` /
  `DSH_TELEMETRY_MODE` to change it.
