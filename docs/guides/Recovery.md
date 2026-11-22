# Restart incomplete campaigns safely

**Rule:** do not delete successful ROOT files or edit frozen configuration files to force a rerun. The production system verifies completed case statuses and intentionally deleted intermediates. A failed shard has a **fixed case range**; resubmitting it should not touch any other shard's outputs.

## 1. Diagnose what failed

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2  # select original release for an older run
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
export RUN=/absolute/path/to/PROJECT/runs/run_0001

squeue -u "$USER"
"$PY" "$TREE/scripts/production_project.py" status --run-dir "$RUN"
"$PY" "$TREE/scripts/campaign_driver.py" status --run-dir "$RUN"
```

Inspect the failed `RUN/jobs/shards/shard_NNNNN.json`, the Slurm `jobs/shards-%A_%a.out/.err` logs, and the failing case's `logs/`, `validation.json` and `*_status.json`. Check `showquota` for bytes/inodes. See [job status](CheckingJobs.md).

## 2. Retry a shard after its old job has stopped

**Never launch a replacement while the previous shard task is still running.** For example, to retry shard 8 after diagnosing a failed/interrupted case:

```bash
"$PY" "$TREE/scripts/production_project.py" resume \
  --run-dir "$RUN" --shards 8 --retry-failed --dry-run
```

Review the generated `sbatch` command and run without `--dry-run` only when safe:

```bash
"$PY" "$TREE/scripts/production_project.py" resume \
  --run-dir "$RUN" --shards 8 --retry-failed
```

Existing verified cases are skipped; failed stages require explicit permission to retry. A shard already verified as passed is protected against unnecessary resubmission. A scientific validation failure should be *investigated*; do not assume every failure is transient. The controller may quarantine partial outputs on explicit retry rather than silently overwriting completed results.

## 3. If a submission stopped between the two Slurm commands

A scheme-generation job may have been submitted while the dependent shard array submission failed (for instance due to controller interruption). The controller records `RUN/jobs/submission_pending.json` so **the scheme job is not submitted twice**:

```bash
"$PY" "$TREE/scripts/production_project.py" complete-submission \
  --run-dir "$RUN" --dry-run
# After verifying the existing scheme job and shown command:
"$PY" "$TREE/scripts/production_project.py" complete-submission --run-dir "$RUN"
```

Do not delete `submission_pending.json` manually. If the original scheme job failed, review the source/model and get help deciding whether a new run is required.

## 4. Passed full cases without `intermediate.root`

This is **expected**: full-scope Step 3c/production cases remove `intermediate.root` only after validation passes. Their `response_status.json` records `intermediate_disposition.state=deleted_after_validation`; a restart recognizes this and skips the expensive response stage. An absent intermediate file **is not a reason to rerun a passed case**.

Partial scopes (`response`, `physical`) retain intermediates by design. Do not apply the full-scope cleanup expectation to a partial-scope project.

## 5. If you need different physics or resource settings

The editable files are `PROJECT/config/*.ini`; the frozen `RUN/config/` contains the bytes actually simulated. **Do not edit the run in place.** Change the project's independent INIs, run `preflight`, and `freeze` a new `run_0002`. This preserves reproducibility and output integrity.

## 6. Avoid these recovery anti-patterns

- `rm -rf` on the run or case tree to make a command "work again";
- resubmitting the entire campaign when only one shard failed;
- running two jobs against one shard or case simultaneously;
- altering input XML/contaminant files without a new frozen run and fingerprints;
- treating `Slurm COMPLETED` as proof that scientific validation passed;
- treating the software's one-node `packed_campaign.py` as a multi-node sharding system.

Related: [new campaign](NewCampaign.md), [job monitoring](CheckingJobs.md), [validation](ValidationWorkflow.md), [storage and archiving](StorageAndArchiving.md).

## 7. Permission-only scheme index errors

Old v1.2.1 may report `Indexed scheme metadata changed after creation` after chmod/chgrp. Do not regenerate schemes or bypass verification. The historical repair compared both SHA-256 hashes and all identity fields, accepted only ctime differences and backed up the descriptor. v1.2.2 ignores ctime in fast identity comparison; full hashes remain enforced. If an index content hash differs, stop and investigate. Preserve original historical executable and software paths.

For any prior array, resume only after all recorded tasks are inactive and accounting confirms terminal states; an empty `squeue` is not enough. If accounting expired, investigate instead of clearing submission history.
