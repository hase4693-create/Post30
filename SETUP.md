# Post30 — Phase 2 セットアップ / 検証手順

このプロジェクトは Cowork 環境（Linux・Xcode無し）で生成したため、**私の側ではビルド・テスト・シミュレーター起動を実行できていません**。以下の手順を Mac / Xcode 上で実行して確認してください。

## 必要環境
- **Xcode 16 以降**（本プロジェクトは file system synchronized group / objectVersion 77 を使用）
- iOS 17.0 以降のシミュレーター

## 方法A（推奨）: 生成済みプロジェクトを開く
1. `Post30Project` フォルダを Mac にコピー
2. `Post30.xcodeproj` を Xcode で開く
   - 同期グループ方式のため、`Post30/` 配下・`Post30Tests/` 配下のファイルは自動でターゲットに含まれます
3. スキームは初回オープン時に Xcode が自動生成します
4. ビルド: `⌘B`
5. 実行（iPhoneシミュレーター）: `⌘R` → 「Post30 / Phase 2 基盤構築完了 / サンプル計画の投稿数 30件」が表示されればOK
6. テスト: `⌘U`

### コマンドラインで実行する場合
```bash
cd Post30Project

# ビルド
xcodebuild -project Post30.xcodeproj -scheme Post30 \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# テスト
xcodebuild -project Post30.xcodeproj -scheme Post30 \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```
（`iPhone 16` の部分は `xcrun simctl list devices` で利用可能な端末名に置き換えてください）

## 方法B（フォールバック）: 手動でプロジェクトを作り直す
方法Aで `.xcodeproj` が開けない場合:
1. Xcode で新規 → iOS App、Product Name = `Post30`、Interface = SwiftUI、Language = Swift、Storage = None
2. 生成された `ContentView.swift` は削除
3. `Post30/` 配下のフォルダ（App, Models, Theme, Utilities, PreviewContent, Resources）をプロジェクトへドラッグして追加（"Create groups"）
4. File → New → Target → Unit Testing Bundle を追加し、`Post30Tests/` 配下のファイルを追加
5. `⌘B` / `⌘U` で確認

## 期待される確認結果
- ビルド成功
- 起動画面に投稿数「30件」が表示
- Unit Test 9項目がすべて成功

## 既知の注意点
- `AppIcon` は 1024pt のプレースホルダのみ（画像未設定）。ビルドは通りますが「アイコン未設定」の警告が出る場合があります。UIフェーズで差し替えます。
- SF Symbols 名（SocialPlatform / PostCategory）は暫定です。UI実装フェーズで見直します。
