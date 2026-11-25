# Documentation checks for v6.3 (model-detail review)

- Compared the detailed β/γ formulas and sampling constraints against **the v1.2.3 `GenerateDecaySchemes.cpp` source** (SHA-256 `889ab065aa1f26f2ace49059f8b404d082850693975212594aa89774d78a360f`) and its official default `GenerateDecaySchemes.ini` (SHA-256 `119e70f7d7d4f27e7f30a833b268f3cd109436db34b5f2ae2c1c33cff4129d37`).
- Added three physics chapters, reduced duplicated program-level material, and updated the navigation, index, scheme guide, and configuration links.
- Reviewed the model's *specific source-derived distinction* between frozen experimental γ branching (connections **and** numerical intensities) and resampled known β feeding (positive connectivity only).
- Checked internal Markdown link destinations, MkDocs nav targets, Markdown fence balance, and mathematical block delimiter balance. These are static checks, not a full MkDocs rendering.
- The current review environment could not install MkDocs because its Python package index was unavailable; **rendered-site acceptance remains to be run by the manual publisher** (`pip install -r requirements-docs.txt && mkdocs build --strict`).
- No C++ scientific source or default INI was modified. Existing v6.2 physics/operations sections are retained unless explicitly linked or status-corrected.
- Original source provenance manifests remain historical; v6.3 source identity is documented in `MODEL_SOURCE_VERIFICATION_v6_3.md`.

---

# Documentation checks for v6.1

- Compared all 29 scientific source files under `src/` in the maintenance archive against the premaintenance source archive: identical bytes. All 11 physics Markdown chapters are preserved byte-for-byte from v5.1.
- Checked 50 MkDocs navigation targets and 240 relative Markdown link paths: all exist. Checked Markdown fence balance and 83 shell code blocks with `bash -n`: passed syntax checks. This does not establish execution for every example.
- Current CLI and defaults cross-checked against maintenance source (project controller, metrics, scaling reporter, launchers). New installation procedure combines the successful separate build and acceptance commands.
- MkDocs is not installed in the review environment; rendered site build not executed. Run `mkdocs build --strict` locally after installing requirements.
- Real-library acceptance evidence added from NERSC job `61769631`: 4/4 complete, stage timing, output presence, shard accounting and observed group-ownership caveat. The operator did not supply a separate full `production_scheme_index.py --verify` log for this smoke test; do not claim that specific check as independently reported.
- Remaining evidence: final full dataset archival, independent fixed-reference scientific comparison, group-sharing configuration for *new* projects, operator review.
