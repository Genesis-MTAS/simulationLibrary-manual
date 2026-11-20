# MTAS technical manual — source review v1

This is a modular Markdown **documentation overlay**, not a software update. It was written from the uploaded November 18, 2026 canonical source tarball, including the Step 3c campaign driver.

- `docs/programs/`: seven program pages with CLI, algorithms and behavior.
- `docs/physics/`: six shared scientific-model pages.
- `docs/reference/`: configs and output structures.
- `docs/guides/`: NERSC queue/scaling notes.
- `docs/development/`: architecture and source-review observations.
- `mkdocs.yml`: optional MkDocs site navigation.

## Review / deployment

Read `docs/development/SourceReview.md` first. Treat this as a technical draft requiring review, not complete final publication documentation. You may copy the Markdown into the canonical `docs/` tree once reviewed, without replacing the existing source code or tests.

To preview with MkDocs on a system where it is installed:

```bash
mkdocs serve -f mkdocs.yml
```

No MkDocs installation or network access is required to read the Markdown in GitHub or a text editor.
