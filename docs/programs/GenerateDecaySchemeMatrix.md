# GenerateDecaySchemeMatrix

**Source:** `src/apps/GenerateDecaySchemeMatrix.cpp`, `src/decay/DecaySchemeMatrixModel.*`, `src/decay/DecaySchemeMatrixRoot.*`. Standalone deterministic probability-matrix generator; it does **not** sample detector events.

```bash
bin/GenerateDecaySchemeMatrix Decay.xml matrix.root   [--physical physical.root]   [--binning mtas354|uniform|custom]   [--uniform-width-kev N]   [--edges-file FILE]
```

Default binning is `mtas354`, and default `--uniform-width-kev` is 100. When `--physical` is supplied, this program reads energy edges from `final/3350` and uses them instead of the explicitly selectable binning. It refuses to overwrite the decay input or a specified physical ROOT file.

The model reads the β feeding and first γ transitions to enumerate β-feeding × first-γ paths, aggregates their probabilities into energy bins, and writes `final/decaySchemeMatrix` plus its path metadata. Multiple paths mapping to the same matrix cell **accumulate** their probabilities. The total matrix integral is 1 under valid input. The model intentionally ignores `StopLevel` for the mathematical path representation (see model source).

## When to use it

Use this program for standalone analysis, debugging, independent validation or generating a matrix for a specific XML/physical energy grid. **The campaign does not call it separately by default**: `PreprocessResponse --decay-xml` writes the same class of untransformed matrix into `ml.root`.

See [DecaySchemeMatrix physics](../physics/DecaySchemeMatrix.md) and [energy binning](../reference/Configurations.md).
