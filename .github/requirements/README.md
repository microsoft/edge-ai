# `.github/requirements/`

Hashed pip lockfiles consumed by GitHub Actions workflows. Each `<name>.in` is the human-edited source; the matching `<name>.txt` is generated with `pip-compile --generate-hashes` (from [pip-tools](https://github.com/jazzband/pip-tools)) and committed alongside it. Workflows install with `pip install --require-hashes -r .github/requirements/<name>.txt` to satisfy OpenSSF Scorecard's `Pinned-Dependencies` check.

## Files

| File                       | Consumed by                                           | Notes                                                        |
|----------------------------|-------------------------------------------------------|--------------------------------------------------------------|
| `yamllint.{in,txt}`        | `.github/workflows/yaml-lint.yml`                     | Single direct dep (`yamllint`).                              |
| `checkov.{in,txt}`         | `.github/workflows/security-staleness-check.yml`      | Large transitive closure; regenerate when bumping `checkov`. |
| `terraform-tools.{in,txt}` | `.github/workflows/variable-compliance-terraform.yml` | `pyyaml` only. `jq` CLI is pre-installed on `ubuntu-latest`. |

## Regeneration

Lockfiles are compiled against Python 3.11 (the version pinned via `actions/setup-python` in the consumer workflows). Regenerate after any `*.in` edit or to refresh transitive versions:

```bash
python3.11 -m venv .venv-pip-tools
source .venv-pip-tools/bin/activate
pip install pip-tools

cd .github/requirements
pip-compile --generate-hashes --output-file=yamllint.txt yamllint.in
pip-compile --generate-hashes --output-file=checkov.txt checkov.in
pip-compile --generate-hashes --output-file=terraform-tools.txt terraform-tools.in
```

Commit both the `.in` and the regenerated `.txt` together. Workflows must continue to invoke `pip install --require-hashes -r <file>.txt` so a tampered lockfile fails the install rather than silently downgrading hash enforcement.

## Adding a new lockfile

1. Create `.github/requirements/<name>.in` with unpinned (or loosely constrained) direct dependencies.
2. Run `pip-compile --generate-hashes --output-file=<name>.txt <name>.in`.
3. Reference it from a workflow as `pip install --require-hashes -r .github/requirements/<name>.txt`.
4. Add a row to the table above.
