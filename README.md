# unanue.mx

Personal site of Adolfo De Unánue — data science, machine learning, and
operations research on national-scale infrastructure. Live at
[unanue.mx](https://unanue.mx).

## How it builds

Pages come from `site.org`, one org subtree per page: seven sections
(about, writing, research, software, teaching, cases, talks) plus a CV
page. Posts come from `writing/`, one org file per post. ox-hugo exports
both to `content/` (generated, gitignored), and Hugo builds the site
with the `unanue` theme in
`themes/unanue/` — a custom navy-gold theme ported from the design
canvas in `design/`.

The export runs headless Emacs with packages installed project-locally
into `tools/elpa/` (gitignored), so neither the local build nor CI
depends on a personal Emacs configuration. Citations use org-cite with
`references.bib`, rendered through citeproc.

## Commands

```
just setup    # install ox-hugo + citeproc into tools/elpa (first run)
just export   # site.org and writing/*.org → content/
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

**A post is one file in `writing/`.** The Writing section's intro stays
in `site.org`; each post is `writing/<slug>.org`, exported as a whole
file. The keywords do the work that subtree properties do in `site.org`:

```org
#+title: Post title
#+author: Adolfo De Unánue
#+date: 2026-09-13
#+keywords: one "two words" three
#+language: en
#+options: toc:nil num:nil author:nil ^:nil tags:nil todo:nil prop:nil
#+options: eval:never-export
#+property: header-args :eval never-export :exports results
#+hugo_base_dir: ..
#+hugo_section: writing
#+export_file_name: slug
#+hugo_draft: true
#+hugo_custom_front_matter: :layout "monograph"
#+bibliography: ../references.bib
#+cite_export: csl
```

- `toc:nil num:nil` are required. ox-hugo otherwise writes its own table
  of contents into the post, duplicating the one the monograph layout
  builds, and numbers every heading.
- `#+keywords` becomes the `keywords` front matter list, split on spaces;
  quote a keyword that contains one.
- `#+export_file_name` sets the URL, so renaming the file does not.
- `^:nil` keeps `as_of_date` from rendering as subscripts.
- End a post that cites anything with `#+print_bibliography:`.

**Drafts stay out of the repository.** It is public, and
`#+hugo_draft: true` hides a page from the site, not from GitHub. An
unfinished post is `writing/<slug>.draft.org`, which `.gitignore`
excludes; `just serve` still renders it. To publish, rename it to
`writing/<slug>.org`, set `#+hugo_draft: false`, then commit and push.

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

`writing/typography-test.org` is a committed draft exercising both;
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
site.org              page source (edit this)
writing/              post sources, one org file per post; *.draft.org gitignored
references.bib        bibliography for org-cite
hugo.toml             Hugo configuration
themes/unanue/        custom theme: layouts + assets/css/main.css
static/CNAME          the apex domain for GitHub Pages
static/cv/            CV PDFs, copied from ../cv
design/               design canvas artboards and social preview images
tools/                headless export scripts (install-packages.el, export.el)
archive/quarto/       the retired Quarto scaffold, kept for reference
```
