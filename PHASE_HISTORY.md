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
