**Production-controller update (November 2026):** New projects should use the integrated `scripts/production_project.py` controller (`create → preflight → freeze → submit → status → resume`) and `scripts/production_shard.py`. It provides independent per-project INIs and bounded, nonoverlapping multi-node sharding; the 512-case two-node acceptance and then the 100k v1.2.1 full campaign passed. The underlying `campaign_driver.py` remains the per-case stage engine and supports legacy schema-2 campaigns. See [the production project program reference](ProductionProject.md) and [new campaign guide](../guides/NewCampaign.md).

# Campaign driver (`campaign_driver.py`)

**Source:** `scripts/campaign_driver.py` as supplied in the November 18 Step 3c tarball; Python 3. Handles orchestration, provenance and restart, not nuclear physics itself.

## Commands

```bash
python3 scripts/campaign_driver.py init --tree TREE --run-dir RUN   --decay-xml Decay.xml --background-file background.mtasbkg   --central-file correction.root --commands campaign_commands.json   --mixture-file Mixture.ini --cases 16 --events 1000000   --batch 100000 --master-seed 20261118
python3 scripts/campaign_driver.py plan --run-dir RUN --case-id 0 --audit
python3 scripts/campaign_driver.py run --run-dir RUN --until schemes
python3 scripts/campaign_driver.py run --run-dir RUN --case-id 0
python3 scripts/campaign_driver.py status --run-dir RUN
```

`init` requires `--tree`, `--run-dir`, `--decay-xml`, `--background-file`, `--central-file` and `--commands`. Optional: `--mixture-file`, `--cases` (default 1), `--events` (1e6), `--batch` (1e5), `--master-seed` (20261117), `--stage-mode link|copy` (`link`), `--dry-run`, and `--keep-intermediate`. The default campaign adapter currently **expects** a `Mixture.ini` to generate final composition; for no contaminants, use a mixture with no `[contaminant:...]` sections.

`plan` has optional `--case-id` (default 0) and `--audit`. `run` can operate on one case or all cases, with `--until schemes|response|clean|preprocess|validate` and explicit `--retry-failed`. `status` summarizes passed/failed/running/pending counts.

## Five stages

1. **schemes:** once per campaign, execute `GenerateDecaySchemes` and write scheme XMLs + metadata.
2. **response:** each case runs `GenerateResponse --direct-sort`, writing `intermediate.root`.
3. **clean:** `CleanPhysicalResponse` writes `physical.root`.
4. **preprocess:** `PreprocessResponse --decay-xml` writes `ml.root` and matrix.
5. **validate:** PyROOT consistency checks write `validation.json`.

All stages run as argv arrays (not through a shell) from `config/defaults/campaign_commands.json`, expanded against a strictly defined placeholder map. Stage logs and JSON statuses record argv, elapsed seconds, fingerprints, expected-output paths, sizes and SHA-256.

## Immutability and arbitrary contaminants

- `init` creates a **new** run directory and copies INIs, stages/symlinks the manifest and sibling XML, background and central ROOT, and snapshots runtime configuration.
- For schema-2 campaigns, every `[contaminant:<name>]` with `file = ...` is discovered generically; external ROOT files are checked and fingerprinted. This supports zero, one or many contaminants without isotope-specific names. The driver does not generate contaminant event files; supply compatible upstream data.
- Seeds for response, conditions, smearing, mixture and pileup are derived per case from master seed, case index and stream name.
- Per-case configuration and generated scheme XML hashes are checked on rerun. Changed external inputs or executables are rejected, not silently accepted.

## Intermediate cleanup and restart

**Schema-2 default:** `intermediate.root` is removed only after `validate` passes. `response_status.json` records its intentional deletion; subsequent `run` verifies downstream output integrity and skips completed response rather than rerunning a million events. `--keep-intermediate` opts out at initialization. Failed/partially validated cases retain intermediates for debugging. Schema-1 historical campaigns keep their old behavior. A restart with tampered or missing final output is rejected unless explicit recovery is appropriate; do not use `--retry-failed` to mask unexplained validation failures.

## Slurm execution

`jobs/campaign_pilot_1case.slurm` is the validated integration pattern. `jobs/campaign_case_array.slurm` supplies a per-case array entry point, but **scheme generation must finish successfully before starting case jobs**. For new large-scale production use the project controller; see the completed 100k scaling measurements. See [operations](../guides/NERSCAndScaling.md).

## Status and tests

- Real schema-1 pilot: passed generator, response, cleaner, shared-log/matrix, validation; restart skipped all stages.
- Step 3c: 14 local Python tests and a Perlmutter installation/restart check passed. Perlmutter schema-2 cleanup pilot subsequently completed: physical.root and ml.root retained, intermediate.root deleted after validation, and restart skipped all stages (operator logs).
- Current driver is intentionally a practical orchestration layer, not a universal workflow service: absolute run paths are fixed, shared response library content is not exhaustively rehashed per case, and filesystem/scheduler scaling has been measured for the 92Y+92Sr workload; retest new workloads.

## Campaign storage, fingerprints and safe replay

A new campaign creates `campaign.json`, `inputs_manifest.json`, staged inputs, `config/`, `schemes/` after scheme generation, and `cases/case_NNNNNN/` when each case starts. The schema-2 driver captures the effective runtime configuration at initialization and checks it against its stored fingerprint on subsequent execution. It does **not** silently follow edits to global deployment settings.

Each case has four main stage statuses (`response`, `clean`, `preprocess`, `validate`) in JSON, plus per-stage logs, per-case INIs and the scheme XML. The response stage produces an intermediate ROOT file; cleanup/preprocessing/validation follow. If every final check passes, schema 2 deletes the intermediate and records that deletion. A restart checks the recorded disposition and final-output hashes, so intentional cleanup does not force re-generation. Failed validation preserves the intermediate for investigation.

The driver hashes external contaminant ROOT files named in all `[contaminant:...]` sections. Contaminant names are generic, but relative and ambiguous file paths may be rejected; use absolute paths for reproducible runs. This mechanism is distinct from hashing the entire 296-GB shared particle-response library on each stage. Separate library inventory/version management is recommended for a published production dataset.

### Example status and recovery workflow

```bash
python3 scripts/campaign_driver.py status --run-dir "$RUN"
python3 scripts/campaign_driver.py plan --run-dir "$RUN" --audit
python3 scripts/campaign_driver.py run --run-dir "$RUN"
```

A completed case should produce `SKIP` messages on the last command. Do not set `--retry-failed` indiscriminately; preserve logs and identify the failure before rerunning an interrupted or failed stage.

### Large campaigns

The driver is a **case orchestrator**, not a cluster scheduler. For parallel execution, generate schemes **once**, then submit a Slurm array with one independent case per task and a configurable concurrency cap. Do not launch all array elements before the schemes job finishes. Use stage statuses to collect actual timing; compare per-case elapsed time with Slurm queue waiting and execution statistics. See [validation and scaling](../development/ValidationAndDocumentationStatus.md).


> **Updated production planning:** [Full configuration reference](../reference/Configurations.md) · [Configuration worksheet](../reference/ProductionConfigurationReview.md) · [100,000-case operations](../guides/Production100k.md) · [Readiness gaps](../development/ProductionReadiness.md).
