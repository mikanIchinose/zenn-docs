ZENN_CLI = deno run --no-lock --reload -A npm:zenn-cli@latest
create-article:
	@./scripts/new-article
create-book:
	@./scripts/new-book

open-article:
	@nvim $(deno run --no-lock --reload -A npm:zenn-cli@latest list:articles | fzf | awk '{print "articles/" $1 ".md"}')

preview:
	@$(ZENN_CLI) preview
