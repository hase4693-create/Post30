//
//  Post30App.swift
//  Post30
//
//  アプリのエントリポイント。SwiftData の ModelContainer を構成する。
//

import SwiftUI
import SwiftData

@main
struct Post30App: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: MonthPlan.self, Post.self)
        } catch {
            fatalError("ModelContainer の生成に失敗しました: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
