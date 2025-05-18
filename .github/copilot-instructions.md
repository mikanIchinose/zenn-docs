# Copilot Guidelines for Zenn-docs

## Project Structure
- `articles/` - All published and draft articles
- `images/` - Article images organized by article ID

## Commands
- `ffmeg -i {input} -vf "fps=10,scale=320:-1;flags=lanczos" -c:v gif {output}`
  - Convert video to gif
  - {input}: input video path
  - {output}: output gif path
    - same directory of input
  - gif画像の生成が完了したら対象記事ファイルの適当な場所に挿入する
  - 処理が完了したら動画ファイルをゴミ箱に捨てる

## Commit Message Style Guidelines
- `article: {title}`
  - 記事ファイルを含んでいる場合に用いる

## Markdown Style Guidelines
### 見出し
- `##` でセクション、`###` で小見出し

### 画像

```
![](https://example.com/image.png)
```

How to use local images
```
![](/images/{article-id}/image.png)
```

画像の横幅を指定する場合(例として250pxを指定する)
```
![](https://example.com/image.png =250x)
```

キャプションをつける
```
![](https://example.com/image.png)
*キャプション*
```

### 独自記法

メッセージ
```
:::message
メッセージの内容
:::
```

警告メッセージ
```
:::message alert
警告メッセージの内容
:::
```

アコーディオン
```
:::details タイトル
アコーディオンの内容
:::
```
