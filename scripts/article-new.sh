#!/usr/bin/env bash
set -euo pipefail

# gum を使った対話的 UI で `zenn new:article` のオプションを決めて実行する。

# 必須: タイトル
title=$(gum input --header 'タイトル' --placeholder '記事のタイトル')

# 必須: 記事タイプ
type=$(gum choose --header '記事タイプ' tech idea)

# 必須: 絵文字（1文字）
emoji=$(gum input --header 'アイキャッチ絵文字（1文字）' --placeholder '✨')

# 任意: スラッグ
slug=''
if gum confirm 'スラッグを指定する？' --default=false; then
  slug=$(gum input --header 'スラッグ (a-z0-9 とハイフン・アンダースコア, 12〜50字)' --placeholder 'my-article-slug')
fi

# 任意: 公開設定
published=false
if gum confirm '公開状態にする？' --default=false; then
  published=true
fi

# 任意: Publication 名
publication=''
if gum confirm 'Publication に紐付ける？' --default=false; then
  publication=$(gum input --header 'Publication 名')
fi

# オプションを組み立てて実行
args=(new:article --type "$type" --published "$published")
[ -n "$title" ] && args+=(--title "$title")
[ -n "$emoji" ] && args+=(--emoji "$emoji")
[ -n "$slug" ] && args+=(--slug "$slug")
[ -n "$publication" ] && args+=(--publication-name "$publication")

echo "実行: zenn ${args[*]}"
zenn "${args[@]}"
