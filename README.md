> **v5.1 backlog addendum (November 20, 2026):** Added a permanent libxml2 runtime-resolution work item and the deferred known-γ-intensity variation idea to `docs/development/ProductionReadiness.md`. Remaining chapters are the original v5 snapshot and do not document production-controller v1.2; see current controller release for tranche commands. No software code was changed.

# MTAS simulation manual — physics, configuration and operations v5

**Complete, standalone Markdown/MkDocs replacement for v4**, authored from the user-supplied canonical MTAS C++ source archive (Nov 18, 2026), the production-controller v1.1 implementation, and the reported NERSC acceptance results through November 19. This is **documentation only**; no installed simulation code or currently submitted jobs are changed.

## Highlights in v5

- **Detailed [event-resolved pileup](docs/physics/PileupDetailed.md):** exact 19-crystal coincidence processing, beta gate, three meanings of zero, event-wise creation of raw and final `3350`, source pair probabilities and normalization/yield accounting.
- **Detailed [time evolution](docs/physics/TimeEvolutionDetailed.md):** source decay constants, S+S and S+B effective time dependence, normalized observation window, and the **Bateman daughter-grow-in equations** explicitly identified as the *first planned scientific development feature*, not yet implemented.
- **Detailed [physical and ML normalization](docs/physics/NormalizationAndReconstruction.md):** weighted additive counts, width-density correction, shared-family log transform, exact inversion for each component, summation in linear space, optional unit-area normalization. Includes a read-only [`uproot` reconstruction example](docs/examples/ReconstructML.py).
- **Current general workflow:** create and edit six independent per-project INIs (defaults or previous campaign), preflight, freeze, dry-run, submit multi-node shards, monitor, recover, report, archive.
- New/updated [New campaign](docs/guides/NewCampaign.md), [Configure campaign](docs/guides/ConfigureCampaign.md), [Check Slurm jobs](docs/guides/CheckingJobs.md), [Recovery](docs/guides/Recovery.md), [Outputs](docs/guides/InspectOutputs.md), [Storage](docs/guides/StorageAndArchiving.md), and [100k operator preparation](docs/guides/Production100k.md) guides.

## Read and render

All chapters can be opened as ordinary Markdown. For interactive navigation and math rendering:

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements-docs.txt
mkdocs serve
```

To build a static site, use `mkdocs build` from this directory (the one containing `mkdocs.yml`). GitHub Pages publishing can be arranged later; no account is needed to read or preview locally. Avoid publishing unpublished research-specific values or personal paths without review.

## Status and evidence limits

The scheme-2 1,024-case full pipeline and the production two-node 512-case acceptance test passed. The **512-case single-node control test** for unexpectedly reduced throughput was still running/awaiting results when this revision was prepared. The **independent fixed-reference scientific regression** and final six-INI approval for 100k also remain outstanding. Bateman daughter production/grow-in is a specification for the next scientific development stage, not an existing feature.

The Python `ReconstructML.py` example has been syntax checked but must still be tested against real ROOT files with `numpy` and `uproot`. Markdown links and navigation have been checked; no MkDocs executable was present for a final rendered-site build in this environment.

`SOURCE_MANIFEST.csv` lists source files used for the scientific and controller review, with SHA-256 hashes. It is not a manifest of generated result files or an assertion that the manual is an exact compiled release.
