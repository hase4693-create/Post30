# Post30 プライバシーポリシー 公開手順

このフォルダには、Post30 のプライバシーポリシーを公開するためのファイルが入っています。

- `index.html` … 公開用HTML（そのままブラウザで開けます）
- `privacy-policy-ja.md` … 本文の原稿（将来の改訂用。内容はHTMLと一致）
- `APP_STORE_PRIVACY_DRAFT.md` … App Store Connect の App Privacy 回答の作業メモ
- `README.md` … 本手順

公開URLはまだ確定していません。**アプリのSwiftコードにはURLを設定していません**（確定後に設定します）。

---

## GitHub Pages で公開する場合の手順

> GitHubのアカウント名・リポジトリ名はあなたが決めるため、以下では `<ユーザー名>` `<リポジトリ名>` と表記します。実在の値に置き換えてください。

1. **公開用リポジトリを作成する**
   GitHubで新規リポジトリ（例：Publicリポジトリ）を作成します。名前は任意です。

2. **index.html を配置する**
   `index.html` をリポジトリの直下、または `docs/` フォルダ配下に置きます。
   （必要に応じて `privacy-policy-ja.md` も一緒に置いて構いません。`README.md` と `APP_STORE_PRIVACY_DRAFT.md` は公開に必須ではありません。）

3. **GitHub Pages を有効化する**
   リポジトリの Settings → Pages を開き、Source を次のいずれかに設定します。
   - `Deploy from a branch` を選び、Branch を `main`、フォルダを `/ (root)`（`index.html` をルートに置いた場合）または `/docs`（`docs/` に置いた場合）。

4. **公開URLを確認する**
   数分後、Settings → Pages に公開URLが表示されます（一般に `https://<ユーザー名>.github.io/<リポジトリ名>/` の形式）。`index.html` をルートに置いた場合は、そのURLでポリシーが表示されます。

5. **スマートフォンとPCで表示確認する**
   公開URLをスマホ（Safari）とPCの両方で開き、見出し・本文・ダークモード表示、`post30.support@gmail.com` のmailtoリンクが動作することを確認します。

6. **HTTPSでアクセスできることを確認する**
   URLが `https://` で始まり、証明書の警告なく表示されることを確認します（GitHub PagesはHTTPS対応）。

7. **公開URLを App Store Connect へ登録する**
   App Store Connect のアプリ情報の「プライバシーポリシーURL」に、確定した公開URLを登録します（この作業は別工程）。

8. **同じURLを Post30 のアプリへ設定する**
   確定URLを、アプリの以下1箇所に設定します（現在は `nil`）。
   - ファイル：`Post30/Features/Settings/AppExternalLinks.swift`
   - 箇所：`static let current` の `privacyPolicyURL`
   - 例：`privacyPolicyURL: URL(string: "https://（確定したHTTPSのURL）")`
   これにより、設定画面の「プライバシーポリシー」が「準備中」から外部リンク（タップで開く）に自動で切り替わります。

9. **アプリ内リンクの動作を確認する**
   Xcodeでビルドし、設定画面の「プライバシーポリシー」をタップして、公開ページがブラウザで開くことを確認します。

10. **将来、本文を変更する際の注意**
    本文を改訂する場合は、`privacy-policy-ja.md` を先に更新し、その内容を `index.html` に反映してから公開ファイルを差し替えてください。大きな変更時は、本文中の「最終更新日」も更新します。機能追加（外部連携・分析・クラウド同期など）を行った場合は、本文の該当箇所も必ず見直してください。

---

## GitHub Pages 以外の選択肢

`index.html` は単一ファイルで完結しているため、次のようなホスティングでも同様に公開できます。

- 既存の自分のWebサイト（`/privacy` などのパスに設置）
- Cloudflare Pages
- Netlify
- そのほか静的HTMLを配信できるサービス

いずれの場合も、**HTTPSでアクセスできる公開URL**であることが必要です。公開後は、上記手順7〜9（App Store Connectへの登録／アプリへの反映／動作確認）を同様に行ってください。
