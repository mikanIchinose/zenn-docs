---
title: "MVIフレームワーク試し打ち#1: yumemi-inc/Tart"
emoji: "🪐"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["mvi", "compose", "android"]
published: false
---

## はじめに
yumemi-inc/Tartを使ってAndroidアプリを作ってみました。

- 対象読者
  - MVIフレームワークを試してみたい人
  - yumemi-inc/Tartの使い心地が知りたい人

## MVIとは
MVI (Model-View-Intent) は、アプリケーションの状態管理とUIの更新を効率的に行うためのアーキテクチャパターンです。MVIは、以下の3つの主要なコンポーネントで構成されています。

- **Model**: アプリケーションの状態を表現します。状態は不変であり、変更がある場合は新しい状態を生成します。
- **View**: ユーザーインターフェースを表現します。ViewはModelの状態を監視し、状態が変化したときにUIを更新します。
- **Intent**: ユーザーのアクションやイベントを表現します。IntentはViewから発生し、Modelの状態を変更するためのアクションを定義します。

MVIアーキテクチャは宣言的UIフレームワークを用いて、アプリの実装をしていると自然と実践しているパターンなので、あまりピンとこないかもしれません。

Jetpack Composeでいうと、以下のようなイメージです。

```kotlin
// Model
data class CounterState(val count: Int)

// View
@Composable
fun CounterScreen(
  state: CounterState, 
  onIncrement: () -> Unit, // Intent
  onDecrement: () -> Unit, // Intent
) {
    Column {
        Text(text = "Count: ${state.count}")
        Row {
            Button(onClick = onDecrement) {
                Text("Decrement")
            }
            Spacer(modifier = Modifier.width(8.dp))
            Button(onClick = onIncrement) {
                Text("Increment")
            }
        }
    }
}

// IntentにもとづいてModelを更新する
class CounterViewModel : ViewModel() {
    private val _state = MutableStateFlow(CounterState(count = 0))
    val state: StateFlow<CounterState> = _state.asStateFlow()

    fun onIncrement() {
        _state.update {
            it.copy(count = it.count + 1)
        }
    }

    fun onDecrement() {
        _state.update {
            it.copy(count = it.count - 1)
        }
    }
}

// MainActivity.kt
setContent {
    val state by viewModel.state.collectAsStateWithLifecycle()
    CounterScreen(
        state = viewModel.state.collectAsState().value,
        onIncrement = { viewModel.onIncrement() },
        onDecrement = { viewModel.onDecrement() }
    )
}
```

1画面の中で複数の状態が刻一刻と変化したり、ユーザーインタラクションの数が膨大になったりして、複雑化すると、状態管理が難しくなります。その解決策として、ユーザーインタラクションをクラスとして定義し、状態遷移をステートマシンとして明示的にプログラミングすることが考えられます。^[https://speakerdeck.com/mikanichinose/modeling-uievent]^[https://techblog.lycorp.co.jp/ja/20240624a]
しかし、そのような仕組みを導入すると途端にボイラープレートが増えてしまいます。この問題を解決するために、MVIフレームワークが存在します。

## Tartとは
[@hkusu_](https://x.com/hkusu_) さんを中心として、YUMEMI社で管理されている状態管理フレームワークです。
去年の後半から氏が個人で開発を始め、11月にYUMEMI社のリポジトリに移管されました。
https://x.com/hkusu_/status/1837409104660517367

このフレームワークでは3つの概念とそれらを繫ぐDSLを提供しています。

- **State**: 状態を表現するインターフェースです。
- **Action**: ユーザーのアクションやUIで発生するイベントを表現するインターフェースです。(UIからStoreに通知されるデータ)
- **Event**: 副作用を表現するインターフェースです。(副作用という表現がピンとこないのであれば、StoreからUIに通知されるデータとして捉えると良いでしょう。)
- **Store**: StateとActionを繋ぐステートマシンです。

基本的な使いかたは[README](https://github.com/yumemi-inc/Tart)や[DeepWiki](https://deepwiki.com/yumemi-inc/Tart)を見ていただくとして、さっそく応用例から見ていきます。

## サンプル実装
Tartを使って、以下のようなQiita閲覧アプリを作りました。
![](/images/0a6bccfa1545ad/articles_article.gif =250x)
*記事一覧画面と詳細画面*
![](/images/0a6bccfa1545ad/article_comments.gif =250x)
*コメント画面*

https://github.com/mikanIchinose/android-tart-sample

### 記事一覧画面

![](/images/0a6bccfa1545ad/ArticlesScreen.png)

状態は初期状態、読み込み中、エラー、成功の4つに分けました。
`Store`関数を使ってStoreインスタンスを生成します。第1引数に初期状態を渡します。
第2引数では、状態遷移の定義を行います。

```kotlin
Store(ArticlesState.Idle) {
    // state machineの定義
}
```

初期状態に遷移したらすぐに読み込み中に遷移し、記事一覧を取得します。
`enter` メソッドを使うことで、状態遷移と同時にアクションを実行できます。

```kotlin
state<ArticlesState.Idle> {
    enter {
        nextState(ArticlesState.Loading)
        val articles = articleRepository.getArticles().map {
            val isLike = articleRepository.isItemLiked(it.id)
            it.toArticle(isLike)
        }
        nextState(ArticlesState.Success(articles))
    }
}
```

読み込みが完了したら、`ArticlesState.Success`に遷移します。
`ArticlesState.Success`に遷移したら、ユーザーインタラクションを受け付けるようになります。
`action`メソッドを使うことで、その状態に対するアクションをマッピングできます。
ユーザーインタラクションとしてはいいねの追加、削除と記事のクリックを定義しました。

```kotlin
state<ArticlesState.Success> {
    action<ArticlesUiAction.Click> {
        event(ArticlesEvent.NavigateToDetail(action.itemId))
    }
    action<ArticlesUiAction.AddLike> {
        articleRepository.addLike(action.itemId)
        val newArticles = state.articles.map {
            if (it.id == action.itemId) {
                it.copy(
                    likesCount = it.likesCount + 1,
                    isLike = true,
                )
            } else {
                it
            }
        }
        nextState(state.copy(newArticles))
    }
    action<ArticlesUiAction.RemoveLike> {
        articleRepository.removeLike(action.itemId)
        val newArticles = state.articles.map {
            if (it.id == action.itemId) {
                it.copy(
                    likesCount = it.likesCount - 1,
                    isLike = false,
                )
            } else {
                it
            }
        }
        nextState(state.copy(newArticles))
    }
}
```

記事をクリックすると詳細画面に遷移させたいので、`event`メソッドを使って、UIにイベントを通知します。
UIではイベントを監視しており、特定のイベントに対して対応する処理を実行するようにできます。

```kotlin
val viewModel: ArticlesViewModel = hiltViewModel()
val viewStore = rememberViewStore(viewModel.store)
viewStore.handle<ArticlesEvent.NavigateToDetail> {
    navController.navigate(ArticleRoute(it.itemId))
}
```

イベントのFlowを監視して、特定のイベントに対して処理を実行することもできます。

```kotlin
LaunchedEffect(Unit) {
    viewStore.eventFlow.collect { event ->
        when (event) {
            is ArticlesEvent.NavigateToDetail -> TODO()
        }
    }
}
```

API通信中にエラーが発生したりした場合は、`ArticlesState.Error`に遷移します。
try-catchを使ってエラーハンドリングを書くこともできますが、`error`メソッドを使うことで、宣言的にエラーハンドリングを書くことができます。

```kotlin
state<ArticlesState> {
    error<Exception> {
        nextState(ArticlesState.Error(error.message ?: "Unknown error"))
    }
}
```

上記のように書くと、任意の状態のときにExceptionが発生した場合に、`ArticlesState.Error`に遷移します。

このようにして作成したStoreをViewModelに持たせて、UIからはViewModelを通してStoreにアクセスします。

```kotlin
@HiltViewModel
class ArticlesViewModel @Inject constructor(
    articlesStateContainer: ArticlesStoreContainer,
) : ViewModel() {
    val store = articlesStateContainer.build()
    override fun onCleared() {
        store.dispose()
    }
}
```

### 記事詳細画面
詳細画面は少し複雑で、メインとなる詳細画面とボトムシートを使って表示するコメント画面の2つの画面を持っています。
詳細画面とコメント画面はそれぞれ関心事が違うので、別々のStoreを作ることでStoreの肥大化を防ぎます。

```kotlin
class ArticleStoreContainer @Inject constructor(
    private val articleRepository: ArticleRepository
) {
    fun build(itemId: String): Store<ArticleState, ArticleAction, ArticleEvent> =
        Store(ArticleState.Idle) {
            state<ArticleState.Idle> {
                enter {
                    nextState(ArticleState.Loading)
                    val articleDetail =
                        articleRepository.getArticle(itemId)?.toArticleDetail()
                    val isLiked = articleRepository.isItemLiked(itemId)
                    val isStocked = articleRepository.isItemStock(itemId)
                    if (articleDetail != null) {
                        nextState(
                            ArticleState.Success(
                                detail = articleDetail,
                                isLiked = isLiked,
                                isStocked = isStocked,
                            )
                        )
                    } else {
                        nextState(ArticleState.Error("Article not found"))
                    }
                }
            }
            state<ArticleState.Success> {
                action<ArticleUiAction.ClickBack> {
                    event(ArticleEvent.NavigateBack)
                }
            }
            state<ArticleState> {
                error<Exception> {
                    nextState(ArticleState.Error(error.message ?: "Unknown error"))
                }
            }
        }
}

class CommentsStoreContainer @Inject constructor(
    private val articleRepository: ArticleRepository
) {
    fun build(itemId: String): Store<CommentsState, CommentsAction, CommentsEvent> =
        Store(CommentsState.Idle) {
            state<CommentsState.Idle> {
                enter {
                    nextState(CommentsState.Loading)
                    val comments = articleRepository.getComments(itemId)
                        .map { it.toState() }
                        .reversed()
                    nextState(CommentsState.Success(comments))
                }
            }
            state<CommentsState> {
                error<Exception> {
                    nextState(CommentsState.Error(error.message ?: "Unknown error"))
                }
            }
        }
}

@HiltViewModel
class ArticleViewModel @Inject constructor(
    articleStoreContainer: ArticleStoreContainer,
    commentsScoreContainer: CommentsStoreContainer,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val itemId: String = savedStateHandle["itemId"]!!
    val articleStore = articleStoreContainer.build(itemId)
    val commentsScore = commentsScoreContainer.build(itemId)
    override fun onCleared() {
        articleStore.dispose()
        commentsScore.dispose()
    }
}
```

このように関心事の単位でStoreを作ることで、画面の作りがよりComposableになります。

## Storeのテスト

あるActionが実行されたあとに、期待されるStateに遷移するかを確認したり、期待されるEventが発行されるかを確認することでStoreのテストを行います。
テストコードを書くために、特別に学習することは無く、JVMのテストとcoroutineのテストの書き方が分かればよいです。

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class ArticlesStoreTest {
    val testDispatcher = UnconfinedTestDispatcher()
    lateinit var repository: FakeArticleRepository
    lateinit var store: Store<ArticlesState, ArticlesAction, ArticlesEvent>

    @Test
    fun articlesStore_loadArticles() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository()
        store = ArticlesStoreContainer(repository, Dispatchers.Unconfined).build()
        val expected = ArticlesState.Success(
            articles = listOf(
                Article(
                    id = "1",
                    author = Author(
                        photoUrl = "",
                        name = "山田太郎",
                        group = "fuga株式会社",
                    ),
                    title = "title",
                    likesCount = 1,
                    tags = emptyList(),
                    createdAt = "2025/01/01",
                    updatedAt = "2025/01/01",
                    isLike = false,
                ),
                Article(
                    id = "2",
                    author = Author(
                        photoUrl = "",
                        name = "山田太郎",
                        group = "fuga株式会社",
                    ),
                    title = "title",
                    likesCount = 1,
                    tags = emptyList(),
                    createdAt = "2025/01/01",
                    updatedAt = "2025/01/01",
                    isLike = false,
                ),
                Article(
                    id = "3",
                    author = Author(
                        photoUrl = "",
                        name = "山田太郎",
                        group = "fuga株式会社",
                    ),
                    title = "title",
                    likesCount = 1,
                    tags = emptyList(),
                    createdAt = "2025/01/01",
                    updatedAt = "2025/01/01",
                    isLike = false,
                ),
            )
        )
        // Act
        store.state // trigger initial state
        // Assert
        assertEquals(expected, store.currentState)
    }

    @Test
    fun articlesStore_clickArticle() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository()
        store = ArticlesStoreContainer(repository, Dispatchers.Unconfined).build()
        var capturedEvent: ArticlesEvent? = null
        store.collectEvent {
            capturedEvent = it
        }
        // Act
        store.dispatch(ArticlesUiAction.Click("1"))
        // Assert
        assertEquals(ArticlesEvent.NavigateToDetail("1"), capturedEvent)
    }

    @Test
    fun articlesStore_addLike() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository()
        store = ArticlesStoreContainer(repository, Dispatchers.Unconfined).build()
        // Act
        store.dispatch(ArticlesUiAction.AddLike("1"))
        // Assert
        assertEquals(
            2,
            (store.currentState as ArticlesState.Success).articles.first { it.id == "1" }.likesCount
        )
    }

    @Test
    fun articlesStore_removeLike() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository()
        store = ArticlesStoreContainer(repository, Dispatchers.Unconfined).build()
        // Act
        store.dispatch(ArticlesUiAction.RemoveLike("1"))
        // Assert
        assertEquals(
            0,
            (store.currentState as ArticlesState.Success).articles.first { it.id == "1" }.likesCount
        )
    }

    @Test
    fun articlesStore_loadError() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository(false)
        store = ArticlesStoreContainer(repository, Dispatchers.Unconfined).build()
        val expected = ArticlesState.Error("Failed to get articles")
        // Act
        store.state
        // Assert
        assertEquals(expected, store.currentState)
    }
}
```

## AIエージェントとの相性
コードでは単にステートマシンを組み立てているだけなので、AIエージェントとの相性が良いのではないかと思い、試してみました。

0から作らせるとAPIを理解しないままに作り始めそうだったので、例を1つ提示して作らせる one-shot promptingで試してみました。

- model: claude-3.7 sonnet
    - 作業量が多かったので、長時間実行してくれるclaudeを選択しました。
- task file
    ```markdown:docs/tasks/0001-create-articlestorecontainer.md
    ---
    input:
      - stateMachineImage: 作ろうとしているステートマシンのイメージ
    ---

    ## TODO
    - [ ] `app/src/main/java/io/github/mikan/tart/article/ArticleStoreContainer.kt` の実装を完成させる
    - [ ] `ArticleStoreContainer` のテストを作成する

    ## Reference
    - TDDで設計を進める
    - `app/src/main/java/io/github/mikan/tart/articles/ArticlesStoreContainer.kt` をステートマシンの実装の参考にする
    - State/Action/Event は `app/src/main/java/io/github/mikan/tart/article/ArticleState.kt` に定義しているものを使う
    ```
- prompt
    ![](/images/0a6bccfa1545ad/prompt.png)

:::details Output
タスクを実行するには、まずプロジェクトの構造をより詳しく把握し、必要なファイルを確認する必要があります。まずは `ArticleState.kt` と参考にする `ArticlesStoreContainer.kt` の内容を確認しましょう。 

次に、`ArticleStoreContainer.kt` の現在の状態を確認し、必要に応じて作成します。 

次に、`ArticleRepository` のインターフェースを確認して、利用可能なメソッドを把握しましょう。 

これで必要な情報が揃いました。`ArticleRepository`インターフェースについても情報が得られました。次に、`ArticleStoreContainer`の実装を完成させましょう。

ステートマシンの図から理解できるように、私たちは以下のステートを持つ実装が必要です：
1. Idle → Loading → Success または Error
2. Success状態から、ClickBackイベントがあれば、NavigateBackイベントを発行する
3. Any stateからExceptionが発生した場合、Errorステートに遷移する

では、ArticleStoreContainer.ktを実装しましょう： 
````

````


Made changes.



これでArticleStoreContainer.ktの実装が完了しました。次に、TDDアプローチに従って、このコンテナのテストを作成する必要があります。テスト用のファイルを作成しましょう。

まず、テストディレクトリとテストファイルの構造を確認します： 



既存のテストファイル構造を確認して、ArticlesStoreTest.ktを参考にしてテストを作成します： 



これで既存のテストの構造が分かりました。これを参考にして、`ArticleStoreTest.kt`を作成しましょう。 

Made changes.





お疲れ様です！以下が実装を完了しました：

1. ArticleStoreContainer.kt の実装を完成させました：
   - `Idle` → `Loading` → `Success` または `Error` の状態遷移を実装
   - `articleRepository` を使用して記事の詳細を取得し、「いいね」と「ストック」の状態を設定
   - `ClickBack` アクションに対して `NavigateBack` イベントを発行
   - 例外処理のためのグローバルエラーハンドラー

2. `ArticleStoreTest.kt` のテストを作成しました：
   - 記事の読み込み成功をテスト
   - 戻るボタンのクリックイベント処理をテスト
   - エラー処理のテスト
   - 存在しない記事IDの場合のテスト

これで、ステートマシンの図に示されているフローが実装されています：
- `Idle` 状態からスタート
- `Loading` 状態への遷移
- ロード成功時は `Success` 状態、失敗時は `Error` 状態
- `Success` 状態から `ClickBack` イベントでユーザーを前の画面に戻す
- どの状態からでも例外が発生した場合に `Error` 状態に遷移

TDDの原則に従い、テストコードも実装しました。この実装により、`ArticleStoreContainer` が正しく動作することを確認できます。
:::

完成したコード

おおよそ期待した通りのコードが生成されました。
```kotlin
class ArticleStoreContainer @Inject constructor(
    private val articleRepository: ArticleRepository,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    fun build(itemId: String): Store<ArticleState, ArticleAction, ArticleEvent> =
        Store(ArticleState.Idle) {
            coroutineContext(dispatcher)

            state<ArticleState.Idle> {
                enter {
                    nextState(ArticleState.Loading)
                }
            }

            state<ArticleState.Loading> {
                enter {
                    val article = articleRepository.getArticle(itemId)
                    if (article != null) {
                        val isLiked = articleRepository.isItemLiked(itemId)
                        val isStocked = articleRepository.isItemStock(itemId)
                        nextState(
                            ArticleState.Success(
                                detail = article.toArticleDetail(),
                                isLiked = isLiked,
                                isStocked = isStocked
                            )
                        )
                    } else {
                        nextState(ArticleState.Error("Article not found"))
                    }
                }
            }

            state<ArticleState.Success> {
                action<ArticleUiAction.ClickBack> {
                    event(ArticleEvent.NavigateBack)
                }
            }

            // グローバルエラーハンドラー
            state<ArticleState> {
                error<Exception> {
                    nextState(ArticleState.Error(error.message ?: "Unknown error"))
                }
            }
        }
}
```

テストコードの方は弱干期待してない作りがあったので微調整をしています。
```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class ArticleStoreTest {
    private val testDispatcher = UnconfinedTestDispatcher()
    private lateinit var repository: FakeArticleRepository
    private lateinit var store: Store<ArticleState, ArticleAction, ArticleEvent>
    private val testItemId = "1"

    @Test
    fun articleStore_loadArticle() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository()
        store = ArticleStoreContainer(repository, Dispatchers.Unconfined).build(testItemId)

        // Act
        store.state // トリガー初期状態

        // Assert
        val currentState = store.currentState
        val expectedState = ArticleState.Success(
            detail = ArticleDetail(
                id = "1",
                title = "title",
                body = "body",
                likesCount = 1,
                commentsCount = 0,
                stocksCount = 0,
                author = Author(
                    photoUrl = "",
                    name = "山田太郎",
                    group = "fuga株式会社"
                )
            ),
            isLiked = false,
            isStocked = false
        )
        assertEquals(expectedState, currentState)
    }

    @Test
    fun articleStore_clickBack() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository()
        store = ArticleStoreContainer(repository, Dispatchers.Unconfined).build(testItemId)
        var capturedEvent: ArticleEvent? = null
        store.collectEvent {
            capturedEvent = it
        }

        // 初期状態に遷移させる
        store.state

        // Act
        store.dispatch(ArticleUiAction.ClickBack)

        // Assert
        assertEquals(ArticleEvent.NavigateBack, capturedEvent)
    }

    @Test
    fun articleStore_loadError() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository(shouldSucceed = false)
        store = ArticleStoreContainer(repository, Dispatchers.Unconfined).build(testItemId)

        // Act
        store.state // トリガー初期状態

        // Assert
        val currentState = store.currentState
        assertIs<ArticleState.Error>(currentState)
        assertTrue(currentState.message.isNotEmpty())
    }

    @Test
    fun articleStore_articleNotFound() = runTest(testDispatcher) {
        // Arrange
        repository = FakeArticleRepository()
        store = ArticleStoreContainer(repository, Dispatchers.Unconfined).build("non-existent-id")

        // Act
        store.state // トリガー初期状態

        // Assert
        val currentState = store.currentState
        assertIs<ArticleState.Error>(currentState)
        assertEquals("Article not found", currentState.message)
    }
}
```

## 利点

### 特定の状態に対するアクションを紐付けられるDSLが優秀
TartのDSLは、状態毎にアクションや副作用を宣言的に紐付けられるため、状態遷移の設計やテストが直感的に行えました。
また、状態毎にロジックを分離できるので、複雑な画面でも可読性・保守性が高まると思います。

### composableなStoreの設計が可能
関心事別にStoreを分割できるため、画面ごと・機能ごとに小さくComposableな設計ができます。
これにより、コードの肥大化や認知負荷の上昇は押さえられるかなと思います。

## 欠点

### enterを介した状態遷移をテストしようとすると実装の詳細を知っておく必要がある
初期状態から次の状態への遷移が`enter`メソッドを介して行われている場合、そのままテストを書いてしまうと初期状態から変化せずにテストが失敗します。
これはstateがlazyで設定されていて、初期化されていないためです。

https://github.com/yumemi-inc/Tart/blob/ada6410520acbdca1a8c35dd7d9d55102e8ade43/tart-core/src/commonMain/kotlin/io/yumemi/tart/core/StoreImpl.kt#L35-L38

そのため、`store.state`を呼び出して初期化を促す必要があります。
こうした実装の詳細を知っておく必要があるため、テストが少し面倒になります。

### 学習コストと学習機会の喪失
Tartに限った話ではないですが、独自DSLや状態遷移の考え方に慣れるまで学習コストがかかります。また、フレームワークに依存することで、状態管理の基礎や一般的な設計パターンを学ぶ機会が減るかなと思いました。
