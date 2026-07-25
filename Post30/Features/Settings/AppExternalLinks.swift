//
//  AppExternalLinks.swift
//  Post30
//
//  外部リンク（サポート・プライバシーポリシー）を一元管理する設定値。
//  App Store 申請前に、ここの値を正式なものへ差し替えるだけでよい設計。
//  未確定の項目は nil のままにする（設定画面では「準備中」＝タップ不可で表示）。
//

import Foundation

struct AppExternalLinks {
    /// お問い合わせ用メールアドレス（未確定なら nil）。
    let supportEmail: String?
    /// プライバシーポリシーの URL（未確定なら nil）。
    let privacyPolicyURL: URL?

    /// 現在の設定値。**正式な連絡先／URL が決まったらここだけ差し替える。**
    /// 仮の値・架空の URL は入れない。
    /// - supportEmail: ユーザー確認済みの正式アドレス。
    /// - privacyPolicyURL: 公開済みの HTTPS URL（GitHub Pages）。
    static let current = AppExternalLinks(
        supportEmail: "craftflow.apps@gmail.com",
        privacyPolicyURL: URL(string: "https://hase4693-create.github.io/Post30/privacy-policy/")
    )

    /// mailto URL（supportEmail が有効なときのみ）。
    var supportMailURL: URL? {
        guard let supportEmail, !supportEmail.isEmpty else { return nil }
        return URL(string: "mailto:\(supportEmail)")
    }
}
