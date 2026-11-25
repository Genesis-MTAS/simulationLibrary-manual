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
