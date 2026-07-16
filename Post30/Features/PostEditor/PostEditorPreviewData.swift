//
//  PostEditorPreviewData.swift
//  Post30
//
//  投稿編集 Preview 専用データ（DEBUG 限定・本番 SampleData とは分離）。
//

#if DEBUG
import Foundation

enum PostEditorPreviewData {

    private static func makePost(content: String) -> Post {
        Post(
            scheduledDate: Calendar.current.startOfDay(for: Date()),
            scheduledTime: DateComponents(hour: 8, minute: 0),
            platform: .threads,
            category: .empathy,
            content: content,
            status: .scheduled,
            memo: nil
        )
    }

    static func normal() -> PostEditorViewModel {
        PostEditorViewModel(post: makePost(content: "朝の30分を自分のために使うと、1日が変わります。"))
    }

    static func emptyContent() -> PostEditorViewModel {
        PostEditorViewModel(post: makePost(content: ""))
    }

    static func longContent() -> PostEditorViewModel {
        let text = String(
            repeating: "投稿を続けるコツは、完璧を目指さないことです。60点で出し続けるほうが、100点を狙って止まるより伸びます。",
            count: 5
        )
        return PostEditorViewModel(post: makePost(content: text))
    }
}
#endif
