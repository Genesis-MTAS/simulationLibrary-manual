# MTAS simulation manual — physics and operations v6.2

Review draft v6.2, 24 November 2026. Includes the scoped v1.2.3 S+B zero-MTAS beta-trigger patch, its passed single-case replay against the completed v1.2.1 100k dataset, and a guarded new-directory deployment procedure. Supersedes v6.1; prior v1.2.1 and v1.2.2 observations remain historical, not v1.2.3 benchmarks. Start at [manual overview](docs/index.md), [installation](docs/guides/Installation.md), [new campaign](docs/guides/NewCampaign.md), [scaling](docs/guides/PerformanceAndStorage.md), [storage](docs/guides/StorageAndArchiving.md).

## Preview

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements-docs.txt
mkdocs serve
```

`mkdocs build` creates the static site. Review personal filesystem paths and unpublished study values before public publication. The prior physics source manifest is retained; RELEASE_SOURCE_MANIFEST.csv identifies the maintained archive source files. See CHANGELOG.md for revision scope. GitHub publishing is outside this update.
