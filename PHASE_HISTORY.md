# PHASE_HISTORY.md — Post30 開発Phase履歴

Post30の開発をPhaseごとに記録するドキュメント。各Phaseがmainへマージされた時点で、そのPhaseの節を追記していく運用とする。

---

## Phase 1〜11(完了済み・概要のみ)

Phase 1〜11は本ドキュメントの新設(Phase 12)より前に実施され、2026-07-26に `integrate/phase11` ブランチ経由でPull Request #1として `main` へマージ済み。

各Phaseの詳細な実装内容・変更ファイル・コミットハッシュ等は、Git履歴(`git log`)および過去の会話記録に基づく情報のみを正とし、本ドキュメントでは推測に基づく詳細を記載しない。判明している範囲の概要は以下の通り。

- Phase 1: 要件定義
- Phase 2〜6: 基本画面構成・SwiftDataモデル設計・初期実装
- Phase 7: SwiftData永続化実装
- Phase 8: カレンダー機能実装
- Phase 9: 設定画面・ステータスバッジ・品質監査(`PHASE9_AUDIT.md`参照)
- Phase 10: リリース設定・プライバシーポリシーURL整備
- Phase 11: プライバシーポリシー最終更新・CraftFlowブランド情報反映

> 上記Phase区分・名称は、リポジトリ内に残るzip/ディレクトリ名(`Post30_Phase7_SwiftData` 等)から判別できる範囲の概要であり、各Phase内の詳細な実装内容・完了日・テスト件数等は本ドキュメントでは未整備。必要であれば別途Git履歴を遡って確認する。

---

## Phase 12: Release Readiness

- **実装日**: 2026-07-27
- **目的**: App Store申請に向けたコード整理・リリース品質確認・公開設定確認・ドキュメント整備
- **実装内容**:
  1. コード整理: 未使用プレースホルダー4ファイルの削除、到達不能コード(`requestGenerate()`/`.generateルート`/重複`GeneratePlaceholderView`)の削除
  2. リリース品質確認: Home/PostList/Calendar/Settingsの主要導線・Empty State・保存失敗時のエラー表示・外部リンク・Dynamic Type・VoiceOver/Accessibilityを、自動テスト・シミュレータ・要ユーザー確認の3区分で調査
  3. App Store公開設定の確認: AppIcon/LaunchScreen/Version/Build Number/Bundle ID/Development Team/ITSAppUsesNonExemptEncryptionの現状調査
  4. ドキュメント整備: 本ファイル(`PHASE_HISTORY.md`)と`RELEASE_CHECKLIST.md`を新設
- **主な変更点**:
  - 削除: `Post30/App/RootView.swift`、`Post30/Features/PostList/PostListPlaceholderView.swift`、`Post30/Features/Calendar/CalendarPlaceholderView.swift`、`Post30/Features/Settings/SettingsPlaceholderView.swift`
  - 変更: `Post30/Features/Home/HomeView.swift`、`Post30/Features/Home/HomeViewModel.swift`、`Post30/Features/PostList/PostListView.swift`、`Post30/Features/PostList/PostListViewModel.swift`(到達不能な`.generate`ルート関連コードの除去)
  - 新規: `PHASE_HISTORY.md`、`RELEASE_CHECKLIST.md`
- **Build結果**: BUILD SUCCEEDED(コード整理後、iPhone 17 Simulator / Debug構成)
- **Test結果**: 147件成功 / 失敗0 / スキップ0(xcresultで検証)
- **コミットハッシュ**: (未コミット・承認待ち)
- **Pull Request**: (未作成)
- **Mergeコミット**: (未マージ)
- **残課題**:
  - AppIcon実画像・Development Team設定は申請ブロッカー。ユーザー側の作業待ち(詳細は`RELEASE_CHECKLIST.md`参照)
  - LaunchScreenは自動生成の空白画面のままだが、**申請ブロッカーではない**(AppIcon/Development Teamとは異なりV1.0申請でも許容可能)。ブランド化はV1.1以降の任意対応
  - 保存失敗パスの自動テスト未整備
  - PostList/Calendar/Settingsタブ、外部リンクタップ、Empty State、Dynamic Type崩れ、VoiceOverの実機確認が未実施(Phase 13以降で対応予定)

---

## Phase 13: App Store Readiness / TestFlight準備

- **実装日**: 2026-07-27〜2026-07-28
- **目的**: App Store申請の直前ブロッカー(輸出コンプライアンス設定・Development Team・AppIcon)を解消し、Archiveが実際に成功する状態まで持っていく。安全のため13-A〜13-Dの段階に分けて実施した
- **実装内容**:
  1. (13-A) `ITSAppUsesNonExemptEncryption = NO` をPost30(App)ターゲットのDebug/Release 2箇所へ追加。通信・暗号化API(`URLSession`/`URLRequest`/WebView/独自暗号化等)の未使用を再確認したうえで設定
  2. (13-B) Development Teamの設定はユーザーがXcodeのSigning & Capabilities画面でPost30(アプリターゲット)のみに設定。Claude Code側では`project.pbxproj`を直接編集せず、設定後にXcodeが自動追加した無関係な差分(`LastUpgradeCheck`更新、`CLANG_WARN_*`等の推奨ビルド設定、セクション並び順変更)をHEAD基準で復元し、`DEVELOPMENT_TEAM = H7229AXFCS`と`ITSAppUsesNonExemptEncryption = NO`の必要な差分のみを残した
  3. (13-C) Release構成でのSimulator Build(`-validate-for-store`込み)、全テスト実行、`generic/platform=iOS`向けArchiveを検証。Archiveは初回失敗(Development Team未設定によるエラーを実際に確認済み)から、設定後は再現性をもって成功することを2回の実行で確認
  4. (13-D) AppIcon画像(1024×1024・PNG・アルファチャンネルなし・sRGB)を事前検証のうえ`AppIcon.appiconset/AppIcon-1024.png`として配置し、`Contents.json`へ`filename`を追加。Asset Catalogコンパイル・Release Build・全テスト・Archiveを再検証
- **主な変更点**:
  - 変更: `Post30.xcodeproj/project.pbxproj`(Post30ターゲットDebug/Releaseに`DEVELOPMENT_TEAM = H7229AXFCS;`・`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;`を追加。Post30Testsターゲットは対象外)
  - 変更: `Post30/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`(`filename: "AppIcon-1024.png"`を追加)
  - 新規: `Post30/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- **Build結果**: BUILD SUCCEEDED(Release構成、iPhone 17 Simulator、`-validate-for-store`検証込み。AppIcon追加後も再検証し成功)
- **Test結果**: 147件成功 / 失敗0 / スキップ0(xcresultで複数回検証、AppIcon追加後も変化なし)
- **Archive結果**: `generic/platform=iOS` / Release構成で `ARCHIVE SUCCEEDED`(Development Team設定後・AppIcon追加後の両時点で成功を確認)
  - Archive内`Info.plist`(`ApplicationProperties`): `CFBundleIdentifier = com.hasegawa.post30`、`CFBundleShortVersionString = 1.0`、`CFBundleVersion = 1`、`SigningIdentity = Apple Development: hase4693@gmail.com (R47WHKY8PV)`、`Team = H7229AXFCS`
  - アプリバンドル内`Info.plist`の`ITSAppUsesNonExemptEncryption`が`false`であることを`PlistBuddy`で確認
  - `assetutil`によりArchive内`Assets.car`へAppIconが実際にコンパイルされていることを確認(`PixelWidth/PixelHeight: 1024`、`Opaque: true`、`RenditionName: AppIcon-1024.png`)
  - AppIcon関連のwarning/errorはビルド・Archiveいずれのログにも出力されず
- **コミットハッシュ**: (未コミット・承認待ち)
- **Pull Request**: (未作成)
- **Mergeコミット**: (未マージ)
- **残課題**:
  - TestFlightへの実アップロード・App Store Connect側のメタデータ入力・審査提出は未実施(Claude Codeから実行不可な領域を含む)
  - 保存失敗パスの自動テスト未整備
  - PostList/Calendar/Settingsタブ、外部リンクタップ、Empty State、Dynamic Type崩れ、VoiceOverの実機確認が未実施
  - LaunchScreenは自動生成の空白画面のまま(申請ブロッカーではないため任意対応)
  - Post30Tests(テストターゲット)へのDevelopment Team設定は不要と判断(Archiveログにテストターゲット起因の署名エラーなし)
