# unanue.mx

Personal website for Adolfo De Unánue — researcher in machine learning,
operations research, and political economy.

## Tech stack

- **Source**: Org-mode files under `org/`
- **Build**: `emacs --batch` + `publish.el` (custom Tufte-flavored HTML backend)
- **Style**: [Tufte CSS](https://edwardtufte.github.io/tufte-css/) vendored under `static/tufte-css/`
- **Task runner**: [`just`](https://github.com/casey/just)
- **Hosting**: GitHub Pages (deployed via GitHub Actions on push to `main`)

No Quarto, no Node, no Hugo. The only runtime dependency is Emacs plus the
`org` and `htmlize` packages (installed automatically on first build into
`.packages/`).

## Layout

```
org/                 # Org-mode sources
  index.org
  about.org
  posts/
  papers/
  projects/
static/              # Assets copied verbatim into public/
  tufte-css/         # Vendored Tufte CSS + et-book fonts
  site.css           # Site-specific overrides
publish.el           # Build script (org-publish + Tufte backend)
justfile             # Task runner recipes
CNAME                # Custom domain for GitHub Pages
.github/workflows/
  publish.yml        # CI: build with emacs, deploy to Pages
```

## Local development

Prerequisites: `emacs` (>= 28), `just`, `python3` (for the preview server).

```bash
just build     # build to ./public
just serve     # build + preview on http://localhost:8000
just rebuild   # clean build
just clean     # remove build output and caches
```

## Writing

Drop `.org` files anywhere under `org/`. Each file becomes one HTML page
at the same relative path in `public/`.

```
org/
  index.org           -> /index.html
  about.org           -> /about.html
  posts/
    my-post.org       -> /posts/my-post.html
    index.org         # auto-generated; ignored in git
  papers/
  projects/
```

### Post front matter

```org
#+TITLE: My new post
#+DATE: <2026-04-10>
#+AUTHOR: Adolfo De Unánue
#+FILETAGS: :ml:research:
#+OPTIONS: toc:nil num:nil
```

**Write dates as Org timestamps (`<YYYY-MM-DD>`), not plain strings.**
`org-publish-find-date` only recognizes `#+DATE` when it is a proper Org
timestamp (`<…>` or `[…]`); plain `YYYY-MM-DD` silently falls back to
the file's mtime. The sitemap, RSS feed, and tag pages all rely on
timestamp dates for chronological sorting.

### Sidenotes

Regular Org footnotes are rewritten at export into Tufte sidenotes:

```org
This claim is suspect[fn:1] but let's roll with it.

[fn:1] Explanation of why, shown in the right margin on desktop.
```

The bottom "Footnotes" section that Org would normally append is
suppressed — the content is inlined at the reference point instead.

### Auto-generated index of posts

`publish.el` runs `org-publish` with `:auto-sitemap t` on the posts
project, generating `org/posts/index.org` on every build and publishing
it as `/posts/index.html`. The entries are rendered as:

```
2026-04-06 — [link to post] Post title
```

sorted anti-chronologically by `#+DATE`. The file is gitignored; do
not edit it by hand.

### RSS feed

Every build writes a RSS 2.0 feed to `/feed.xml`, linked from every
page via a `<link rel="alternate">` tag in the `<head>`. Items are
generated from every post under `org/posts/` that has a `#+DATE`,
sorted newest-first.

### Tags

Declare tags per file with `#+FILETAGS:`:

```org
#+FILETAGS: :ml:research:bayes:
```

After publishing, `publish.el` walks every post, collects tags, and
writes:

- `/tags/index.html` — alphabetical list of tags with post counts
- `/tags/<tag>.html` — all posts carrying that tag, newest first

Tag pages are plain Tufte-styled HTML (not generated via Org export) to
keep the build simple.

### Full-width figures

```org
#+ATTR_HTML: :class fullwidth
[[file:diagram.png]]
```

## Deployment

### GitHub Pages

1. In the repo settings, set **Settings → Pages → Source** to **"GitHub
   Actions"** (not "Deploy from a branch").
2. Push to `main`. The `Publish` workflow builds the site with Emacs and
   deploys it via `actions/deploy-pages`.
3. Add the custom domain `unanue.mx` under **Settings → Pages → Custom
   domain**. The `CNAME` file at the repo root is also copied into the
   artifact so the domain persists across deploys.
4. Once the certificate provisions, enable **Enforce HTTPS**.

### DNS (Fastmail — authoritative)

`unanue.mx`'s nameservers point to Fastmail
(`ns1.messagingengine.com`, `ns2.messagingengine.com`), so **all DNS
records live in the Fastmail panel**, not GoDaddy. GoDaddy is only the
registrar — ignore its DNS editor entirely.

In Fastmail: **Settings → Domains → unanue.mx → Advanced DNS records**.

Leave the existing Fastmail mail records in place (MX, SPF TXT, DKIM
CNAMEs). Add the following records for GitHub Pages:

| Type  | Name | Value                   |
|-------|------|-------------------------|
| A     | @    | `185.199.108.153`       |
| A     | @    | `185.199.109.153`       |
| A     | @    | `185.199.110.153`       |
| A     | @    | `185.199.111.153`       |
| AAAA  | @    | `2606:50c0:8000::153`   |
| AAAA  | @    | `2606:50c0:8001::153`   |
| AAAA  | @    | `2606:50c0:8002::153`   |
| AAAA  | @    | `2606:50c0:8003::153`   |
| CNAME | www  | `nanounanue.github.io.` |

Do **not** add a `CNAME` record at the apex (`@`) — it would conflict
with the MX records. Use the A/AAAA records above instead.

Verify with:

```bash
dig unanue.mx +short
dig www.unanue.mx +short
```

You should see GitHub's IPs for the apex and `nanounanue.github.io` for
`www`.

## License

- Code and templates: MIT License (see `LICENSE`)
- Vendored Tufte CSS: MIT License (see `static/tufte-css/LICENSE`)
- Content (articles, posts): CC BY 4.0
