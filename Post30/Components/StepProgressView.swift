//
//  StepProgressView.swift
//  Post30
//
//  ウィザードのステップ進捗表示（● ━ ○ と「N / 総数 タイトル」）。
//

import SwiftUI

struct StepProgressView: View {
    /// 現在ステップ（1始まり）。
    let currentStep: Int
    let totalSteps: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(spacing: 6) {
                ForEach(1...totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Theme.Color.accent : Theme.Color.border)
                        .frame(width: 10, height: 10)
                    if index < totalSteps {
                        Rectangle()
                            .fill(index < currentStep ? Theme.Color.accent : Theme.Color.border)
                            .frame(height: 2)
                    }
                }
            }

            HStack(spacing: 6) {
                Text("\(currentStep) / \(totalSteps)")
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.accentText)
                Text(title)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ステップ \(currentStep) / \(totalSteps)。\(title)")
    }
}

#Preview {
    VStack(spacing: 24) {
        StepProgressView(currentStep: 1, totalSteps: 3, title: "事業情報")
        StepProgressView(currentStep: 2, totalSteps: 3, title: "投稿条件")
        StepProgressView(currentStep: 3, totalSteps: 3, title: "入力内容の確認")
    }
    .padding()
}
