#!/usr/bin/env bash
# Promote the already tested MTAS S+B zero-trigger Scratch build to a NEW release.
# Run ONCE on a Perlmutter login node; never writes to v1.2.2, the unversioned
# installation, or a completed/frozen campaign. No compilation is done here.
set -euo pipefail
umask 027

BASE=/global/common/software/gen0018/mtas
OLD="$BASE/mtas-simulation-v1.2.2"
NEW="$BASE/mtas-simulation-v1.2.3"
TRY=/pscratch/sd/m/michals/MTAS/maintenance/sbzero_trial_v1
WORK="$TRY/source-build"
PATCH="$HOME/MTAS_SB_ZeroTrigger_patch_v1"
COMPARE="$TRY/replayed_case/comparison.txt"
BINARIES=(GenerateDecaySchemes GenerateResponse SortResponse GenerateDecaySchemeMatrix CleanPhysicalResponse PreprocessResponse)

printf 'Source:       %s\nTrial build:  %s\nDestination:  %s\n' "$OLD" "$WORK" "$NEW"
for d in "$BASE" "$OLD" "$WORK" "$PATCH"; do
  [[ -d "$d" ]] || { echo "STOP: missing directory $d" >&2; exit 1; }
done
[[ ! -e "$NEW" && ! -L "$NEW" ]] || { echo "STOP: target already exists: $NEW" >&2; exit 1; }
[[ -f "$COMPARE" ]] || { echo "STOP: comparison report missing: $COMPARE" >&2; exit 1; }
grep -Fqx 'PASS: S+S/main/contaminants identical; S+B modified; 3300 fraction fixed' "$COMPARE" || {
  echo 'STOP: full comparison PASS line was not found' >&2; exit 1;
}

# Check exact baseline hashes, approved patch payload, and tested Scratch sources.
python3 - "$OLD" "$WORK" "$PATCH" <<'PY'
import hashlib, json, sys
from pathlib import Path
old, work, patch = map(Path, sys.argv[1:])
manifest = json.loads((patch/'SOURCE_HASHES.json').read_text())
for rel, expected in sorted(manifest.items()):
    for description, file, hashvalue in (
        ('unchanged v1.2.2', old/rel, expected['before']),
        ('approved patch payload', patch/'payload'/rel, expected['after']),
        ('successfully tested Scratch source', work/rel, expected['after']),
    ):
        if not file.is_file():
            raise SystemExit(f'STOP: missing {file}')
        got = hashlib.sha256(file.read_bytes()).hexdigest()
        if got != hashvalue:
            raise SystemExit(f'STOP: {description}: {rel}: {got} != {hashvalue}')
        print(f'PASS: {description}: {rel}')
PY

# Do not accidentally publish absolute symbolic links back into the old release.
python3 - "$WORK" "$OLD" <<'PY_LINKS'
import os, sys
from pathlib import Path
work, old = map(Path, sys.argv[1:])
for root, dirs, files in os.walk(work, followlinks=False):
    for name in dirs + files:
        item = Path(root) / name
        if item.is_symlink():
            target = os.readlink(item)
            if str(old) in target:
                raise SystemExit(f'STOP: link to old release: {item} -> {target}')
print('PASS: no symbolic links directly target the old installation')
PY_LINKS

for b in "${BINARIES[@]}"; do
  [[ -x "$WORK/bin/$b" ]] || { echo "STOP: missing tested executable: $b" >&2; exit 1; }
  [[ -x "$OLD/bin/$b" ]] || { echo "STOP: missing original executable: $b" >&2; exit 1; }
done
for b in GenerateDecaySchemes GenerateDecaySchemeMatrix CleanPhysicalResponse PreprocessResponse; do
  cmp -s "$OLD/bin/$b" "$WORK/bin/$b" || {
    echo "STOP: unexpected change to unaffected binary: $b" >&2; exit 1;
  }
done
for b in GenerateResponse SortResponse; do
  if cmp -s "$OLD/bin/$b" "$WORK/bin/$b"; then
    echo "STOP: affected executable matches old release; test build may not have been compiled: $b" >&2
    exit 1
  fi
done
printf 'PASS: four unaffected binaries match v1.2.2; two modified binaries differ.\n'

# Versioned, atomic publish on the SAME filesystem. Preserve the tested build.
STAGE=$(mktemp -d "$BASE/.mtas-simulation-v1.2.3.stage.XXXXXX")
echo "Staging to $STAGE"
# If a check fails, intentionally leave the stage for inspection rather than
# recursively deleting anything on the shared software filesystem.
cp -a "$WORK/." "$STAGE/"
chgrp -R gen0018 "$STAGE"
chmod -R g+rX "$STAGE"
find "$STAGE" -type d -exec chmod g+s {} +

cp "$PATCH/SOURCE_HASHES.json" "$STAGE/SB_ZERO_TRIGGER_SOURCE_HASHES.json"
cat > "$STAGE/RELEASE_NOTES_v1.2.3.txt" <<EOF
MTAS simulation v1.2.3 — S+B zero-MTAS beta-trigger primary patch
Base release: $OLD
Tested source/build: $WORK
Patch source: $PATCH
Only production code changed:
  src/sorting/SortEngine.cpp
  src/mixture/PileupEngine.cpp
Affected rebuilt executables:
  bin/GenerateResponse
  bin/SortResponse
Original 100k campaign and v1.2.2 are unchanged.
S+B zero-MTAS beta triggers are included only as S+B primaries.
Main, contaminants and S+S are unchanged; S+B 3300 fraction fixed.
Trial comparison: $COMPARE
NOTE: Original v1.2.2 source verifier may reject these intentional changes.
EOF
(cd "$STAGE/bin" && sha256sum "${BINARIES[@]}") > "$STAGE/binaries.sha256"
(cd "$STAGE/bin" && sha256sum -c ../binaries.sha256)

python3 - "$STAGE" "$PATCH" <<'PY'
import hashlib, json, sys
from pathlib import Path
stage, patch = map(Path, sys.argv[1:])
manifest=json.loads((patch/'SOURCE_HASHES.json').read_text())
for rel, spec in manifest.items():
    got=hashlib.sha256((stage/rel).read_bytes()).hexdigest()
    assert got == spec['after'], (rel, got)
print('PASS: staged production source code has exact patch SHA-256 hashes')
PY

[[ ! -e "$NEW" && ! -L "$NEW" ]] || { echo "STOP: destination was created concurrently: $NEW" >&2; exit 1; }
mv -T -n -- "$STAGE" "$NEW"
[[ -f "$NEW/RELEASE_NOTES_v1.2.3.txt" ]] || {
  echo 'STOP: rename did not create the intended release' >&2; exit 1;
}
(cd "$NEW/bin" && sha256sum -c ../binaries.sha256)
printf '\nPASS: v1.2.3 installed at %s\n' "$NEW"
printf 'Old release untouched. Existing frozen campaigns have NOT been redirected.\n'
