//
//  PrimaryButton.swift
//  Post30
//
//  主要アクション用の共通ボタン（高さ52・角丸16・白文字）。
//  塗り(solid)と紫グラデーション(gradient)を切り替えられる。
//

import SwiftUI

struct PrimaryButton: View {
    enum Fill { case solid, gradient }

    let title: String
    var leadingSystemImage: String? = nil
    var trailingSystemImage: String? = nil
    var fill: Fill = .solid
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.small) {
                if let leadingSystemImage {
                    Image(systemName: leadingSystemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
                if trailingSystemImage != nil {
                    Spacer(minLength: Theme.Spacing.small)
                }
                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                }
            }
            .padding(.horizontal, Theme.Spacing.large)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.Layout.primaryButtonHeight)
            .foregroundStyle(.white)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.buttonCornerRadius))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var background: some View {
        switch fill {
        case .solid:
            Theme.Color.accent
        case .gradient:
            Theme.Gradient.accent
        }
    }
}

/// 押下時にわずかに縮小するボタンスタイル（スケール 0.97）。
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "AIで30日分の投稿を作成",
                      leadingSystemImage: "sparkles",
                      trailingSystemImage: "chevron.right",
                      fill: .gradient) {}
        PrimaryButton(title: "塗りボタン", fill: .solid) {}
    }
    .padding()
}
