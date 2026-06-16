#!/usr/bin/env bash
set -euo pipefail

# articles 一覧 (slug<TAB>title) を fzf で選択し、対応する記事ファイルを開く。
selected=$(zenn list:articles --format tsv | fzf --delimiter='\t' --with-nth=2 --prompt='article> ')

# 何も選択されなかった場合（Esc など）は終了。
[ -z "${selected:-}" ] && exit 0

slug=$(printf '%s' "$selected" | cut -f1)
"${EDITOR:-vim}" "articles/${slug}.md"
