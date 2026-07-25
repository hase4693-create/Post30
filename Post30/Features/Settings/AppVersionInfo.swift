//
//  AppVersionInfo.swift
//  Post30
//
//  アプリのバージョン／ビルド番号を Bundle から安全に取得する純粋な値型。
//  取得失敗・空文字でもクラッシュせず、欠落時はフォールバック表示にする。
//  SwiftUI 非依存でテスト可能。
//

import Foundation

struct AppVersionInfo: Equatable {
    /// CFBundleShortVersionString（例: "1.0"）。取得不可なら空文字。
    let version: String
    /// CFBundleVersion（例: "1"）。取得不可なら空文字。
    let build: String

    init(version: String?, build: String?) {
        self.version = version?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.build = build?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var hasVersion: Bool { !version.isEmpty }
    private var hasBuild: Bool { !build.isEmpty }

    /// 値のみの表示（例: "1.0（1）" / "1.0" / "—"）。
    var valueText: String {
        switch (hasVersion, hasBuild) {
        case (true, true): return "\(version)（\(build)）"
        case (true, false): return version
        case (false, true): return "ビルド \(build)"
        case (false, false): return "—"
        }
    }

    /// ラベル込みの表示（VoiceOver 等で使用）。
    var displayText: String {
        switch (hasVersion, hasBuild) {
        case (true, true): return "バージョン \(version)（\(build)）"
        case (true, false): return "バージョン \(version)"
        case (false, true): return "ビルド \(build)"
        case (false, false): return "バージョン情報を取得できません"
        }
    }

    /// Bundle から生成する（既定は .main）。
    static func fromBundle(_ bundle: Bundle = .main) -> AppVersionInfo {
        AppVersionInfo(
            version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        )
    }
}
