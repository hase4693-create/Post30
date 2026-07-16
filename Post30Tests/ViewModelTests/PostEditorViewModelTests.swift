//
//  PostEditorViewModelTests.swift
//  Post30Tests
//
//  投稿編集ロジックの検証。
//

import XCTest
@testable import Post30

final class PostEditorViewModelTests: XCTestCase {

    private let calendar = Calendar.current

    private func makePost() -> Post {
        Post(
            scheduledDate: calendar.startOfDay(for: Date()),
            scheduledTime: DateComponents(hour: 8, minute: 0),
            platform: .threads,
            category: .empathy,
            content: "元の本文",
            status: .scheduled,
            memo: nil
        )
    }

    private func makeVM(post: Post, now: Date = Date(), onSaved: @escaping () -> Void = {}) -> PostEditorViewModel {
        PostEditorViewModel(post: post, calendar: calendar, now: { now }, onSaved: onSaved)
    }

    // 保存可否（本文あり）
    func testCanSaveWhenContentPresent() {
        let vm = makeVM(post: makePost())
        XCTAssertTrue(vm.canSave)
    }

    // 本文が空なら保存不可
    func testCannotSaveWhenContentEmpty() {
        let vm = makeVM(post: makePost())
        vm.content = "   \n  "
        XCTAssertFalse(vm.canSave)
    }

    // 保存で updatedAt が更新される
    func testSaveUpdatesUpdatedAt() {
        let post = makePost()
        let saveTime = Date(timeIntervalSince1970: 1_800_000_000)
        let vm = makeVM(post: post, now: saveTime)
        vm.content = "更新後の本文"
        vm.save()
        XCTAssertEqual(post.updatedAt, saveTime)
    }

    // 保存で content が更新される
    func testSaveUpdatesContent() {
        let post = makePost()
        let vm = makeVM(post: post)
        vm.content = "新しい本文"
        vm.save()
        XCTAssertEqual(post.content, "新しい本文")
    }

    // 保存で category が更新される
    func testSaveUpdatesCategory() {
        let post = makePost()
        let vm = makeVM(post: post)
        vm.category = .failure
        vm.save()
        XCTAssertEqual(post.category, .failure)
    }

    // 保存で platform が更新される
    func testSaveUpdatesPlatform() {
        let post = makePost()
        let vm = makeVM(post: post)
        vm.platform = .instagram
        vm.save()
        XCTAssertEqual(post.platform, .instagram)
    }

    // 保存で memo が更新される
    func testSaveUpdatesMemo() {
        let post = makePost()
        let vm = makeVM(post: post)
        vm.memo = "あとで画像を追加"
        vm.save()
        XCTAssertEqual(post.memo, "あとで画像を追加")
    }

    // 本文が空のときは保存しても更新されない
    func testSaveIsIgnoredWhenInvalid() {
        let post = makePost()
        let vm = makeVM(post: post)
        vm.content = ""
        vm.save()
        XCTAssertEqual(post.content, "元の本文")
    }

    // 未保存変更検知：初期は変更なし
    func testNoUnsavedChangesInitially() {
        let vm = makeVM(post: makePost())
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    // 未保存変更検知：本文を変えると変更あり
    func testHasUnsavedChangesAfterEditingContent() {
        let vm = makeVM(post: makePost())
        vm.content = "編集した本文"
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    // 保存完了で onSaved が呼ばれる
    func testOnSavedCalledAfterSave() {
        var called = false
        let vm = makeVM(post: makePost(), onSaved: { called = true })
        vm.content = "本文"
        vm.save()
        XCTAssertTrue(called)
    }
}
