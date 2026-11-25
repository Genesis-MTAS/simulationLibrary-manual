# Install, build, and verify the software

## Daily use on Perlmutter (after v1.2.3 promotion)

The shared environment is ROOT 6.40.04 at `/global/common/software/gen0018/mtas/root-env`. Put the operator's tested function in `~/.bashrc` (Conda must be initialized for the shell):

```bash
# Activate the shared MTAS ROOT environment
mtas() {
    module load python || return 1
    conda activate /global/common/software/gen0018/mtas/root-env
}
```

Run `source ~/.bashrc` after editing and `mtas` at each new login. Then:

```bash
mtas
export BASE=/global/common/software/gen0018/mtas
export TREE="$BASE/mtas-simulation-v1.2.3"
export PY="$BASE/root-env/bin/python3"
export SCR=/pscratch/sd/m/michals/MTAS
export CFS=/global/cfs/cdirs/gen0018/MTAS
which root
root-config --version
which python3
# v1.2.3 is patch-based: use its own source/binary hash verification,
# not the unmodified v1.2.2 maintenance-source verifier.
(cd "$TREE/bin" && sha256sum -c ../binaries.sha256)
python3 - "$TREE" <<'PY_CHECK'
import hashlib, json, sys
from pathlib import Path
root=Path(sys.argv[1]); hashes=json.loads((root/'SB_ZERO_TRIGGER_SOURCE_HASHES.json').read_text())
for rel, rec in hashes.items():
    got=hashlib.sha256((root/rel).read_bytes()).hexdigest()
    assert got==rec['after'], (rel, got)
print('PASS: v1.2.3 source hashes')
PY_CHECK
```

The paths are the actual project layout, not portable defaults for other accounts. The historical 100k campaign uses `$BASE/mtas-simulation` (v1.2.1); keep that installation and its binaries intact. Use **v1.2.3 after deployment verification** for new projects. A completed/frozen campaign must retain its recorded software tree. This release changes S+B event sampling; it is not physics-equivalent to v1.2.1/v1.2.2 for ground-state-rich cases.

## v1.2.3 S+B patch: safe promotion from the completed Scratch test

The already completed trial build is `/pscratch/sd/m/michals/MTAS/maintenance/sbzero_trial_v1/source-build`, and the recorded regression result is in `replayed_case/comparison.txt`. The accepted patch has **two changed production C++ files** (`src/sorting/SortEngine.cpp`, `src/mixture/PileupEngine.cpp`) and rebuilt `bin/GenerateResponse` and `bin/SortResponse`. Other four production executables must match v1.2.2 byte-for-byte.

On a **login node**, transfer `tools/mtas_deploy_v1_2_3.sh` (included in this documentation package) to the NERSC home directory and run `bash ~/mtas_deploy_v1_2_3.sh`. This script checks old/new/payload SHA-256 values from the patch, the acceptance report and executable identities, creates an isolated staging directory on Global Common, sets group-readable `gen0018` permissions, saves binary hashes, and moves it into the **new** `mtas-simulation-v1.2.3` path without overwriting any existing installation. It performs no compilation, since the changed executables were already built and regression-tested on a CPU node.

After it reports `PASS`, verify installed source/binary hashes using the daily-use commands above, and then inspect a freshly created campaign's `project_run.json`/`campaign.json` and planned command paths to establish that `--tree` selected v1.2.3. Do not reuse a frozen run to force a version switch. The original `verify_maintenance_release.py` source digest was written for v1.2.2 and is **not** an appropriate unmodified v1.2.3 acceptance check. A new full-scope v1.2.3 campaign is advisable before mass production; the one-case replay verifies the intended *scientific* delta, not the complete new-tree controller integration. The new-tree campaign should be created with `production_project.py create --tree "$TREE"`, preflighted/frozen with the same explicit tree, and checked via `project_run.json`, `campaign.json`, and `production_project.py submit --dry-run` before any `sbatch`. See [New campaign](NewCampaign.md).

## Historical v1.2.2 maintenance installation (do not repeat for v1.2.3)

Transfer `MTAS_simulation_maintenance_v1_2_2.tar.gz` to the NERSC home directory via the supported DTN, then extract from a **login node** only into a nonexistent versioned directory:

```bash
(
set -euo pipefail
BASE=/global/common/software/gen0018/mtas
NEW_TREE="$BASE/mtas-simulation-v1.2.2"
test ! -e "$NEW_TREE"
umask 027
tar -xzf "$HOME/MTAS_simulation_maintenance_v1_2_2.tar.gz" -C "$BASE" --no-same-owner --no-same-permissions
python3 "$NEW_TREE/scripts/verify_maintenance_release.py" --tree "$NEW_TREE"
)
```

**Global Common is read-only on compute nodes.** Build in writable Scratch, test there, and deploy from a login node. See [NERSC Global Common](https://docs.nersc.gov/filesystems/global-common/). The release archive intentionally excludes the six prebuilt binaries. Never rebuild the old tree in place. Do not submit two build jobs using the same workspace.

```bash
export NEW_TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2
export SCR=/pscratch/sd/m/michals/MTAS
umask 027
mkdir -p "$SCR/maintenance"
export WORK=$(mktemp -d "$SCR/maintenance/v122-build-XXXXXX")
cp -a "$NEW_TREE/." "$WORK/"
printf '%s\n' "$WORK" > "$HOME/mtas-v122-build-path.txt"
python3 "$WORK/scripts/verify_maintenance_release.py" --tree "$WORK"
```

Submit from a login shell after `mtas`. Request eight logical CPUs: synthetic end-to-end tests use four workers and enforce allocation and affinity checks. Two CPUs are insufficient.

```bash
sbatch -A gen0018 -C cpu --qos=regular --time=00:45:00 \
  --nodes=1 --ntasks=1 --cpus-per-task=8 \
  --job-name=mtas-maint-122 --chdir="$HOME" \
  --output="$HOME/mtas-maint-122-%j.out" \
  --export="ALL,WORK=$WORK" <<'SBATCH'
#!/bin/bash
set -euo pipefail
umask 027
ENV=/global/common/software/gen0018/mtas/root-env
export PATH="$ENV/bin:$PATH"
export LD_LIBRARY_PATH="$ENV/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PYTHONDONTWRITEBYTECODE=1
export TMPDIR="$WORK/tmp"
mkdir -p "$TMPDIR"
rm -f "$WORK/ACCEPTANCE_PASSED"
python3 "$WORK/scripts/verify_maintenance_release.py" --tree "$WORK"
make -C "$WORK" -B -j2
python3 "$WORK/scripts/verify_maintenance_release.py" --tree "$WORK" --require-built
env -u LD_LIBRARY_PATH python3 "$WORK/scripts/verify_maintenance_release.py" --tree "$WORK" --require-built
python3 -m unittest discover -s "$WORK/tests/production" -p 'test_*.py' -v
make -C "$WORK" check
(cd "$WORK/bin"; sha256sum GenerateDecaySchemes GenerateResponse SortResponse GenerateDecaySchemeMatrix CleanPhysicalResponse PreprocessResponse) > "$WORK/binaries.sha256"
touch "$WORK/ACCEPTANCE_PASSED"
echo 'MTAS MAINTENANCE v1.2.2 ACCEPTANCE PASS'
SBATCH
```

Read the exact job log and confirm `sacct -j JOB_ID --format=JobID,State,ExitCode,Elapsed`. A failed test must be investigated; no acceptance marker is produced by this script unless every step succeeded. When all pass, deploy from the login node:

```bash
(
set -euo pipefail
NEW_TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2
WORK=$(cat "$HOME/mtas-v122-build-path.txt")
test -f "$WORK/ACCEPTANCE_PASSED"
(cd "$WORK/bin"; sha256sum -c "$WORK/binaries.sha256")
for p in GenerateDecaySchemes GenerateResponse SortResponse GenerateDecaySchemeMatrix CleanPhysicalResponse PreprocessResponse; do
    install -m 750 -g gen0018 "$WORK/bin/$p" "$NEW_TREE/bin/$p"
done
install -m 640 -g gen0018 "$WORK/binaries.sha256" "$NEW_TREE/binaries.sha256"
(cd "$NEW_TREE/bin"; sha256sum -c "$NEW_TREE/binaries.sha256")
python3 "$NEW_TREE/scripts/verify_canonical.py" --tree "$NEW_TREE" --require-built
env -u LD_LIBRARY_PATH python3 "$NEW_TREE/scripts/verify_maintenance_release.py" --tree "$NEW_TREE" --require-built
)
```

Do not rerun deployment over an active release referenced by a frozen campaign. The v1.2.2 `GenerateDecaySchemes` link rule embeds the ROOT-env library RUNPATH, including the libxml2 location. The check without `LD_LIBRARY_PATH` verifies actual linkage; avoid relying on a temporary environment workaround.

## Final live acceptance

**PASS (November 21–22, 2026):** a new full-scope four-case ⁹²Y + ⁹²Sr campaign completed on the real Scratch response library using the deployed v1.2.2 installation. Run: `/pscratch/sd/m/michals/MTAS/production/Maintenance_Acceptance_v1_2_2/runs/run_0001`, Slurm array `61769631`. The controller metrics reported **4/4 validated**, successful scheme generation (0.102 s), and all expected physical/ML outputs. All 30 Python regression tests and the preserved C++ modular tests also passed on Perlmutter. This establishes operational integration, **not** independent fixed-reference scientific correctness.

### Live acceptance results and reproducibility

```bash
TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2
RUN=/pscratch/sd/m/michals/MTAS/production/Maintenance_Acceptance_v1_2_2/runs/run_0001
sacct -X -j 61769631 --format=JobID,State,ExitCode,Elapsed
python3 "$TREE/scripts/production_project.py" status --run-dir "$RUN"
python3 "$TREE/scripts/production_scheme_index.py" --run-dir "$RUN" --verify
python3 "$TREE/scripts/campaign_metrics.py" --run-dir "$RUN" --require-complete --detailed
python3 "$TREE/scripts/production_scaling_report.py" --run-dir "$RUN" --details
```

Observed results for the four accepted cases (from `campaign_metrics.py --detailed`):

| Metric | Observed |
|---|---:|
| Validated full cases | **4/4** |
| Mean response stage | 85.79 s |
| Mean clean stage | 1.39 s |
| Mean preprocess stage | 1.12 s |
| Mean validate stage | 2.91 s |
| Mean case outer wall time (driver overhead included) | 94.73 s |
| Mean recorded peak RSS per case | 966,730 KiB |
| Slurm one-shard elapsed | 106 s |
| Slurm allocated node-hours | 0.0294 |
| Final per-case files | `physical.root` and `ml.root`, approximately 6.2–6.8 MiB and 4.8–5.2 MiB respectively |

The scaling report produced 135.8 cases/node-hour and a zero-valued aggregate CPU statistic for this **four-worker** shard; those are not comparable to fully occupied 256-worker production-node throughput. The batch launcher allocates a full node even when only four workers are requested. The campaign-metrics estimator also prints hypothetical 100k-case projections for a single-CPU-per-stage model; those are **not scheduling predictions** and must not replace the measured 100k Slurm results.

**Observed permission caveat:** the four-case acceptance outputs were `-rw-r----- michals:michals`, while the completed 100k campaign used `-rw-r----- michals:gen0018`. The `umask 027` safeguard controls mode bits, **not group ownership**. The acceptance results are valid, but these new test files are not automatically readable by `gen0018`. For *future shared projects*, configure a setgid project parent before invoking `create`, following [new campaign](NewCampaign.md) and [storage permissions](StorageAndArchiving.md). Do not recursively alter the completed 100k frozen run to solve this small smoke-test ownership issue.

The command block above can be used to repeat the controller, scheme-index, metrics, and Slurm checks. Confirm the production state separately from numerical and scientific validation.

## Required inputs

- Active binary electron/gamma library under Scratch; the source's checked range is 10 keV–10 MeV, not the 12 MeV histogram axis.
- Valid nuclear XML, background `.mtasbkg`, central-correction ROOT, appropriate mixture INI, and any contaminant ROOT sources.
- Writable campaign directory, enough bytes and inodes, appropriate Slurm allocation.

See [library and inputs](../reference/LibraryAndInputs.md), [storage](StorageAndArchiving.md) and [recovery](Recovery.md).
