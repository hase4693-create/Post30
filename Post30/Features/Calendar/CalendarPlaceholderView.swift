//
//  CalendarPlaceholderView.swift
//  Post30
//
//  TabView 成立のための最小プレースホルダ。本格実装は Phase 7。
//

import SwiftUI

struct CalendarPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "カレンダー",
                systemImage: "calendar",
                description: Text("この画面は今後のフェーズで実装します。")
            )
            .navigationTitle("カレンダー")
        }
    }
}

#Preview {
    CalendarPlaceholderView()
}
