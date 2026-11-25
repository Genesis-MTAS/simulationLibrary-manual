# v6.3 model-documentation source audit

The β and γ chapters were authored directly from the **v1.2.3 repository candidate source**, not from prior conversations or general physics expectations.

- `src/apps/GenerateDecaySchemes.cpp`: `889ab065aa1f26f2ace49059f8b404d082850693975212594aa89774d78a360f` (SHA-256).
- `config/defaults/GenerateDecaySchemes.ini`: `119e70f7d7d4f27e7f30a833b268f3cd109436db34b5f2ae2c1c33cff4129d37` (SHA-256).
- Source functions inspected: `LoadScheme`, `CompleteSkeleton`, `PhaseSpace`, `FrozenGammaOnly`, `ChooseBetaModel`, `DrawFedFraction`, `ClusterWeights`, `WeightedIndex`, `AssignBeta`, `GammaWeight`, `Widths`, `DrawBranchCount`, `GenerateGammas`, `Populations`, `GammaOnlyStats`, `Multiplicity`, `OneVariation`, `ReachableDaughterLevels`, `WriteVariation`, and `main`.
- The manual's three new chapters are **explanatory documentation**, not proposals for modifying parameters or algorithms. No C++ source or INI was changed.
- The reviewed source is the package assembled from the installed release plus the supplemental export. The source archive also includes an unverified portable Makefile: new Makefile acceptance is **not implied** by the physics review.
- v6.2 `RELEASE_SOURCE_MANIFEST.csv` and `SOURCE_MANIFEST.csv` are preserved as **historical manifests**, not rewritten as checksums of v6.3 Markdown files.
- For source identity, compare the SHA-256 recorded above to the exact installed generator if the release is modified after the review.
