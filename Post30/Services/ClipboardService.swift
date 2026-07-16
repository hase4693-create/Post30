//
//  ClipboardService.swift
//  Post30
//
//  クリップボード処理の抽象化。
//  HomeViewModel が UIPasteboard(UIKit) に直接依存しないよう、
//  プロトコル越しに注入してテスト可能にする（過剰なサービス層は作らない）。
//

import Foundation

/// テキストをクリップボードへコピーする最小インターフェース。
protocol ClipboardService {
    func copy(_ text: String)
}

#if canImport(UIKit)
import UIKit

/// 実機用の実装（UIPasteboard）。この型だけが UIKit に依存する。
final class SystemClipboardService: ClipboardService {
    func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}
#endif
