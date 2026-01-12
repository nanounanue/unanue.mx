# Makefile for unanue.mx
# Converts org-mode files to Quarto markdown and renders the site

ORG_DIR := org
CONTENT_DIR := content
ORG_FILES := $(shell find $(ORG_DIR) -name '*.org' 2>/dev/null)
QMD_FILES := $(patsubst $(ORG_DIR)/%.org,$(CONTENT_DIR)/%.qmd,$(ORG_FILES))

.PHONY: all convert render preview clean help

# Default target
all: convert render

# Convert all org files to qmd
convert: $(QMD_FILES)

# Pattern rule for org -> qmd conversion
$(CONTENT_DIR)/%.qmd: $(ORG_DIR)/%.org
	@echo "Converting $< -> $@"
	@mkdir -p $(dir $@)
	pandoc $< -t markdown -o $@ --wrap=none
	@# Fix code blocks for Quarto (pandoc outputs ``` {.python}, Quarto needs ```{python})
	sed -i 's/``` {\.python}/```{python}/g' $@
	sed -i 's/``` {\.r}/```{r}/g' $@
	sed -i 's/``` {\.julia}/```{julia}/g' $@
	sed -i 's/``` {\.bash}/```{bash}/g' $@
	sed -i 's/``` {\.sql}/```{sql}/g' $@

# Render the Quarto site
render: convert
	quarto render

# Preview the site locally
preview: convert
	quarto preview

# Clean generated files
clean:
	rm -rf _site .quarto
	@# Optionally clean converted qmd files (uncomment if desired)
	@# rm -f $(QMD_FILES)

# Show help
help:
	@echo "Available targets:"
	@echo "  all      - Convert org files and render site (default)"
	@echo "  convert  - Convert org files to qmd"
	@echo "  render   - Render the Quarto site"
	@echo "  preview  - Preview site locally (hot reload)"
	@echo "  clean    - Remove generated files"
	@echo "  help     - Show this message"
	@echo ""
	@echo "Workflow:"
	@echo "  1. Write content in org/ directory"
	@echo "  2. Run 'make preview' to see changes"
	@echo "  3. Commit and push to trigger CI deploy"
