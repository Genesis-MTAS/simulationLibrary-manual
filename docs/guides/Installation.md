# Install, build, and verify the software

## Existing NERSC installation (known working layout)

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation
export SCR=/pscratch/sd/m/michals/MTAS
export CFS=/global/cfs/cdirs/gen0018/MTAS

# Use the Python/ROOT environment actually used by the campaign.
source /global/common/software/nersc/pe/conda/26.11.0/etc/profile.d/conda.sh  # if available
mamba activate /global/common/software/gen0018/mtas/root-env

which root
root-config --version
which python3
"$TREE/bin/GenerateResponse" 2>&1 | head -12  # deliberately prints usage
```

**Note:** an installation's conda initialization path depends on local shell modules. If `source .../conda.sh` above is not present, use your already working NERSC Python environment setup; the canonical ROOT environment path is the verified part. For status/metrics commands, a reliable explicit interpreter is `/global/common/software/gen0018/mtas/root-env/bin/python3`.

## Build from source (maintainers)

The canonical tree contains a Makefile and C++17 ROOT/libxml2 modules. This is **not** a request to rebuild the active binaries while a campaign is running.

```bash
cd "$TREE"
make -j2
make check
```

For source integrity and compiled artifacts, use the repository's existing verification tooling and check the results before submitting another campaign. Rebuilding binaries during an active campaign may violate the input/binary fingerprints expected on restart.

```bash
python3 "$TREE/scripts/verify_canonical.py" --tree "$TREE" --require-built --require-paths
```

**Production rule:** do not casually modify installed source, executables or global defaults during a live campaign. Build and test a new software revision separately, record its version, and use it for *new* campaigns. See [Architecture](../development/Architecture.md).

## What must exist

- Binary library root with `electrons/` and `gammas/` containing `.mtasbin` files. The active verified location was under `$SCR/library/binary`, not CFS.
- A valid decay manifest and all referenced parent/daughter XML files.
- For full mixture/pileup: exact 19-crystal `.mtasbkg` background, central-correction ROOT, a compatible `Mixture.ini`, and any external contaminant ROOT files.
- Writable new output directory on Scratch, sufficient bytes **and inodes**, appropriate allocation and ROOT/Python runtime.

Do not duplicate the large library per campaign. The library's currently available electron/gamma energy range ends at 10 MeV; the 12 MeV histogram axis is not evidence of 12 MeV particle-response coverage.
