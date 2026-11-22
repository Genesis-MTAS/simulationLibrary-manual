# Editing and publishing the documentation with MkDocs

MkDocs turns these Markdown files into a navigable static documentation site. It is **not** a continuously running web application: `mkdocs serve` is only the local development-preview server.

## Recommended workflow

The canonical source repository should eventually contain `mkdocs.yml`, `docs/`, and the program source together. The material in this documentation-only archive is a draft intended for review and integration into that repository; it is not another simulator installation.

On Ubuntu (from the folder containing `mkdocs.yml`):

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-docs.txt
mkdocs serve
```

Browse locally at `http://127.0.0.1:8000/`. Saving a Markdown file refreshes the development site while `mkdocs serve` is running. Close the terminal or stop the command to stop the preview.

For a **local static build**, run:

```bash
mkdocs build
```

This creates a `site/` folder containing HTML, CSS, JavaScript and the search index. You can copy it to any ordinary static web server; it does not need a Python server once published. Some features may not work properly when opened through `file://` rather than HTTP, so for offline browsing prefer an ordinary localhost static server or a local webserver rather than relying on file links.

## Always-available wiki-style hosting

**GitHub Pages** is already in use for the separate manual repository `Genesis-MTAS/simulationLibrary-manual`. The present v6 archive is a review draft; do not replace published material until it is approved. For a configured and authenticated repository, the general MkDocs deployment commands are:

```bash
mkdocs build
mkdocs gh-deploy
```

`gh-deploy` commits the generated website into a `gh-pages` branch and pushes that branch to the configured remote. In the repository's **Settings → Pages**, select the publishing source/branch as needed. The website will generally be accessible at `https://GITHUB-USER.github.io/REPOSITORY/`. It remains online even if your desktop and Perlmutter are off. When the documents change, rebuild/redeploy or later configure a GitHub Actions workflow to publish automatically.

**Read the Docs** is another option, with builds triggered by repository updates and features for versioned manuals. It requires a hosted documentation project/repository integration, whereas GitHub Pages can be deployed directly from MkDocs. Both approaches keep the Markdown files authoritative.

**Visibility and timing:** GitHub Pages for a public repository is available with GitHub Free. A site from a private repository may have different plan requirements and is not automatically private merely because the source repository is private. Do not publish scientific information, restricted data, credentials, or institution-specific internal details without reviewing access requirements. Review v6 locally first; actual publication and source-repository export are a separate task.

## MkDocs configuration and links

`mkdocs.yml` at the project root controls the navigation tree. Each navigation target names a Markdown file relative to `docs/`. Prefer relative links for chapter cross-references, for example:

```markdown
[Beta spectra](../physics/BetaSpectra.md)
```

We use the built-in MkDocs theme, plus `pymdown-extensions`/Arithmatex and MathJax 3 for scientific equations. `requirements-docs.txt` lists the two Python documentation dependencies; MathJax is loaded from a public CDN by default, so browsers need Internet access for typeset equations. To make an entirely offline bundle, bundle the MathJax JavaScript and fonts as project assets before release. Material for MkDocs is optional later.

## Documentation release checklist

1. Check all internal Markdown links and run `mkdocs build --strict` before release.
2. Verify CLI options and defaults against the versioned source code, not just older README files.
3. Review equations, energy units and terminology with a physics-domain reviewer.
4. Confirm licensing/redistribution permission for all images, example input data and third-party components.
5. Remove real user identifiers and absolute personal filesystem paths from public examples where unnecessary.
6. Record a release tag, compiler/ROOT requirements, data-format versions and a link to tests/regression results.

Official guidance: [MkDocs deployment](https://www.mkdocs.org/user-guide/deploying-your-docs/) and [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages).
