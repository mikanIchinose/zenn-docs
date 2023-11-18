---
title: "Android Studioでのビルド時のジャーナルファイルロック絶対回避するマン"
emoji: "🔑"
type: "tech"
topics: ["android", "androidstudio", "gradle"]
published: true
publication_name: "karabiner_inc"
---

Android Studioでの開発中に「さてビルドして動作を確認しよう」と思ったときに
このようなログが出力された経験はないだろうか

```sh
Gradle could not start your build.
> Cannot create service of type BuildSessionActionExecutor using method LauncherServices$ToolingBuildSessionScopeServices.createActionExecutor() as there is a problem with parameter #21 of type FileSystemWatchingInformation.
   > Cannot create service of type BuildLifecycleAwareVirtualFileSystem using method VirtualFileSystemServices$GradleUserHomeServices.createVirtualFileSystem() as there is a problem with parameter #7 of type GlobalCacheLocations.
      > Cannot create service of type GlobalCacheLocations using method GradleUserHomeScopeServices.createGlobalCacheLocations() as there is a problem with parameter #1 of type List<GlobalCache>.
         > Could not create service of type FileAccessTimeJournal using GradleUserHomeScopeServices.createFileAccessTimeJournal().
            > Timeout waiting to lock journal cache (~/.gradle/caches/journal-1). It is currently in use by another Gradle instance.
              Owner PID: 91509
              Our PID: 91540
              Owner Operation: 
              Our operation: 
              Lock file: ~/.gradle/caches/journal-1/journal-1.lock
```

悲しきかな。gradleのインスタンスが既に作られていたためにジャーナルファイルがロックされていたようです。
直前にターミナルで `./gradlew hoge` とタスクを実行していたり、複数のAndroid Studioを開いて別のAndroid Studioでビルドしたあとだったりしたときに直面します。

この場合の汎用的な解決策として僕はJavaのプロセスをキルしています。

```sh
killall -9 java
```

ビルドする直前にこのスクリプトを実行できればいついかなるときであってもジャーナルファイルロックに悩まされることはありませんよね。

### ビルド前にJavaには死んでいただきます

1. Run/Debug Configurations を開く
  ![](/images/9ce0dbb64ccf14/edit-configuration.png)
1. 左上の+ボタンをクリックし、shell scriptを選択する
  ![](/images/9ce0dbb64ccf14/add-shell-script.png)
1. `Script text` を選択し、先程のスクリプト `killall -9 java` を入力し、Nameは「kill java process」とでも入力しておく
  ![](/images/9ce0dbb64ccf14/kill-java-process.png)
1. 左の設定一覧から `Android app/app` を選択し、下のほうにスクロールすると `Before launch` という項目があるので、そこの+をクリックし、 `Run Another Configuration` を選択し、`kill java process` を追加する
  ![](/images/9ce0dbb64ccf14/add-another-configuration.png)
1. `kill java process` を先頭に移動させる
  ![](/images/9ce0dbb64ccf14/before-launch-shell-script.png)

準備はこれで完了だ。
あとはいつもどおりアプリをビルドすればよい、実行前にJavaのプロセスを殺してくれるので(多分)確実にジャーナルファイルロックによるエラーは出なくなるはずだ


### アプリエンジニア募集中

最後にカラビナテクノロジーではAndroid/iOSエンジニアを積極採用中なので、興味がある方は是非連絡いただけるとありがたいです

https://www.wantedly.com/projects/549813
