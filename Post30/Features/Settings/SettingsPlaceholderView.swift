//
//  SettingsPlaceholderView.swift
//  Post30
//
//  TabView 成立のための最小プレースホルダ。本格実装は後続フェーズ。
//

import SwiftUI

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "設定",
                systemImage: "gearshape",
                description: Text("この画面は今後のフェーズで実装します。")
            )
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsPlaceholderView()
}
