# unanue.mx

Personal site of Adolfo De Unánue — data science, machine learning, and
operations research on national-scale infrastructure. Live at
[unanue.mx](https://unanue.mx).

## How it builds

`site.org` is the single source: one org subtree per page, seven
sections (about, writing, research, software, teaching, cases, talks).
ox-hugo exports it to `content/` (generated, gitignored), and Hugo
builds the site with the `unanue` theme in `themes/unanue/` — a custom
navy-gold theme ported from the design canvas in `design/`.

The export runs headless Emacs with packages installed project-locally
into `tools/elpa/` (gitignored), so neither the local build nor CI
depends on a personal Emacs configuration. Citations use org-cite with
`references.bib`, rendered through citeproc.

## Commands

```
just setup    # install ox-hugo + citeproc into tools/elpa (first run)
just export   # site.org → content/
just build    # export, then hugo --minify
just serve    # export, then hugo server -D
just deploy   # push main; GitHub Actions builds and publishes
```

Requires Emacs 29+ and Hugo (pinned to 0.165.0 in CI; see
`.github/workflows/deploy.yml`).

## Deploy

Push to `main`. The deploy workflow exports, builds, and publishes
`public/` to the `gh-pages` branch, which GitHub Pages serves at the
apex domain (`static/CNAME`). DNS lives at Fastmail; mail records stay
untouched.

## Layout

```
site.org              content source (edit this)
references.bib        bibliography for org-cite
hugo.toml             Hugo configuration
themes/unanue/        custom theme: layouts + assets/css/main.css
design/               design canvas artboards and social preview images
tools/                headless export scripts (install-packages.el, export.el)
archive/quarto/       the retired Quarto scaffold, kept for reference
```
