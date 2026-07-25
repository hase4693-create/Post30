# PHASE9_AUDIT.md — Post30 Version 1.0 リリース品質監査

> 本書は監査文書のみ。Swiftコード・テスト・Xcode設定は変更していない。
> 実行環境は Linux（Xcode/ビルド/実機不可）のため、コードから確認できない挙動はすべて「要実機確認」と明記する。
> 対象は iPhoneアプリ **Post30** のみ（AffiPost AI / AffiPostAIDomain / AffiPostAIPersistence とは無関係で、混同していない）。

## 1. 監査日時
2026-07-18 14:41 JST（監査実施）。

## 2. 対象
- 対象ZIP: 直近納品 `Post30_StatusBadge.zip` 相当（ステータスバッジ実装まで反映済みの完全プロジェクト）。
- 対象コミット: 当ワークスペースはGit管理外のため不明。Git履歴はユーザーのMacリポジトリ側にあり、本監査はソース全ファイルの静的読解に基づく。
- Swiftファイル数: 55（本体）＋テスト15。`@main` は `Post30App` の1つ。

## 3. プロジェクト構成
- App: `Post30App.swift`（ModelContainer構成・`@main`）、`RootView.swift`（空・型定義なし＝旧プレースホルダの残骸）
- Navigation: `RootTabView.swift`（4タブ＋生成の全画面カバー、SwiftData駆動のセットアップ）
- Features: Home / PostList / PostEditor / Generation / Calendar / Settings
- Components: PostRowCard, PostStatusBadge(+Model), CategoryTag, CircularProgressView, ProgressSummaryCard, TodayPostCard, NextPostCard, DailyTipCard, GreetingHeaderView, PostingStreakBadge, PrimaryButton, StepProgressView, CalendarDayCell, CalendarMonthHeader, EmptyStateView
- Models: `Post`(@Model), `MonthPlan`(@Model), Enums(PostStatus/MonthPlanStatus/SocialPlatform/PostCategory)
- Services: `PersistenceStore`, `ClipboardService`
- Theme: `Theme`（余白/角丸/色/グラデ）
- PreviewContent: `SampleData`, `PreviewSupport`（inMemoryコンテナ）
- Utilities: `CalendarDateHelper`, `Date+Extensions`
- 残置の空ファイル: `RootView.swift` / `Features/PostList/PostListPlaceholderView.swift` / `Features/Calendar/CalendarPlaceholderView.swift`（いずれも型定義なし・無害）
- xcodeproj: File System Synchronized Group 方式（objectVersion 77）。Deployment Target iOS 17.0。`PRODUCT_BUNDLE_IDENTIFIER = com.example.Post30`、`MARKETING_VERSION = 1.0`、`CURRENT_PROJECT_VERSION = 1`、`ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`、`CODE_SIGN_STYLE = Automatic`、`DEVELOPMENT_TEAM` 未設定。

## 4. 主要導線の完成状況

| 導線 | 分類 | 根拠（ファイル/型） |
|------|------|------|
| アプリ起動 | 完成 | `Post30App`→`.modelContainer`→`RootTabView.setup()`でStore生成・シード |
| ホーム表示 | 完成 | `HomeView`/`HomeViewModel`（state: loading/content/empty/error） |
| 投稿生成（30日） | 完成（要実機確認） | `PostGenerationView`/`PostGenerationViewModel`→`MockPostGenerationService`→`store.replacePosts` |
| 投稿作成（単発） | 未実装（仕様外） | 単発の新規追加導線は無い。作成は30日一括生成のみ |
| 投稿一覧表示 | 完成 | `PostListView`/`PostListViewModel`（`plan.posts`をライブ参照） |
| 投稿編集 | 完成 | 一覧/カレンダーの`Post`タップ→`PostEditorView`（`store`注入） |
| 投稿予定日の変更 | 完成 | `PostEditorView`のDatePicker→`save()`→`store.save()` |
| 投稿内容の保存 | 完成 | `PostEditorViewModel.save()`（成功時のみdismiss・失敗時alert） |
| 投稿内容のコピー | 一部完成 | Homeの`TodayPostCard`のみ（`HomeViewModel.copy`→`ClipboardService`＋トースト）。一覧/編集にコピー無し |
| 投稿済みへの変更 | 一部完成 | Homeの今日の投稿のみ（`HomeViewModel.markAsPublished`）。一覧/編集/カレンダーからは不可 |
| カレンダー表示 | 完成 | `CalendarView`/`CalendarViewModel`/`CalendarDateHelper` |
| カレンダー→日別一覧 | 完成 | `DailyPostListView`（選択日の`posts(on:)`） |
| 「今月の投稿」 | 完成 | `ProgressSummaryCard.onTap`→`HomeView`の`.sheet`で当月スコープ`PostListView` |
| 投稿削除 | 未実装 | Post単位の削除UI/メソッド無し（`PersistenceStore`はMonthPlan削除と置換のみ） |
| 設定画面への遷移 | 完成（内容は未完） | タブ遷移は成立。中身は`SettingsPlaceholderView`のプレースホルダ |

> 補足: 「投稿済みにする」「コピー」がHomeの今日の投稿限定である点は、30日運用の管理ループとして重要な機能欠落（下記P1）。

## 5. 永続化監査
- ModelContainer生成: `Post30App.init()`で`ModelContainer(for: MonthPlan.self, Post.self)`。失敗時`fatalError`（起動不能を明示する標準対応）。
- 注入: `Post30App.body`で`.modelContainer(container)`。`RootTabView`が`@Environment(\.modelContext)`から`PersistenceStore`生成。
- 作成保存: 生成完了時`applyToPlan`→`store.replacePosts(in:with:)`（旧Post削除→新Post挿入→save）。
- 編集保存: `PostEditorViewModel.save()`→`store.save()`。
- 状態変更保存: `HomeViewModel.markAsPublished`→`store.save()`。
- 削除保存: `PersistenceStore.delete(_ plan:)`（cascade）と`replacePosts`のみ。Post単位削除UIは無し。
- 再起動復元: `PersistenceStore.currentMonthPlan()`（createdAt降順・fetchLimit 1）。要実機確認。
- シード条件: `seedIfNeeded()`（`monthPlanCount()==0`のときのみ）。重複防止済み。全件`scheduled`/`publishedAt=nil`（前フェーズで修正済み）。
- Preview/本番分離: Previewは`PreviewSupport.previewPersistence()`のinMemoryコンテナ、本番は永続コンテナ。分離済み。
- Migrationリスク: 初回リリースのため移行不要。**ただしV1.0出荷後に`Post`/`MonthPlan`のスキーマを変更する場合は`VersionedSchema`+`MigrationPlan`が必要**（現状は未設定）。→ V1.1以降の注意事項（P2）。
- 要実機確認: 実機での「生成→編集→投稿済み→完全終了→再起動」でのデータ保持、`@Model`関係(cascade/inverse)の実挙動。

## 6. エラー処理監査
- `fatalError`: `Post30App`のContainer生成失敗時のみ（妥当。復旧不能の起動失敗）。`precondition`/`preconditionFailure`/force unwrap（`!`）: 本体コードに無し（テストを除く）。
- ユーザー向けエラー表示（実装済み）: 保存失敗のalert＝`HomeView`（markAsPublished）/`PostEditorView`（save）/`PostGenerationView`（replace）。文言統一「データを保存できませんでした。もう一度お試しください。」。
- `try?`によるサイレント処理:
  - `HomeView`の`try? await Task.sleep`（トースト自動非表示のタイミング。無害）。
  - `RootTabView.setup()`の`let plan = try? { seedIfNeeded(); currentMonthPlan() }()`（**起動時のシード/取得失敗を無音でnil化→空状態表示**）。低頻度だが失敗が隠れる。
  - `RootTabView.makeGenerationViewModel()`の`(try? currentMonthPlan()) ?? (try? createEmptyMonthPlan())`（両方失敗でnil→生成結果が保存されない可能性）。
- コピー失敗: `ClipboardService.copy`は失敗を返さない設計（UIPasteboardは実質失敗しない）。V1.0では内部的に許容。
- 削除失敗UI: 削除UI自体が無いため対象外。
- 空配列/nil/不正日付耐性: `MonthPlan`集計はゼロ除算回避済み、`Post.scheduledDateTime`/`scheduledTimeText`はnil/不正で安全にnil、`monthInterval`はoptionalで失敗時nil。良好。
- V1.0で内部ログ許容: 起動時`try?`のフォールバック（頻度極小）、コピー失敗。
- V1.0で表示推奨: 起動時persistence失敗の最小可視化（P2、低頻度のためP0/P1ではない）。

## 7. Empty State 監査

| 状態 | 現状表示 | 判定 |
|------|----------|------|
| 投稿0件（計画空） | `PostListView`→`EmptyStateView`（AI生成CTA） | 良好（ただしタブでは`onRequestGeneration`が動作、シートでは後述） |
| 未投稿0件（フィルタ該当なし） | `noMatchState`「該当する投稿がありません」 | 良好 |
| 投稿済み0件（同上） | 同上 | 良好 |
| 今月の投稿0件（Homeシート） | `isEmpty(scoped)`→`EmptyStateView`のAI CTA。**シート提示時`onRequestGeneration`は既定`{}`＝無反応** | 改善要（P1） |
| 選択日の投稿0件 | `DailyPostListView`「この日の投稿はありません」 | 良好 |
| 検索結果0件 | `.searchable`は絞り込み未接続のため常に全件（0件状態は発生しない） | 検索仕様の整理が前提（P1） |
| カレンダーに対象なし | セルにドット無し＋日別一覧の空状態 | 良好 |

## 8. 削除確認監査
- 現状: **Post単位の削除機能・確認ダイアログ・スワイプ削除は未実装**。`PersistenceStore.delete(_ plan:)`（MonthPlan削除）は存在するがUI導線なし。生成時の置換は「現在の投稿計画を置き換えますか？」（`role:.destructive`）で確認あり。
- リスク: V1.0では「30日分の再生成（置換）」でリセット可能なため、個別削除が無くても主要運用は成立。
- 判定: 個別削除はV1.1候補（P2）。V1.0申請ブロッカーではない。

## 9. 一覧機能監査（検索/フィルター/ソート）
- 実装済み（事実）:
  - ステータスフィルター: `PostListViewModel.Filter`（すべて/未投稿/投稿済み、ステータス基準・日付非依存）。
  - ソート: 予定日昇順固定（`sortedPosts`）。昇降切替・作成日順は無し。
  - 当月スコープ: `monthScope`（「今月の投稿」用）。
  - テキスト検索: `.searchable`のUIは表示されるが`searchText`は**絞り込みに未使用**（非機能）。
  - SNSフィルター: 無し。
- 評価: V1.0はステータスフィルター＋予定日順で主要導線に十分。**非機能の検索バーは要整理（P1）**。SNSフィルター/作成日順/昇降切替/複合条件保存/高度検索はV1.1候補（P2）。

## 10. カレンダー監査
- 月移動: `goToPreviousMonth/goToNextMonth`（`CalendarMonthHeader`のchevron）。実装済み。
- 当月/今日へ戻る: **専用ボタン無し**（遠くへ移動後の復帰導線なし）。改善候補（P1・小）。
- 日付選択: `select(_:)`（別月の補助日タップで表示月も移動）。
- 投稿有無/件数: `CalendarDayCell`（状態はドット形状で区別＋件数、`accessibilityLabel`に件数・状態）。
- 選択日一覧: `DailyPostListView`。
- 過去/未来移動・月境界・年またぎ・うるう年: `CalendarDateHelper`＋`CalendarViewModel`、ユニットテストで検証済み。
- タイムゾーン/日付比較: `Calendar`（`isDate(_:inSameDayAs:)`・`startOfMonth`）で端末TZ基準。良好。
- 空状態: セルのドット無し＋日別空状態。良好。
- Dynamic Type: `CalendarDayCell`は日付番号を`32x32`固定・セル高`52`固定 → 大サイズで窮屈/切れの可能性。**要実機確認**（P1/P2）。
- パフォーマンス: `dayStatus(for:)`/`postCount(on:)`が各セルで`posts(on:)`（全件filter+sort）を呼ぶ→最大42セル×全件。件数が小さい（〜60）ため実害は小。メモ化はP2。

## 11. 設定画面監査
- 現状: `SettingsPlaceholderView` は `ContentUnavailableView("設定", … "この画面は今後のフェーズで実装します。")` の**プレースホルダをユーザーに表示**。
- リスク: App Store審査ガイドライン2.1（未完成/プレースホルダ画面）に抵触し得る。またプライバシーポリシーへのアプリ内導線が無い。
- V1.0最低限（候補）: アプリ名／バージョン（`MARKETING_VERSION`）／ビルド番号（`CURRENT_PROJECT_VERSION`）／プライバシーポリシーURL／サポート連絡先。ライセンス表記・データ初期化は任意（データ初期化は削除UI未実装のため実装は任意）。
- 判定: **プレースホルダのままの設定タブ露出はP0**（最小の実画面へ置換、または当該タブをV1.0で撤去）。外部URL未確定分は「申請準備項目」として分離。

## 12. アクセシビリティ監査（主要導線に限定）
- 良好な点:
  - `PostStatusBadge`: テキスト＋アイコン＋色（色のみ依存せず）、`accessibilityLabel("投稿状態")`/`accessibilityValue(表示名)`。
  - `PostRowCard`: `accessibilityElement(.combine)`＋状態を含むラベル。
  - `CalendarDayCell`: `accessibilityLabel`に日付・今日・件数・状態、`.isButton`/`.isSelected`。ドットは形状で区別。
  - アイコンのみボタン（`CalendarMonthHeader`前月/次月、`PostEditorView`戻る）に`accessibilityLabel`あり。
- 確認/改善点:
  - Dynamic Type最大時: `CalendarDayCell`固定フレーム、`PostStatusBadge`の`lineLimit(1)`、各カードの折返し → **要実機確認**（P1）。
  - `accessibilityIdentifier`: UIテスト未導入のため現状不要（P2）。
  - Reduce Motion: 明示配慮はないが、アニメは軽微（ボタン0.97スケール、トーストのopacity/move）。V1.0で必須ではない（P2、要実機確認）。
  - コントラスト: 淡色バッジ背景（accentSoft/info.opacity(0.15)/success.opacity(0.15)）のダーク時コントラストは**要実機確認**。

## 13. パフォーマンス監査（実害のあるもののみ抽出）
- `DateFormatter()`をメソッド呼び出しごとに生成: `HomeViewModel`(2)、`CalendarViewModel`(3)、`PostListViewModel`(1)、`PostGenerationViewModel`(1)、`CalendarDateHelper`(1)。一覧行/カレンダーセル描画ごとに生成されるが、対象件数が小（一覧数十・カレンダー42）のため**実害は小**。→ キャッシュ化はP2。
- `CalendarViewModel`の日別集計（各セルで全件filter+sort）: 上記同様、件数小のため実害小。メモ化P2。
- MainActor: 保存を伴うVM（Home/Editor/Generation）と`PersistenceStore`は`@MainActor`。`Calendar/PostList`VMはStore非依存で非分離。違反リスクは低いが**要実機確認**（特に生成の`Task`＋progressコールバックのメインアクター往復）。
- Task多重起動: 生成`Task`はキャンセル管理あり、トースト`Task`は単発。無限更新/状態ループの兆候は静的には見当たらない。
- 判定: V1.0で必須修正の「実害あるパフォーマンス問題」は**なし**（すべてBacklog/P2）。

## 14. テスト監査
現状テスト（15ファイル）:
- Model/Enum: `EnumTests`, `MonthPlanTests`, `PostTests`, `SampleDataTests`, `PostStatusBadgeModelTests`
- Service: `MockPostGenerationServiceTests`, `PersistenceStoreTests`, `PostEditorPersistenceIntegrationTests`
- Utility: `CalendarDateHelperTests`, `DateExtensionsTests`
- ViewModel: `HomeViewModelTests`, `PostEditorViewModelTests`, `PostGenerationViewModelTests`, `PostListViewModelTests`, `PostListClassificationTests`, `CalendarViewModelTests`

観点別カバレッジ:
- PostStatus分類/日付非依存/日付変更時の状態維持/投稿済み操作/ステータスバッジ/永続化/シード/カレンダー月境界/今月抽出/空状態(VM)/生成: **カバー済み**。
- 未カバー: 投稿削除（機能未実装）、UIテスト（XCUITestターゲット無し）。
- V1.0前に最低限追加を推奨（テスト数の増加自体は目的にしない）:
  1. 「投稿済みにする」を**編集画面経由**でも実装する場合、その保存経路の統合テスト（P1対応に付随）。
  2. 「今月の投稿」シートの空状態が意図どおり（無反応CTAを出さない）になることの検証（P1対応に付随）。
  - 上記は該当機能を実装する場合のみ。単独での新規テスト量産はしない。

## 15. P0 一覧（申請前に必須）

| ID | 指摘 | 対象 | 現状 | リスク | 推奨対応 | 規模 |
|----|------|------|------|--------|----------|------|
| P0-1 | 設定タブがプレースホルダ表示 | `Features/Settings/SettingsPlaceholderView` | 「今後実装します」をユーザーに表示 | 審査2.1（未完成画面）でリジェクト | 最小の実設定（バージョン/ビルド/プライバシー/サポート）へ置換、またはV1.0で設定タブ撤去 | 中 |
| P0-2 | AppIcon未設定 | `Assets.xcassets/AppIcon`（Swift外） | 1024プレースホルダのみ・実画像なし | アイコン無しは申請不可 | 実アプリアイコンを追加 | 小（資産） |
| P0-3 | Bundle ID/署名がテンプレート | `project.pbxproj`（Swift外） | `com.example.Post30`／`DEVELOPMENT_TEAM`未設定 | 申請不可 | 正式な逆ドメインBundle ID＋署名チーム設定 | 小（Xcode） |
| P0-4 | プライバシーポリシー | App Store Connect＋アプリ内導線 | 未整備 | 申請メタデータ必須／審査要件 | ポリシーURL準備＋設定画面にリンク（P0-1と連動） | 小〜中（申請準備＋実装） |

> P0-2/P0-3/P0-4 は主に「資産・Xcode設定・申請メタデータ」であり、本監査の「Swift非変更」制約の対象外（申請準備タスク）。P0-1はSwift実装を伴う。

## 16. P1 一覧（Version 1.0で強く推奨）

| ID | 指摘 | 対象 | 現状 | リスク | 推奨対応 | 規模 |
|----|------|------|------|--------|----------|------|
| P1-1 | 「投稿済みにする」が今日の投稿(Home)のみ | `HomeViewModel.markAsPublished`／`PostEditorView` | 他日/一覧/編集から投稿済みにできない | 30日運用の管理ループが完遂できない（過去分を消し込めない） | 編集画面（またはカードアクション）に「投稿済みにする」を追加し`store.save()`まで接続 | 中 |
| P1-2 | 非機能の検索バー | `PostListView`の`.searchable`／`PostListViewModel.searchText` | バーは出るが絞り込み無し | ユーザー混乱／非機能UIの審査指摘リスク | V1.0では`.searchable`を撤去、または本文/カテゴリの最小テキスト検索を`filteredPosts`へ接続 | 小〜中 |
| P1-3 | 今月の投稿シートの空状態CTAが無反応 | `HomeView`の`.sheet`→`PostListView(onRequestGeneration:既定{})` | 当月0件時にAI生成ボタンが押せて何も起きない | 操作不能・混乱 | シートでは生成CTAを出さない（noMatchState相当）か、`onRequestGeneration`をシート閉じ＋生成起動へ接続 | 小 |
| P1-4 | カレンダー「今日/当月へ戻る」導線なし | `CalendarView`/`CalendarMonthHeader` | 前後移動のみ | 迷子・復帰しづらい | ヘッダーに「今日」ボタン（`select(now)`＋表示月移動） | 小 |
| P1-5 | 主要導線のDynamic Type/VoiceOver成立確認 | `CalendarDayCell`固定フレーム・各カード | 静的には配慮あり・実挙動未確認 | 大文字サイズで切れ/崩れ、読み上げ順の不備 | 実機確認のうえ、崩れる箇所のみ最小対応 | 小＋要実機確認 |

## 17. P2 一覧（Version 1.1以降 / Backlog）
- 投稿の個別削除UI＋確認ダイアログ（現状は30日再生成で置換のみ）。規模：中。
- 一覧のコピー導線（現状Homeの今日の投稿のみ）。規模：小。
- `DateFormatter`のキャッシュ化・`CalendarViewModel`日別集計のメモ化（perf・実害小）。規模：小〜中。
- 起動時persistence失敗の最小可視化（`RootTabView`の`try?`）。規模：小。
- SNSフィルター/作成日順/昇降切替/複合条件保存/高度検索。規模：中。
- 空の残置ファイル削除（`RootView`/`PostListPlaceholderView`/`CalendarPlaceholderView`）。規模：小。
- Launch screenのブランディング、Reduce Motion配慮。規模：小。
- 将来のスキーマ変更に備えた`VersionedSchema`/`MigrationPlan`整備。規模：中。
- 設定のライセンス表記・データ初期化機能。規模：中。

## 18. Phase 9で実装する推奨順序
1. **申請ブロッカーの資産/設定**（P0-2 AppIcon、P0-3 Bundle ID/署名）※Swift外・先に潰す。
2. **設定画面の最小実装＋プライバシーポリシー導線**（P0-1／P0-4）。
3. **「投稿済みにする」を編集画面へ**（P1-1）＋付随の統合テスト。
4. **検索バーの整理**（P1-2：撤去 or 最小検索）＋**今月シート空状態の修正**（P1-3）。
5. **カレンダー「今日」ボタン**（P1-4）。
6. **Dynamic Type/VoiceOver実機確認**（P1-5）→崩れ箇所のみ最小対応。
7. 主要導線の実機通し確認（生成→編集→投稿済み→再起動保持→今月/カレンダー）→ 申請。
- P2は本フェーズでは着手しない。

## 19. Version 1.0 の完了判定基準
- 主要導線が完遂: 起動→30日生成→一覧/カレンダー確認→編集/予定日変更→保存→**任意の投稿を投稿済みにできる**→完全終了→再起動でデータ保持。
- 申請ブロッカー解消: 実AppIcon、正式Bundle ID＋署名、設定タブがプレースホルダでない、プライバシーポリシーURL（Connect＋アプリ内）。
- 非機能UIが無い（検索バーは機能するか撤去）。
- 空データ/保存失敗で破綻せず、失敗時はユーザーに最低限のフィードバック。
- 主要導線でDynamic Type/VoiceOverが成立（致命的な切れ/読み上げ不能がない）。
- 既存＋（必要時）追加のUnit Testがすべて成功、Debugビルド成功。
- クラッシュ・データ消失・投稿状態の誤変化が無い。

## 20. 要実機確認事項
- 「生成→編集→投稿済み→完全終了→再起動」でのデータ保持と`@Model`関係（cascade/inverse）の実挙動。
- 生成中のプログレス更新・キャンセル・失敗時の復帰、`@MainActor`＋`Task`のメインアクター往復。
- `.sheet`（今月の投稿）の提示・「閉じる」/スワイプでの復帰、多重提示の有無。
- VoiceOver読み上げ順・要素粒度（カード`combine`とバッジ`ignore`の統合結果）。
- Dynamic Type最大での`CalendarDayCell`固定フレーム、`PostStatusBadge`の切れ、各カードの折返し。
- ダークモードでの淡色バッジ/カード背景のコントラスト。
- 起動時のシード失敗（`try?`）が起きた場合の空状態表示とAI生成での復帰。
- クリップボードコピーの実挙動と触覚フィードバック。

---
### 付記（検証）
- 本作業の変更は **`PHASE9_AUDIT.md` の新規作成のみ**。Swiftコード・テスト・Xcodeプロジェクト設定は変更していない。
- Phase 9本体（機能実装）には着手していない。
- 当ワークスペースはGit管理外のため `git diff --stat` / `git status --short` は実行不可。ユーザーのMacリポジトリ上では、本ファイル追加後の想定は「`PHASE9_AUDIT.md` のみ untracked（新規）」で、既存の追跡ファイルに差分は無い。
