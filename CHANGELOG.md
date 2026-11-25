# v6.3 — gamma and beta-spectra chapter review update (November 25, 2026)

- Reorganized the statistical γ-transition chapter around the actual generation tasks (branch count, eligible lower levels, energy-weighted destination selection, gamma-distributed partial widths, intensity normalization/pruning), with a numerical 92Zr-inspired example and **five** explanatory diagrams/figures (SVG + PNG). Kept experimental topology/intensity freeze and γ-only-level rules explicit.
- Expanded the β− electron-spectrum chapter with the exact `GenerateResponse.cpp` calculation, including the relativistic Coulomb/Euler-product implementation, codes 0–4 of `ShapeFactor`, spin/parity inference, screening omission, midpoint integration and library-energy mapping. Added **four** figures (SVG + PNG), including 92Y spectra for ground-state and 934.49-keV feeding and a comparison of shape codes.
- The β-feeding models chapter from the preceding review is **unchanged**. No source or INI was modified. The calculations in the new β-spectrum plots use the v1.2.3 C++ routines transcribed into a ROOT-independent calculation; 92Y endpoints and level labels follow the supplied XML.
- The generated curves are pre-detector continuum spectra; they are not experiment or full simulation results. Full rendered MkDocs acceptance remains with the publisher.

---

# v6.3 review draft — November 25, 2026

- Expanded the source-verified `GenerateDecaySchemes` physics into three technical chapters: **β-feeding models**, **γ-transition generation**, and **complete construction/validation/cascade statistics**; retained a concise overview.
- Documented the exact allowed β phase-space midpoint integral, model-dependent active-feeding fraction laws, level-selection powers, Gaussian clustering prior, gamma-distributed β strengths and iterative positive-intensity floor.
- Documented γ destination eligibility (ground or lower *directly β-fed* levels unless frozen/forced), the lack of a topology-frozen/intensity-only variation mode, broadened-Poisson outgoing counts, `E_gamma^3 exp(-E_gamma / scale)` weighting, Porter–Thomas-like widths, weak-γ pruning, and the inherited/forced γ-only cascade rules.
- Added exact dynamic-programming formulae for γ multiplicity, γ-only event fractions, path counting, 64-bit per-variation seed derivation, validation tolerances and XML reachability pruning.
- Verified the model descriptions against v1.2.3 `src/apps/GenerateDecaySchemes.cpp` (SHA-256 `889ab065aa1f26f2ace49059f8b404d082850693975212594aa89774d78a360f`) and its default INI; **no simulation source code or statistical parameters were changed**.
- Updated manual navigation and links to the new model sections. Also recorded the confirmed v1.2.3 installation status in the overview; separate full-controller acceptance remains deferred.

---

# v6.2 — November 24, 2026

- Documented the v1.2.3 S+B zero-trigger **physics change**: silicon-triggered events with processed total MTAS energy exactly zero are eligible only as the first S+B member. Main, contaminants, and S+S remain unchanged. S+B source selection and within-source sampling use the true zero/positive β-trigger counts without storing a large zero-event reservoir.
- Recorded the passed single-case replay: S+B `3300` fraction 0.753500% before/after; exact agreement of main, S+S, and 92Sr component bins; S+B shapes differ in 3300/3350/3351/energyTime as intended. The 2D signed sums need not be zero due to independent Y cuts.
- Added guarded v1.2.3 side-by-side deployment guidance. For **new** campaigns, select `/global/common/software/gen0018/mtas/mtas-simulation-v1.2.3` using `--tree`, and verify the frozen run paths. Historical runs are never retargeted.
- Updated the default/current-version operational references from v1.2.2 to v1.2.3 where applicable, retaining v1.2.2 commands and metrics where they document the historical maintenance release. The old `verify_maintenance_release.py` hash contract is **not** a valid unmodified v1.2.3 release check.
- Evidence boundary: the patch replay passed on NERSC; the actual permanent v1.2.3 promotion and a new full v1.2.3 production-controller acceptance are **not claimed as completed** by this draft.

---

## v6.1 review draft — 2026-11-22

- Updated installation and operator workflow for v1.2.2, including actual `mtas` function, writable workspace, eight-CPU acceptance, versioned deployment, explicit initial selection and resume, reporting and scheduling overrides.
- Recorded completed 100k campaign, six Slurm tranches, observed cost/makespan, recommended 4 vs 32 nodes, straggler limitations, and archival report paths.
- Updated storage, purge, sharing, library completeness, archive and recovery guidance. Full dataset archival remains unconfirmed.
- v6.1: recorded **passed** full-scope four-case real-library v1.2.2 acceptance (Slurm 61769631), actual stage statistics, generated physical/ML ROOTs, and the personal-group ownership caveat for new project creation. The smoke-test results are not a production scaling benchmark.
- Preserved detailed source-reviewed physics chapters and earlier source manifest. Historical development observations are labeled; current readiness is authoritative. No software modifications.
