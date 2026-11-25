# Documentation checks for v6.1

- Compared all 29 scientific source files under `src/` in the maintenance archive against the premaintenance source archive: identical bytes. All 11 physics Markdown chapters are preserved byte-for-byte from v5.1.
- Checked 50 MkDocs navigation targets and 240 relative Markdown link paths: all exist. Checked Markdown fence balance and 83 shell code blocks with `bash -n`: passed syntax checks. This does not establish execution for every example.
- Current CLI and defaults cross-checked against maintenance source (project controller, metrics, scaling reporter, launchers). New installation procedure combines the successful separate build and acceptance commands.
- MkDocs is not installed in the review environment; rendered site build not executed. Run `mkdocs build --strict` locally after installing requirements.
- Real-library acceptance evidence added from NERSC job `61769631`: 4/4 complete, stage timing, output presence, shard accounting and observed group-ownership caveat. The operator did not supply a separate full `production_scheme_index.py --verify` log for this smoke test; do not claim that specific check as independently reported.
- Remaining evidence: final full dataset archival, independent fixed-reference scientific comparison, group-sharing configuration for *new* projects, operator review.
