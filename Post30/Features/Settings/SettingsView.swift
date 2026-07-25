//
//  SettingsView.swift
//  Post30
//
//  Version 1.0 用の最小限の設定・情報画面（読み取り専用・ViewModel なし）。
//  標準 Form を使用し、ダークモード／Dynamic Type に自然に対応する。
//  外部リンクは未設定時に「準備中」（タップ不可）で表示する。
//

import SwiftUI

struct SettingsView: View {
    private let versionInfo = AppVersionInfo.fromBundle()
    private let links = AppExternalLinks.current

    var body: some View {
        NavigationStack {
            Form {
                Section("アプリ情報") {
                    LabeledContent("アプリ名", value: "Post30")
                    LabeledContent("バージョン", value: versionInfo.valueText)
                        .accessibilityLabel(versionInfo.displayText)
                }

                Section("サポート") {
                    supportRow
                    privacyRow
                }

                Section("このアプリについて") {
                    Text("Post30は、30日分のSNS投稿を計画・管理するためのアプリです。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - サポート行

    @ViewBuilder
    private var supportRow: some View {
        if let url = links.supportMailURL {
            Link(destination: url) {
                Label("お問い合わせ", systemImage: "envelope")
            }
        } else {
            preparingRow(title: "お問い合わせ", systemImage: "envelope")
        }
    }

    @ViewBuilder
    private var privacyRow: some View {
        if let url = links.privacyPolicyURL {
            Link(destination: url) {
                Label("プライバシーポリシー", systemImage: "hand.raised")
            }
        } else {
            preparingRow(title: "プライバシーポリシー", systemImage: "hand.raised")
        }
    }

    /// 未設定の項目：タップ不可＋「準備中」を明示。
    private func preparingRow(title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text("準備中")
        }
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("準備中")
        .accessibilityHint("現在準備中です")
    }
}

#Preview {
    SettingsView()
}

#Preview("ダークモード") {
    SettingsView()
        .preferredColorScheme(.dark)
}

#Preview("大きい文字サイズ") {
    SettingsView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
