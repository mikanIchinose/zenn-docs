---
name: zenn-markdown
description: Zenn特有のMarkdown記法リファレンスを提供する。articles/,books/配下のマークダウンを編集する際に参照する。trigger「:::message」「:::details」「メッセージボックス」「アコーディオン」「折りたたみ」「埋め込み」「数式」「KaTeX」「mermaid」「ダイアグラム」「画像キャプション」「画像幅指定」「diff表示」「ファイル名表示」
---

## Zenn独自のMarkdown記法リファレンス

ref: https://zenn.dev/zenn/articles/markdown-guide

### メッセージボックス

```
:::message
通常のメッセージ（補足・注意書き）
:::

:::message alert
警告メッセージ
:::
```

### アコーディオン（折りたたみ）

```
:::details タイトル
折りたたまれる内容
:::
```

ネスト時は外側の`:`を増やす:

```
::::details 外側タイトル
:::message
ネストされたメッセージ
:::
::::
```

### コンテンツ埋め込み

URLを単独行に記述するだけで自動埋め込みされる。

| サービス | 記法例 |
|----------|--------|
| リンクカード | `https://example.com` |
| X(Twitter) | `https://x.com/user/status/123` |
| YouTube | `https://www.youtube.com/watch?v=VideoID` |
| GitHub ファイル | `https://github.com/user/repo/blob/main/file.js#L1-L3` |
| GitHub Gist | Gist URL |
| CodeSandbox | CodeSandbox URL |
| StackBlitz | StackBlitz URL |
| Figma | Figma URL |
| SlideShare | SlideShare URL |
| SpeakerDeck | SpeakerDeck URL |
| Docswell | Docswell URL |
| CodePen | CodePen URL |
| JSFiddle | JSFiddle URL |

### 数式（KaTeX）

ブロック数式:

```
$$
e^{i\theta} = \cos\theta + i\sin\theta
$$
```

インライン数式: `$a \ne 0$`

### ダイアグラム（mermaid.js）

````
```mermaid
graph TB
  A --> B
```
````

制限事項:
- クリックイベント無効
- 2000文字以内
- Chain数10以下

### 画像

幅指定:
```
![altテキスト](URL =250x)
```

キャプション（画像の直下に記述）:
```
![](URL)
*キャプションテキスト*
```

### コードブロックのdiff表示

````
```diff js
@@ @@
- const old = "before";
+ const new = "after";
```
````

### コードブロックのファイル名表示

````
```js:ファイル名.js
const example = true;
```
````
