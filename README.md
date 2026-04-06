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

Drop `.org` files anywhere under `org/`. Standard Org export options apply
(`#+TITLE`, `#+DATE`, `#+AUTHOR`, `#+OPTIONS: toc:nil`, etc.).

### Sidenotes

Write regular Org footnotes; they are rewritten at export into Tufte
sidenotes:

```org
This claim is suspect[fn:1] but let's roll with it.

[fn:1] Explanation of why, shown in the right margin on desktop.
```

The "Footnotes" section that Org would normally append at the bottom is
suppressed — the content is inlined at the reference point instead.

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
