# unanue.mx

Personal site of Adolfo De Unánue — data science, machine learning, and
operations research on national-scale infrastructure. Live at
[unanue.mx](https://unanue.mx).

## How it builds

`site.org` is the single source: one org subtree per page, seven
sections (about, writing, research, software, teaching, cases, talks)
plus a CV page. ox-hugo exports it to `content/` (generated,
gitignored), and Hugo builds the site with the `unanue` theme in
`themes/unanue/` — a custom navy-gold theme ported from the design
canvas in `design/`.

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

## Source conventions

**A section with entries needs three levels.** The top heading declares
the section and carries no `EXPORT_FILE_NAME`; a nested `_index` subtree
carries the intro; the entries are its siblings:

```org
* Research
:PROPERTIES:
:EXPORT_HUGO_SECTION: research
:END:

** Research
:PROPERTIES:
:EXPORT_FILE_NAME: _index
:END:
Intro paragraph.

** Some paper
:PROPERTIES:
:EXPORT_FILE_NAME: some-paper
:END:
```

Putting `EXPORT_FILE_NAME: _index` on the top heading instead makes
ox-hugo export the children into the section page as well as into their
own files, so every entry's prose appears twice. Research, Software and
Cases all follow the three-level shape.

**Margin notes** need `layout = "monograph"` in the page's front matter,
which reserves a third column for them.

- An Org footnote becomes a numbered sidenote:
  `a claim[fn:: Ashby, /An Introduction to Cybernetics/ (1956).]`
  `layouts/partials/sidenotes.html` splices the note body back to its
  reference point at build time; CSS floats it into the margin, and a
  hidden checkbox reveals it inline below 1240px. No JavaScript. Keep a
  note to one paragraph — a multi-paragraph note makes the partial leave
  the whole page's notes at the bottom, which still reads correctly.
- An unnumbered note beside the paragraph:

  ```org
  #+begin_marginnote
  The aside goes here.
  #+end_marginnote
  ```

`content/writing/typography-test.md` is a draft page exercising both;
`just serve` renders it, `just build` leaves it out.

**Colour theme.** The palette follows the reader's system setting and a
header control pins it to light or dark, stored in `localStorage`.
Without JavaScript the control is hidden and the system setting decides.
The dark tokens are written twice in `main.css`, once under
`prefers-color-scheme` and once under `[data-theme="dark"]`; CSS cannot
share declarations across a media query and an attribute selector, so
edit both.

**The CV PDFs are copies.** `static/cv/adolfo-de-unanue-cv.pdf` and
`-es.pdf` come from `../cv/unanue.pdf` and `../cv/unanue_es.pdf`. Copy
them again when that repository rebuilds them.

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
static/CNAME          the apex domain for GitHub Pages
static/cv/            CV PDFs, copied from ../cv
design/               design canvas artboards and social preview images
tools/                headless export scripts (install-packages.el, export.el)
archive/quarto/       the retired Quarto scaffold, kept for reference
```
