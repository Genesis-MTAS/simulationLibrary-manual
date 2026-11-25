# NERSC working storage, quota monitoring and durable archiving

Our MTAS data layout separates **shared software**, **shared prepared inputs**, and **independent campaigns**. CFS is the chosen destination for verified historical software, production-test bundles and reports. The full 100k dataset and active library still need verified durable copies; CFS/HPSS or another approved storage endpoint can be used.

## Directory policy

```text
/global/common/software/gen0018/mtas/
  root-env/                      shared ROOT/Python environment
  mtas-simulation/               preserved historical v1.2.1
  mtas-simulation-v1.2.2/         preserved maintenance release
  mtas-simulation-v1.2.3/         patched software for new campaigns (after promotion)

/global/cfs/cdirs/gen0018/MTAS/
  inputs/                        existing persistent/master input sources
  library/binary/                existing master response-library copy
  archive/                       verified historical packages, tests and reports

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

The reported Scratch quota was 20 TiB / 10 million inodes. The completed 100k run occupied about 1.2 TiB (measured with `du -h`); earlier tests projected ~2.7 million inodes, not a final measured inode count. Check current group CFS capacity and personal Scratch quotas separately. Leave headroom for simultaneous intermediates, input data and new cases.

Check before, during and after production:

```bash
showquota
"$PY" "$TREE/scripts/production_project.py" status --run-dir "$RUN"  # use the run's original tree
# When the run is complete:
"$PY" "$TREE/scripts/campaign_metrics.py" \
  --run-dir "$RUN" --require-complete --report-dir "$RUN/reports"
```

For **small completed** runs `du -sh "$RUN"` and `find "$RUN" -xdev -type f | wc -l` can help. For 100,000 active case directories, avoid repeated unbounded filesystem traversals during heavy parallel writes; prefer existing campaign report data and periodic sampling.

## Scratch retention and library completeness

NERSC's [Scratch policy](https://docs.nersc.gov/filesystems/perlmutter-scratch/) says files not accessed for eight weeks (56 days) may be purged when the filesystem reaches its threshold. Eligibility is per file; this is not a guaranteed grace period after campaign completion. Scratch is not backed up. See [data policy](https://docs.nersc.gov/policies/data-policy/policy/) and [backups](https://docs.nersc.gov/filesystems/backups/). Do not use artificial reads or timestamp changes to evade purging. Check candidate and deletion records under `$SCRATCH/.purge/` (not exhaustive); archive important data regardless.

Preflight verifies the active library root and electron/gamma directories, not every file. Binary readers check the opened records; `GenerateResponse --validate-only` does not load the library. The 92Y run cannot prove completeness at higher energies. A quick read-only check for the documented grid (10–1000 keV in 1-keV steps, 1010–10000 keV in 10-keV steps) compares names:

```bash
python3 - <<'PY'
from pathlib import Path
root = Path('/pscratch/sd/m/michals/MTAS/library/binary')
energies = list(range(10, 1001)) + list(range(1010, 10001, 10))
for folder, particle in [('electrons', 'Electron'), ('gammas', 'Gamma')]:
    expected = {f'Pure_{particle}_{e}keV.mtasbin' for e in energies}
    actual = {p.name for p in (root/folder).glob('*.mtasbin') if p.is_file()}
    print(folder, 'expected', len(expected), 'present', len(actual))
    print('missing:', sorted(expected-actual))
    print('unexpected:', sorted(actual-expected))
PY
```

Expected 1,891 per particle (3,782 total). Filename completeness is not a checksum; keep a durable master manifest and check sizes and headers after restoration. No standalone complete library audit is implemented in v1.2.2.

## Actual archive layout

```text
/global/cfs/cdirs/gen0018/MTAS/archive/
  software-history/
    MTAS_legacy_patch_packages_Nov2026.tar.gz   # confirmed; 23 originals removed
    MTAS_preconsolidation_sources_Nov2026.tar.gz # verify if second cleanup executed
    home-packages/                              # verify if home ZIP cleanup executed
  production-tests/
    MTAS_pre100k_production_tests_Nov2026.tar.gz # confirmed 24 GiB; 7 originals removed
    MTAS_pre100k_production_tests_Nov2026.tar.gz.sha256
  production-reports/Production_100k_candidate_v1/
    metrics/metrics.json
    scaling/report.json
    scaling/array_shards.csv
    mtas_full_scaling_report.txt
```

Historical patch archive, production-test archive and reports are confirmed. The production acceptance run for v1.2.2 is stored on **Scratch**, not in this CFS archive tree. Preconsolidation and home-package cleanup instructions were supplied but no completion log was reported. Verify their presence before relying on them. Neither the full 100k run nor library was archived by these operations.

To recover an archive, verify its SHA-256 if provided, list contents with `tar -tzf`, then extract into a new writable recovery directory using `tar -xzf ARCHIVE -C DEST --no-same-owner`. Do not extract over active software or frozen runs. Stop jobs before archiving, compare original and archived content, check for additional unarchived files and live dependencies, then explicitly delete only verified originals. Archive symlinks do not include external targets: preserve the referenced master inputs. CFS is not an independent disaster backup; HPSS and/or another site should hold critical copies.

## Read-only sharing with gen0018

For the completed run, the owner configured group traversal on ancestors (group execute, no group write) and group read/traverse on the campaign tree. Setgid on new output parents gives group inheritance; v1.2.2 launchers set `umask 027`. Expected directory mode 2750, regular file mode 0640, group `gen0018`. Setgid does not change existing children. Set ownership and permissions on the intended project, run and output parents before submission; do not broaden permissions of unrelated directories. Verify with `namei -l` and `stat`, and ask a collaborator to open a representative file from their own account. Sampled production files had the correct group and read-only permissions; independent colleague confirmation was not reported. No recursive permission change is needed on the completed run. Older index verification rejected harmless ctime changes; v1.2.2 tolerates those while preserving SHA verification.

**v1.2.2 live smoke-test lesson:** the new `Maintenance_Acceptance_v1_2_2` project produced `physical.root` and `ml.root` with mode `0640`, but group `michals` rather than `gen0018`. `umask 027` worked; group inheritance was not configured on that new project's parent. A read-only file is not readable by collaborators unless its **group** is one they belong to and all ancestor directories are traversable. For a shared new project, use a group-owned setgid parent **before** `production_project.py create`; inspect the resulting group/modes on `config`, `runs`, `cases` and outputs. The controller requires that the project itself not exist at creation time. Do not use a blanket recursive permission operation on historical frozen runs; such operations can change metadata used for provenance.


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
