//
//  PreviewSupport.swift
//  Post30
//
//  Preview 用のインメモリ ModelContainer を付与するヘルパー（DEBUG 限定）。
//  本番データへは一切影響しない。
//

#if DEBUG
import SwiftUI
import SwiftData

extension View {
    /// Preview に本番と分離したインメモリの永続コンテナを付与する。
    func previewPersistence() -> some View {
        modelContainer(for: [MonthPlan.self, Post.self], inMemory: true)
    }
}
#endif
