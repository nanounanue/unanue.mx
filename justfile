# unanue.mx — org → ox-hugo → Hugo

# Export site.org to content/ and build the site
build: export
    hugo --minify

# Export site.org to content/ via ox-hugo (batch, project-local elpa)
export:
    emacs --batch -l tools/export.el

# Install the project-local Emacs packages (first run, and in CI)
setup:
    emacs --batch -l tools/install-packages.el

# Local preview with drafts
serve: export
    hugo server -D

# Deploy: push main; the deploy workflow publishes to Pages
deploy:
    git push origin main
