//
//  CircularProgressView.swift
//  Post30
//
//  進捗リング（Circle + trim）。中央にパーセントを表示。外部ライブラリ不使用。
//

import SwiftUI

struct CircularProgressView: View {
    /// 進捗（0.0〜1.0）。
    let progress: Double
    var lineWidth: CGFloat = 10

    private var clamped: Double { min(max(progress, 0), 1) }
    private var percentText: String { "\(Int((clamped * 100).rounded()))%" }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Color.border, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Theme.Color.accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text(percentText)
                .font(.headline)
                .fontWeight(.bold)
                .minimumScaleFactor(0.6)
        }
        // 進捗の意味は親カードでまとめて読み上げるため、ここでは非表示にする。
        .accessibilityHidden(true)
    }
}

#Preview {
    CircularProgressView(progress: 0.1)
        .frame(width: 84, height: 84)
        .padding()
}
