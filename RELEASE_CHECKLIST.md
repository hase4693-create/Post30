# RELEASE_CHECKLIST.md — Post30 App Store公開チェックリスト

Post30をApp Storeへ申請する前に確認すべき項目を整理したチェックリスト。Phase 12(2026-07-27)・Phase 13(2026-07-27〜2026-07-28)時点の調査結果を反映している。完了状況は今後のPhaseで随時更新する。

`APP_STORE_PRIVACY_DRAFT.md`との役割分担: 本ファイルは申請前作業全体のgo/no-goチェックリスト。`privacy-policy/APP_STORE_PRIVACY_DRAFT.md`はApp Privacy回答(データ収集有無)の判断根拠専用の文書として維持する。

---

## 1. コード品質

- [x] Build succeeded(Debug構成、iPhone 17 Simulator)
- [x] Build succeeded(Release構成、iPhone 17 Simulator。`-validate-for-store`検証も通過。Phase 13でAppIcon追加後も再検証済み)
- [x] 全テストpass(147件 / 失敗0 / スキップ0。Phase 13でxcresultにより複数回再検証)
- [x] Archive succeeded(`generic/platform=iOS` / Release構成。Phase 13でDevelopment Team設定後・AppIcon追加後の両時点で成功を確認)
- [x] 未使用プレースホルダーファイルの除去(Phase 12で対応済み)
- [x] 到達不能コード(Dead Code)の除去(Phase 12で対応済み: `.generate`ルート関連)
- [x] TODO/FIXME・print残骸なし(Phase 12調査で確認)
- [ ] 保存失敗パスの自動テスト整備(未着手)

## 2. 主要導線・リリース品質

- [x] Home/PostList/Calendarの主要ロジック(自動テストで確認済み)
- [ ] Home/PostList/Calendar/Settingsの実機/シミュレータでの目視動作確認(未実施・要ユーザー確認)
- [ ] Empty State表示の実機確認(未実施)
- [ ] 保存失敗時のアラート表示の実機確認(自動テストなし・未実施)
- [ ] 設定画面の外部リンク(お問い合わせ/プライバシーポリシー)タップ動作確認(未実施)
- [ ] Dynamic Type最大時の`CalendarDayCell`/`PostStatusBadge`崩れ確認(未実施、固定frame残存を確認済み)
- [ ] VoiceOver実機確認・Accessibility Inspector監査(未実施、CLIから実行不可)

## 3. App Store公開設定

**旧・申請ブロッカー(Phase 13で解消済み)**

- [x] **AppIcon実画像**: 完了 — 1024×1024・PNG・アルファチャンネルなし・sRGBの画像を`AppIcon.appiconset/AppIcon-1024.png`として配置し、`Contents.json`に`filename`を追加。Archive内`Assets.car`への実際の組み込みを`assetutil`で確認済み(`PixelWidth/PixelHeight: 1024`、`Opaque: true`)
- [x] **Development Team(署名)**: 完了 — Post30(アプリターゲット)のDebug/Release 2箇所に`DEVELOPMENT_TEAM = H7229AXFCS`を設定(ユーザーがXcodeのSigning & Capabilities画面で選択)。Post30Tests(テストターゲット)は未設定だが、Archive成功に影響がないことを確認済みのため対応不要と判断

**完了済み**

- [x] **Version(MARKETING_VERSION)**: 完了 — `1.0`(初回リリースとして妥当)
- [x] **Build Number(CURRENT_PROJECT_VERSION)**: 完了 — `1`(初回リリースとして妥当)
- [x] **Bundle ID**: 完了 — App: `com.hasegawa.post30` / Tests: `com.hasegawa.post30.tests`(CLAUDE.md記載の正式値と一致)
- [x] **ITSAppUsesNonExemptEncryption**: 完了 — `NO`を設定済み。詳細は本ファイル末尾「輸出コンプライアンスに関する調査結果」を参照

**ブロッカーではない(V1.0では許容可能・任意対応)**

- [ ] **LaunchScreen**: 未完了だが**申請ブロッカーではない** — `INFOPLIST_KEY_UILaunchScreen_Generation = YES`によるXcode自動生成の空白画面。起動時の動作自体は問題なく、V1.0申請でもこのままで許容可能。ブランド化はV1.1以降の任意対応でよい

## 4. App Store Connect(申請メタデータ)

- [ ] App Privacy回答の最終確定(下書きは`APP_STORE_PRIVACY_DRAFT.md`に準備済み、提出時に最新コードと再照合が必要)
- [ ] プライバシーポリシーURLのApp Store Connectへの登録(GitHub Pages URL自体は公開済み: https://hase4693-create.github.io/Post30/privacy-policy/ )
- [ ] スクリーンショット(各デバイスサイズ)
- [ ] アプリ説明文・キーワード・サポートURL
- [ ] 年齢レーティング
- [ ] 輸出コンプライアンス回答(プロジェクト側の設定は完了。App Store Connect提出画面での最終回答は未実施)
- [ ] TestFlight内部テスト・ビルドアップロード(Archiveはローカルで成功済み。実際のアップロード操作は未実施)

---

## 輸出コンプライアンス(ITSAppUsesNonExemptEncryption)に関する調査結果

**Phase 13で`NO`を設定済みです。**

- **設定内容**: `project.pbxproj`のPost30(App)ターゲット Debug/Release 2箇所に `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;` を追加。Release構成でビルドした`Post30.app/Info.plist`に `ITSAppUsesNonExemptEncryption = false` が反映されていることを`PlistBuddy`で確認済み。Post30Tests(テストターゲット)には追加していない
- **アプリで使用している通信・暗号化機能**: `URLSession`/`URLRequest`/WebView/外部API通信は実装されておらず、ネットワーク通信は一切行っていない(`APP_STORE_PRIVACY_DRAFT.md`の調査結果と同様)。独自の暗号化実装も存在せず、標準iOSフレームワーク以外の暗号化ライブラリの使用もない
- **推奨する設定値**: `NO`(輸出コンプライアンス対象の暗号化を使用していない) → 設定済み
- **設定先**: `Post30.xcodeproj/project.pbxproj`のPost30(App)ターゲット Debug/Release 2箇所(`GENERATE_INFOPLIST_FILE = YES`のため、Info.plistを直接編集せずビルド設定経由で反映)。Post30Tests(テストターゲット)は対象外
- **App Store Connectの回答への影響**: この値を設定したことで、Archive→App Store Connectへのアップロード時に表示される「暗号化の使用有無」の確認ダイアログがスキップされる見込み。App Store Connect上のExport Compliance情報にも自動的に反映される見込み。ローカルでのArchive(`generic/platform=iOS` / Release)は成功し、生成されたアプリバンドルの`Info.plist`にも`ITSAppUsesNonExemptEncryption = false`が反映されていることを確認済み。実際のTestFlight/App Store Connectへのアップロード時の挙動は未確認(Claude Codeから実行不可な領域)
