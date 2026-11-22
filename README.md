# MTAS simulation manual — physics and operations v6

Review draft, 22 November 2026. Documentation only; no scientific algorithm changes. Supersedes v5.1. The completed 100k v1.2.1 campaign and v1.2.2 maintenance build/test results are incorporated. Live four-case v1.2.2 acceptance remains pending. Start at [manual overview](docs/index.md), [installation](docs/guides/Installation.md), [new campaign](docs/guides/NewCampaign.md), [scaling](docs/guides/PerformanceAndStorage.md), [storage](docs/guides/StorageAndArchiving.md).

## Preview

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements-docs.txt
mkdocs serve
```

`mkdocs build` creates the static site. Review personal filesystem paths and unpublished study values before public publication. The prior physics source manifest is retained; RELEASE_SOURCE_MANIFEST.csv identifies the maintained archive source files. See CHANGELOG.md for revision scope. GitHub publishing is outside this update.
