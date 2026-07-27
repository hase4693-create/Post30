# RELEASE_CHECKLIST.md — Post30 App Store公開チェックリスト

Post30をApp Storeへ申請する前に確認すべき項目を整理したチェックリスト。Phase 12(2026-07-27)時点の調査結果を反映している。完了状況は今後のPhaseで随時更新する。

`APP_STORE_PRIVACY_DRAFT.md`との役割分担: 本ファイルは申請前作業全体のgo/no-goチェックリスト。`privacy-policy/APP_STORE_PRIVACY_DRAFT.md`はApp Privacy回答(データ収集有無)の判断根拠専用の文書として維持する。

---

## 1. コード品質

- [x] Build succeeded(Debug構成、iPhone 17 Simulator)
- [x] 全テストpass(147件 / 失敗0 / スキップ0)
- [x] 未使用プレースホルダーファイルの除去(Phase 12で対応済み)
- [x] 到達不能コード(Dead Code)の除去(Phase 12で対応済み: `.generate`ルート関連)
- [x] TODO/FIXME・print残骸なし(Phase 12調査で確認)
- [ ] 保存失敗パスの自動テスト整備(未着手・Phase 13候補)

## 2. 主要導線・リリース品質

- [x] Home/PostList/Calendarの主要ロジック(自動テストで確認済み)
- [ ] Home/PostList/Calendar/Settingsの実機/シミュレータでの目視動作確認(未実施・要ユーザー確認)
- [ ] Empty State表示の実機確認(未実施)
- [ ] 保存失敗時のアラート表示の実機確認(自動テストなし・未実施)
- [ ] 設定画面の外部リンク(お問い合わせ/プライバシーポリシー)タップ動作確認(未実施)
- [ ] Dynamic Type最大時の`CalendarDayCell`/`PostStatusBadge`崩れ確認(未実施、固定frame残存を確認済み)
- [ ] VoiceOver実機確認・Accessibility Inspector監査(未実施、CLIから実行不可)

## 3. App Store公開設定

**申請ブロッカー(必須・未解消のまま申請不可)**

- [ ] **AppIcon実画像**: 未完了 — `AppIcon.appiconset/Contents.json`は1024×1024スロットの定義のみで実画像ファイルが存在しない。ユーザーによるアイコン画像の用意が必要
- [ ] **Development Team(署名)**: 未完了 — `DEVELOPMENT_TEAM`が4構成すべて未設定。Apple Developer Program Team IDの提供、またはXcodeでのApple IDサインインと設定が必要

**完了済み**

- [x] **Version(MARKETING_VERSION)**: 完了 — `1.0`(初回リリースとして妥当)
- [x] **Build Number(CURRENT_PROJECT_VERSION)**: 完了 — `1`(初回リリースとして妥当)
- [x] **Bundle ID**: 完了 — App: `com.hasegawa.post30` / Tests: `com.hasegawa.post30.tests`(CLAUDE.md記載の正式値と一致)

**ブロッカーではない(V1.0では許容可能・任意対応)**

- [ ] **LaunchScreen**: 未完了だが**申請ブロッカーではない** — `INFOPLIST_KEY_UILaunchScreen_Generation = YES`によるXcode自動生成の空白画面。起動時の動作自体は問題なく、AppIcon/Development Teamとは異なりV1.0申請でもこのままで許容可能。ブランド化はV1.1以降の任意対応でよい
- [ ] **ITSAppUsesNonExemptEncryption**: 未設定 — 詳細調査結果は本ファイル末尾「輸出コンプライアンスに関する調査結果」を参照。**今回は値を変更していない**(ユーザー承認待ち)

## 4. App Store Connect(申請メタデータ)

- [ ] App Privacy回答の最終確定(下書きは`APP_STORE_PRIVACY_DRAFT.md`に準備済み、提出時に最新コードと再照合が必要)
- [ ] プライバシーポリシーURLのApp Store Connectへの登録(GitHub Pages URL自体は公開済み: https://hase4693-create.github.io/Post30/privacy-policy/ )
- [ ] スクリーンショット(各デバイスサイズ)
- [ ] アプリ説明文・キーワード・サポートURL
- [ ] 年齢レーティング
- [ ] 輸出コンプライアンス回答(ITSAppUsesNonExemptEncryptionの設定後に確定)
- [ ] TestFlight内部テスト・ビルドアップロード

---

## 輸出コンプライアンス(ITSAppUsesNonExemptEncryption)に関する調査結果

**変更は行っていません。以下は報告のみです。**

- **現在の設定**: 未設定(`project.pbxproj`・Info.plist生成キーいずれにも記載なし)。この状態では、Xcode OrganizerからApp Store Connectへビルドをアップロードするたびに、暗号化に関する質問へ手動で回答するダイアログが毎回表示される
- **アプリで使用している通信・暗号化機能**: `URLSession`/`URLRequest`/WebView/外部API通信は実装されておらず、ネットワーク通信は一切行っていない(`APP_STORE_PRIVACY_DRAFT.md`の調査結果と同様)。独自の暗号化実装も存在せず、標準iOSフレームワーク以外の暗号化ライブラリの使用もない
- **推奨する設定値**: `NO`(輸出コンプライアンス対象の暗号化を使用していない)
- **設定先**: `Post30.xcodeproj/project.pbxproj`の4つのビルド設定(Post30 Debug/Release、Post30Tests Debug/Release)に `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;` を追加する(`GENERATE_INFOPLIST_FILE = YES`のため、Info.plistを直接編集せずビルド設定経由で反映する)
- **App Store Connectの回答への影響**: この値を設定しておくことで、Archive→App Store Connectへのアップロード時に表示される「暗号化の使用有無」の確認ダイアログがスキップされ、申請作業がスムーズになる。App Store Connect上のExport Compliance情報にも自動的に反映される。未設定のままでも申請自体は可能だが、アップロードのたびに手動回答が必要になる

設定変更を承認いただければ、Phase 12またはPhase 13で反映します。
