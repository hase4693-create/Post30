//
//  Theme.swift
//  Post30
//
//  アプリ全体の基本デザイン定数（デザイン案 2 準拠）。
//  余白・角丸・カラー・グラデーションの最小限のみ定義する。
//  カラーは固定の白/黒を避け、ライト/ダーク両対応の適応カラーを用いる。
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Theme {

    // MARK: - レイアウト（余白・サイズ）

    enum Layout {
        /// 画面左右の余白。
        static let screenHorizontalPadding: CGFloat = 20
        /// セクション間の余白。
        static let sectionSpacing: CGFloat = 20
        /// カード間の余白。
        static let cardSpacing: CGFloat = 16
        /// カードの角丸。
        static let cardCornerRadius: CGFloat = 16
        /// 主要ボタンの角丸。
        static let buttonCornerRadius: CGFloat = 16
        /// カード内アクションボタンの角丸。
        static let actionButtonCornerRadius: CGFloat = 12
        /// タグの角丸。
        static let tagCornerRadius: CGFloat = 8
        /// 主要ボタンの高さ。
        static let primaryButtonHeight: CGFloat = 52
        /// 最小タップ領域。
        static let minTapTarget: CGFloat = 44
    }

    // MARK: - スペーシング（小・中・大）

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    // MARK: - カラー（ライト/ダーク両対応）

    enum Color {
        /// アクセント（メインの紫 #7B61FF）。
        static let accent = SwiftUI.Color(hex: 0x7B61FF)
        /// 淡紫の背景／ソフト面（タグ・バッジ等）。
        static let accentSoft = adaptive(light: 0xF2EEFF, dark: 0x2E2A45)
        /// ソフト面の上に置く紫のテキスト／アイコン色。
        static let accentText = adaptive(light: 0x7B61FF, dark: 0xC4B5FF)
        /// カード背景（ライト #FFFFFF / ダーク #1F2937）。
        static let cardBackground = adaptive(light: 0xFFFFFF, dark: 0x1F2937)
        /// 画面背景（ライト #FFFFFF / ダーク #0B0B0F）。
        static let screenBackground = adaptive(light: 0xFFFFFF, dark: 0x0B0B0F)
        /// 区切り線（#E5E7EB）。
        static let border = adaptive(light: 0xE5E7EB, dark: 0x3A3A3C)
        /// カードの影色。
        static let cardShadow = SwiftUI.Color.black.opacity(0.06)
        /// 成功（投稿済み反映などの一時表現）。
        static let success = SwiftUI.Color(hex: 0x22C55E)

        /// ライト/ダークで切り替わる適応カラーを生成する。
        static func adaptive(light: UInt, dark: UInt) -> SwiftUI.Color {
            #if canImport(UIKit)
            return SwiftUI.Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
            })
            #else
            return SwiftUI.Color(hex: light)
            #endif
        }
    }

    // MARK: - グラデーション

    enum Gradient {
        /// 主要ボタン用の紫グラデーション。
        static let accent = LinearGradient(
            colors: [SwiftUI.Color(hex: 0x8E76FF), SwiftUI.Color(hex: 0x6B4EFF)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        /// 画面上部に控えめに敷く淡い紫グラデーション。
        static let topBackground = LinearGradient(
            colors: [Theme.Color.accent.opacity(0.08), SwiftUI.Color.clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - カラー用ヘルパー

extension Color {
    /// 0xRRGGBB 形式の16進からカラーを生成する。
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
#endif

// MARK: - カード面の共通装飾

extension View {
    /// カード面（背景・角丸・影）を適用する。内側の余白は呼び出し側で付与する。
    func cardSurface() -> some View {
        self
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardCornerRadius))
            .shadow(color: Theme.Color.cardShadow, radius: 10, x: 0, y: 4)
    }
}
