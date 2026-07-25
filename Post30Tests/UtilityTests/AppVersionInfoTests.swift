//
//  AppVersionInfoTests.swift
//  Post30Tests
//
//  バージョン／ビルド番号の安全な取り扱いの検証（純ロジック）。
//

import XCTest
@testable import Post30

final class AppVersionInfoTests: XCTestCase {

    // 両方ある場合
    func testBothPresent() {
        let info = AppVersionInfo(version: "1.0", build: "1")
        XCTAssertEqual(info.displayText, "バージョン 1.0（1）")
        XCTAssertEqual(info.valueText, "1.0（1）")
    }

    // バージョンだけ取得できる場合
    func testVersionOnly() {
        let info = AppVersionInfo(version: "1.0", build: nil)
        XCTAssertEqual(info.displayText, "バージョン 1.0")
        XCTAssertEqual(info.valueText, "1.0")
    }

    // どちらも取得できない場合（クラッシュしない）
    func testNeitherPresent() {
        let info = AppVersionInfo(version: nil, build: nil)
        XCTAssertEqual(info.displayText, "バージョン情報を取得できません")
        XCTAssertEqual(info.valueText, "—")
    }

    // 空文字・空白のみを安全に「未取得」として扱う
    func testEmptyAndWhitespaceTreatedAsMissing() {
        let info = AppVersionInfo(version: "   ", build: "")
        XCTAssertEqual(info.displayText, "バージョン情報を取得できません")
        XCTAssertEqual(info.valueText, "—")
    }

    // ビルドだけある場合も安全
    func testBuildOnly() {
        let info = AppVersionInfo(version: nil, build: "42")
        XCTAssertEqual(info.valueText, "ビルド 42")
    }

    // 前後の空白は除去される
    func testTrimsWhitespace() {
        let info = AppVersionInfo(version: " 2.1 ", build: " 7 ")
        XCTAssertEqual(info.valueText, "2.1（7）")
    }
}
