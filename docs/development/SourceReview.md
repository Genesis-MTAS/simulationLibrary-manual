**Current implementation addendum:** The code snapshot contains six scientific C++ applications; production orchestration comes from installed `MTAS_ProductionWorkflow_v1_1` and passed a real 512-case two-shard acceptance test. The available electron/gamma binary library ends at **10 MeV**, consistent with `GenerateResponse.cpp maxLibraryKeV=10000`; this is not a discrepancy. New physics reference chapters: [pileup](../physics/PileupDetailed.md), [time evolution and Bateman](../physics/TimeEvolutionDetailed.md), [normalization and ML inverse](../physics/NormalizationAndReconstruction.md).

# Source-review findings, documentation v1

Source: user-provided canonical tarball from `mtas-simulation/` on 2026-11-18. These are **observations for discussion**, not automatic source-code modifications.

1. **Compiled response energy limit:** `src/apps/GenerateResponse.cpp` defines `maxLibraryKeV=10000`, consistent with the currently deployed monoenergetic electron/gamma library extending to 10,000 keV, as confirmed by the project owner. The 12,000-keV histogram upper edge is a separate analysis binning convention. To simulate particles above 10 MeV, the library and compiled range must both be extended.
2. **Archived docs are stale:** bundled `docs/CAMPAIGN_DRIVER.md` describes Step 3a and says the library is read on CFS; actual deployment runtime path and Step 3c driver use Scratch and allow safe intermediate deletion. Do not copy stale text into the final manual.
3. **Raw sorter zeros:** Source intentionally writes zero-valued IMO crystals in raw `3305` and `3350`, while finished rebinned products have a different zero/low-Y policy. This distinction must remain documented and tested.
4. **Matrix meaning:** `decaySchemeMatrix` means **β-fed excitation vs first-γ destination**, not a complete detector-energy response or an arbitrarily ordered full-cascade histogram.
5. **Current scaling status (updated November 19):** the schema-2 cleanup pilot, 16-case Slurm array, 64-case one-node packed test, and 1,024-case packed-256 full pipeline all completed successfully. The v1.1 production workflow also passed a real **512-case two-shard/two-node** validation test with all intermediates deleted. Its measured per-node throughput was below the one-node 1,024-case benchmark; a controlled single-node 512-case comparison was launched and its result is still awaited.
6. **Config limitations:** generator currently accepts one named gamma model and fixed `mtas_354` skeleton profile; this is intentional implementation scope.
7. **Need deeper review before public release:** inspect all error paths and serialization fields against exact ROOT output files, compare the full fixed-reference physics regression, and audit software licensing/dependencies and provenance of archived data.

Do not use doc work as justification to change physics while scaling tests are running.

## Documentation revision v2

The 10-MeV response library (12 MeV final analysis axis); these are separate parameters with different meanings.

Additional source observations: the generator's lightweight INI reader does not reject every unknown key; avoid claiming typo-proof configuration parsing. Exact raw and mixture histogram zero-bin policies differ intentionally. Schema-2 campaign-level validation presently verifies final maxima, matrix integral and physical additivity, but **not yet** every-cell shared-log inversion against physical counts. A manual reviewer should keep this distinction when interpreting the PASS status of a pilot campaign.
