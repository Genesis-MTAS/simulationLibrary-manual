# NERSC working storage, quota monitoring and durable archiving

Our MTAS data layout separates **shared software**, **shared prepared inputs**, and **independent campaigns**. The archive destination remains **undecided**: it may be NERSC CFS or another computer. The production workflow must not depend on the archive choice.

## Directory policy

```text
/global/common/software/gen0018/mtas/
  root-env/                      shared ROOT/Python environment
  mtas-simulation/               one canonical software installation

/global/cfs/cdirs/gen0018/MTAS/
  inputs/                        existing persistent/master input sources
  library/binary/                existing master response-library copy
  # possible later archive, only after project-quota and retention review

/pscratch/sd/m/michals/MTAS/
  library/binary/{electrons,gammas}/  ACTIVE 296-GiB response library
  inputs/                        active working references/background
  contaminants/                  prepared source event/histogram ROOT files
  production/
    ProjectName/
      config/                    editable independent six INIs
      runs/run_0001/
        config/                  immutable run snapshot
        inputs/ schemes/ cases/ jobs/ reports/
```

**No campaign copies the entire response library.** The active library is on **Scratch**, not CFS. The production controller checks the runtime library path and uses the same files in all shards. A named contaminant file may be on Scratch, but it is hashed and referenced as frozen input; keep its upstream/master source separately.

## Space and inode limits

The operator's latest quota output was **20.00 TiB Scratch / 10 million inodes** and ~320.83 GiB used / 78.38K inodes used after the 512-case run. The budget is ample for the **observed** full 92Y+92Sr output shapes, but **not guaranteed** for any target or time range.

Measurements from the successful 1024/512 full tests project roughly **1.1 TiB final plus metadata** and **~2.7 million inodes** for 100,000 similar cases. These are much better than extrapolating a single pilot's 54 objects/case. Filesystem objects include directories, not just ROOT files. This would use a significant fraction of the 10M quota; leave headroom for other work, background inputs, scripts, failed-case diagnostics and temporary operations.

Check before, during and after production:

```bash
showquota
"$PY" "$TREE/scripts/production_project.py" status --run-dir "$RUN"
# When the run is complete:
"$PY" "$TREE/scripts/campaign_metrics.py" \
  --run-dir "$RUN" --require-complete --report-dir "$RUN/reports"
```

For **small completed** runs `du -sh "$RUN"` and `find "$RUN" -xdev -type f | wc -l` can help. For 100,000 active case directories, avoid repeated unbounded filesystem traversals during heavy parallel writes; prefer existing campaign report data and periodic sampling.

## Temporary outputs and peak storage

Keep `physical.root` and `ml.root` for full-scope ML data. `intermediate.root` can be ~13 MiB per case (example), and is removed only **after** full validation. At 256 active processes/node and several active nodes, many intermediate files may exist simultaneously. The peak working-set space is larger than the final ROOT estimate; memory pressure and Scratch metadata load may also increase with many simultaneous jobs.

If validation fails, preserve the intermediate for diagnosis; do not run cleanup logic that deletes evidence. Scope `response`/`physical` intentionally retains the intermediate. Record the scope and expected products rather than treating these as errors.

## What to retain for scientific reproducibility

| Content | Retain? | Reason |
|---|---|---|
| `physical.root` | Yes for physical spectrum analysis | Final and elementary additive weighted counts |
| `ml.root` | Yes when used for training | Shared-log data and matrix; inverse metadata |
| Frozen six INIs and run manifests | Yes | Precise scientific, seed and executable provenance |
| Scheme XML for every case | Yes or verified reproducible archive | β/γ nuclear model labels, target reconstruction |
| `validation.json` and stage statuses | Yes / validated aggregate with per-case traceability | Identifies what actually passed and failed |
| Slurm job IDs, logs and cost reports | Yes / summarized with access to failures | Reproducible resource and debugging history |
| Raw `intermediate.root` | No **after passing full validation** | Large temporary, no longer needed for standard final products |
| `EventInfo` raw trees | Only if explicitly required | Huge; not part of direct-sort full default |
| Input electron/gamma response library | One shared, versioned master + manifest | Avoid N × 296-GiB duplication |
| Background/correction/contaminant inputs | Preserve or reference their verified masters | Reproducing the actual simulation conditions |

## Destination-neutral archive workflow

1. **Choose** CFS **or another machine**; verify free capacity, inode or file-count limit, retention/purge policy, permissions, availability and transfer method. The decision must occur before Scratch could become the sole fragile copy of valuable output.
2. Generate a verified inventory: run IDs, case count, file paths/bytes/hashes, final ROOT outputs, XML, frozen configs, reports, validation and input/software provenance. Preserve each case's traceability.
3. Transfer in monitored batches using a method supported by the chosen endpoints. Do not assume NERSC login/compute nodes are appropriate for large transfers; use the site-approved transfer path.
4. Verify destination file count, bytes and **SHA-256** versus source manifests. A successful copy command alone is not proof that the scientific dataset is complete.
5. Record destination path/URI, date, operator and check results. Ensure authorized collaborators can actually read the archive.
6. Only then consider removing Scratch copies, after an explicit retention review; do not automatically delete successful results merely because an archive job started.

For public GitHub, publish **code, documentation, test fixtures and small examples**, not the multi-terabyte simulation dataset.

Related [performance](PerformanceAndStorage.md), [output guide](InspectOutputs.md), [production 100k walkthrough](Production100k.md), [job status](CheckingJobs.md).
