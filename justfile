# unanue.mx — build recipes
# Requires: emacs, just (https://github.com/casey/just)

emacs := env_var_or_default("EMACS", "emacs")
out   := "public"

# Default: show available recipes
default:
    @just --list

# Build the site into ./public
build:
    {{emacs}} -Q --batch --load publish.el --funcall org-publish-all

# Force a full rebuild (clears Org's publish timestamp cache)
rebuild: clean build

# Preview locally on http://localhost:8000
serve: build
    cd {{out}} && python3 -m http.server 8000

# Remove build output and Org's publish cache
clean:
    rm -rf {{out}} ~/.org-timestamps .packages

# Print what would be built
status:
    @find org -name '*.org' | sort
