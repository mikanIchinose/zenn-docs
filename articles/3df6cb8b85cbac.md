---
title: "アプリのリリースフローをスクリプト化する"
emoji: "🎉"
type: "tech"
topics: ["android", "firebase"]
published: true
published_at: 2022-12-19 07:00
publication_name: "karabiner_inc"
---

:::message
この記事は[Android advent calendar 2022 その2](https://qiita.com/advent-calendar/2022/android)の19日目の記事です。
:::

AndroidアプリをFirebase App Distribution等を使って配布する場合
`Variantを合わせる → APKの生成 → Firebase App Distributionにアップロード→配布`
というフローを毎回実施しないといけないので数をこなしてくると面倒になってきます。。
そこでシェルスクリプトを使ってこの作業を `スクリプトの実行 → 配布` だけで完結するようにしてみます。

## ツール導入

以下のCLIをインストールします

- [firebase-tools](https://github.com/firebase/firebase-tools): firebaseを操作するためのCLI
- [firebase-multi](https://github.com/atlanteh/firebase-multi): firebase-toolsを複数アカウントで利用するときに必要

```bash
npm i -g firebase-tools
npm i -g firebase-multi
firebase login:add # Firebaseのアカウントを紐付けます
firebase login:ci # トークンが発行されるのでメモします
firebase-multi set hoge <FIREBASE_TOKEN> # メモしたトークンを貼り付けます
```

## シェル環境の設定

シェルからgradleタスクを実行するためにはJDKとJAVA_HOMEを設定する必要があります。
ここではasdfを使った方法を紹介しますが、各々好きなやり方で設定してください。

```bash
asdf plugin-add java
asdf install java adoptopenjdk-11.0.17+8 # 執筆時点での最新のJava11
asdf global java adoptopenjdk-11.0.17+8
. ~/.asdf/plugins/java/set-java-home.bash
```

`jarsigner`というツールがアプリの署名に必要なのですがJDKのインストールと同時に設定されます。

```bash
$ which jarsigner
/Users/your-name/.asdf/shims/jarsigner
```

## スクリプト作成

単純なスクリプトを結構な数作らないといけないのでMakefileとしてまとめます。
{}で囲んでいる箇所はご自身のものに置き換えてください

```make:Makefile
.PHONY: tasks # タスク一覧表示
tasks:
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1 -> \2/' | expand -t20

.PHONY: clean # buildディレクトリの削除
clean:
	@./gradlew clean

# apk生成
.PHONY: assemble # apk生成: すべてのvariant
assemble:
	@./gradlew assemble

.PHONY: assembleDebug # apk生成: デバッグ版
assembleDebug:
	@./gradlew assembleDebug

.PHONY: assembleRelease # apk生成: リリース版
assembleRelease:
	@./gradlew assembleRelease

.PHONY: generateSignedBundle # 署名付きAABの生成
generateSignedBundle: clean
	@./gradlew bundleRelease
	jarsigner \
		-sigalg SHA256withRSA \
		-digestalg SHA-256 \
		-keystore {path/to/release.keystore} \
		-storepass {storepass} \
		-keypass   {keypass} \
		{path/to/release.aab} \
		{alias}

# APKをfirebase app distributionにアップロードする(配信まではしない)
.PHONY: upload # APKをfirebase app distributionにアップロード
upload:
	@firebase-multi use hoge firebase appdistribution:distribute \
		--app {app_id} \
		{path/to/debug.apk}

# firebase app distributionにアップロードするために必要なタスクをまとめて実行する
.PHONY: release # リリースタスク
release: clean assembleDebug upload
```

### {app_id}の探し方

`Firebase>プロジェクトの設定>マイアプリ`を見ると`アプリID`という項目があるのでそちらをコピペします

![](/images/3df6cb8b85cbac/firebase-app-id.png)

## Appendix: gumを使ってローディングを表示する

[gum](https://github.com/charmbracelet/gum)というCLIを使えば簡単にローディングアニメーションを表示できるのでオススメ

```make
release: clean assembleDebug
	@gum spin --spinner=dot --title "Uploading Firebase" -- make upload
```
