//
//  PostEditorViewModelTests.swift
//  Post30Tests
//
//  投稿編集ロジックの検証。
//

import XCTest
@testable import Post30

@MainActor
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

    // 改善項目1：投稿日を過去に変更して保存しても status は変わらない
    func testEditingDateDoesNotChangeStatus() {
        let post = makePost() // status = .scheduled（未投稿）
        let vm = makeVM(post: post)
        // 予定日を過去へ変更（本文は既存のまま有効）
        vm.scheduledDate = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let didSave = vm.save()

        XCTAssertTrue(didSave)
        XCTAssertEqual(post.status, .scheduled, "投稿日の変更で status が変化してはいけない")
        XCTAssertNil(post.publishedAt)
    }

    // MARK: - Phase 9-2: 投稿済みにする

    private func makePost(status: PostStatus, publishedAt: Date? = nil) -> Post {
        Post(
            scheduledDate: calendar.startOfDay(for: Date()),
            scheduledTime: DateComponents(hour: 8, minute: 0),
            platform: .threads, category: .empathy,
            content: "本文", status: status, publishedAt: publishedAt
        )
    }

    // 1/2/3. 下書き・予約済みを投稿済みに変更でき、status=published・publishedAt が設定される
    func testConfirmMarkAsPublishedSetsStatusAndPublishedAt() {
        for status in [PostStatus.draft, .scheduled] {
            let post = makePost(status: status)
            let time = Date(timeIntervalSince1970: 1_900_000_000)
            let vm = makeVM(post: post, now: time)
            XCTAssertTrue(vm.canMarkAsPublished)
            let ok = vm.confirmMarkAsPublished()
            XCTAssertTrue(ok)
            XCTAssertEqual(post.status, .published)
            XCTAssertEqual(post.publishedAt, time)
            XCTAssertEqual(post.updatedAt, time)
        }
    }

    // 5. 編集内容も同時に保存される
    func testMarkAsPublishedAlsoSavesEdits() {
        let post = makePost(status: .scheduled)
        let vm = makeVM(post: post)
        vm.content = "編集後の本文"
        vm.category = .failure
        XCTAssertTrue(vm.confirmMarkAsPublished())
        XCTAssertEqual(post.content, "編集後の本文")
        XCTAssertEqual(post.category, .failure)
        XCTAssertEqual(post.status, .published)
    }

    // 6. 日付を変更しただけ（保存）では投稿済みにならない
    func testDateChangeSaveDoesNotPublish() {
        let post = makePost(status: .scheduled)
        let vm = makeVM(post: post)
        vm.scheduledDate = calendar.date(byAdding: .day, value: -10, to: Date())!
        XCTAssertTrue(vm.save())
        XCTAssertEqual(post.status, .scheduled)
        XCTAssertNil(post.publishedAt)
    }

    // 7. 通常保存では publishedAt が変わらない
    func testNormalSaveDoesNotSetPublishedAt() {
        let post = makePost(status: .scheduled)
        let vm = makeVM(post: post)
        vm.content = "更新"
        XCTAssertTrue(vm.save())
        XCTAssertNil(post.publishedAt)
    }

    // 8. 既に投稿済みの投稿を開いただけでは publishedAt が変わらない
    func testOpeningPublishedDoesNotChangePublishedAt() {
        let original = Date(timeIntervalSince1970: 1_800_000_000)
        let post = makePost(status: .published, publishedAt: original)
        let vm = makeVM(post: post)
        XCTAssertFalse(vm.canMarkAsPublished)
        vm.requestMarkAsPublished() // ガードで何も起きない
        XCTAssertFalse(vm.showMarkPublishedDialog)
        XCTAssertEqual(post.publishedAt, original)
    }

    // 9/10. 本文が空だと投稿済みにできない（成功扱いにしない）
    func testCannotMarkAsPublishedWithEmptyContent() {
        let post = makePost(status: .scheduled)
        let vm = makeVM(post: post)
        vm.content = "   "
        XCTAssertFalse(vm.confirmMarkAsPublished())
        XCTAssertEqual(post.status, .scheduled, "失敗時は投稿済みにしない")
        XCTAssertNil(post.publishedAt)
    }

    // canMarkAsPublished は draft/scheduled のみ true
    func testCanMarkAsPublishedByStatus() {
        XCTAssertTrue(makeVM(post: makePost(status: .draft)).canMarkAsPublished)
        XCTAssertTrue(makeVM(post: makePost(status: .scheduled)).canMarkAsPublished)
        XCTAssertFalse(makeVM(post: makePost(status: .published, publishedAt: Date())).canMarkAsPublished)
        XCTAssertFalse(makeVM(post: makePost(status: .skipped)).canMarkAsPublished)
    }
}
