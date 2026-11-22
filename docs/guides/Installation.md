# Install, build, and verify the software

## Daily use on Perlmutter

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
export TREE="$BASE/mtas-simulation-v1.2.2"
export PY="$BASE/root-env/bin/python3"
export SCR=/pscratch/sd/m/michals/MTAS
export CFS=/global/cfs/cdirs/gen0018/MTAS
which root
root-config --version
which python3
"$PY" "$TREE/scripts/verify_maintenance_release.py" --tree "$TREE" --require-built
```

The paths are the actual project layout, not portable defaults for other accounts. The historical 100k campaign uses `$BASE/mtas-simulation` (v1.2.1); keep that installation and its binaries intact. Use v1.2.2 for new projects. Do not silently point an existing frozen run at another release.

## Versioned installation (maintainers)

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

Create a new four-case full campaign from the approved 92Y+92Sr INIs, with 1,000,000 events/case, a new seed, `workers=4`, `shard_size=4`, `max_active_nodes=1`. Use the [normal campaign workflow](NewCampaign.md), including real input paths, and check controller status, scheme index, physical and ML outputs. As of this review, array `61769631` is submitted but has not yet been reported passed. All 30 Python and preserved modular C++ tests have passed on Perlmutter. Do not confuse these tests with the live acceptance or a fixed-reference scientific comparison.

### Check the submitted acceptance run

```bash
TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2
RUN=/pscratch/sd/m/michals/MTAS/production/Maintenance_Acceptance_v1_2_2/runs/run_0001
sacct -X -j 61769631 --format=JobID,State,ExitCode,Elapsed
python3 "$TREE/scripts/production_project.py" status --run-dir "$RUN"
python3 "$TREE/scripts/production_scheme_index.py" --run-dir "$RUN" --verify
python3 "$TREE/scripts/campaign_metrics.py" --run-dir "$RUN" --require-complete --detailed
python3 "$TREE/scripts/production_scaling_report.py" --run-dir "$RUN" --details
```

Expect one passed response shard with four completed full cases, no failed or pending shards, a passing scheme index, and `physical.root`, `ml.root` and validation status for all four. The current production launcher allocates a full node even for four workers. Do not use the smoke-test timing as a throughput benchmark.

## Required inputs

- Active binary electron/gamma library under Scratch; the source's checked range is 10 keV–10 MeV, not the 12 MeV histogram axis.
- Valid nuclear XML, background `.mtasbkg`, central-correction ROOT, appropriate mixture INI, and any contaminant ROOT sources.
- Writable campaign directory, enough bytes and inodes, appropriate Slurm allocation.

See [library and inputs](../reference/LibraryAndInputs.md), [storage](StorageAndArchiving.md) and [recovery](Recovery.md).
