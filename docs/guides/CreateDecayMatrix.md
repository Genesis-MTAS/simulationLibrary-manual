# Guide: generate a decay-scheme matrix without detector simulation

`GenerateDecaySchemeMatrix` reads a valid scheme and writes a normalized mathematical β-feeding × **first γ transition** probability matrix. This is independent of the response library, detector thresholds and contamination.

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2
"$TREE/bin/GenerateDecaySchemeMatrix" \
  /absolute/path/to/scheme/Decay.xml \
  /absolute/path/to/decay_matrix.root \
  --binning mtas354
```

You can choose an explicit energy grid:

```bash
"$TREE/bin/GenerateDecaySchemeMatrix" \
  /absolute/path/to/scheme/Decay.xml /absolute/path/to/matrix.root \
  --physical /absolute/path/to/physical.root
```

When `--physical` is given, the program gets edges from `physical.root`'s `final/3350` and does not resolve the other binning options. Without a physical file it supports `--binning mtas354|uniform|custom`, `--uniform-width-kev`, and `--edges-file` as appropriate. The matrix integral is one for valid schemes. It does **not** encode the whole gamma cascade or detector efficiency.

A full ML pipeline already embeds this target when `PreprocessResponse` is called with `--decay-xml`; standalone matrix generation is optional for independent checks and research. See [matrix program](../programs/GenerateDecaySchemeMatrix.md).
