# Documentation checks for v6

- Compared all 29 scientific source files under `src/` in the maintenance archive against the premaintenance source archive: identical bytes. All 11 physics Markdown chapters are preserved byte-for-byte from v5.1.
- Checked 50 MkDocs navigation targets and 240 relative Markdown link paths: all exist. Checked Markdown fence balance and 82 shell code blocks with `bash -n`: passed syntax checks. This does not establish execution for every example.
- Current CLI and defaults cross-checked against maintenance source (project controller, metrics, scaling reporter, launchers). New installation procedure combines the successful separate build and acceptance commands.
- MkDocs is not installed in the review environment; rendered site build not executed. Run `mkdocs build --strict` locally after installing requirements.
- Remaining evidence: four-case real-library v1.2.2 acceptance output, final full dataset archival, independent fixed-reference scientific comparison, operator review.
