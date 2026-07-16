//
//  PostGenerationView.swift
//  Post30
//
//  30日分投稿生成ウィザード（4ステップ）。AI 非接続・モック生成。
//  上部にステップ進捗、下部に主要ボタン（キーボードに隠れないよう safeAreaInset）。
//

import SwiftUI

struct PostGenerationView: View {
    @State private var viewModel: PostGenerationViewModel

    init(viewModel: PostGenerationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.step != .generation {
                    StepProgressView(
                        currentStep: viewModel.step.inputStepNumber,
                        totalSteps: 3,
                        title: viewModel.step.title
                    )
                    .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
                    .padding(.top, Theme.Spacing.medium)
                }

                ScrollView {
                    stepContent
                        .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
                        .padding(.vertical, Theme.Spacing.large)
                }
            }
            .background(backgroundView)
            .navigationTitle("AIで30日分の投稿を作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.close()
                    } label: {
                        Label("閉じる", systemImage: "xmark")
                    }
                    .accessibilityLabel("閉じる")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.step != .generation {
                    bottomBar
                }
            }
            .confirmationDialog(
                "現在の投稿計画を置き換えますか？",
                isPresented: $vm.showReplaceDialog,
                titleVisibility: .visible
            ) {
                Button("置き換える", role: .destructive) { viewModel.confirmReplace() }
                Button("キャンセル", role: .cancel) { viewModel.cancelReplace() }
            }
        }
    }

    private var backgroundView: some View {
        Theme.Color.screenBackground
            .overlay(alignment: .top) { Theme.Gradient.topBackground.frame(height: 180) }
            .ignoresSafeArea()
    }

    // MARK: - ステップ本体

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .businessInfo:
            BusinessInfoStepView(viewModel: viewModel)
        case .conditions:
            ConditionsStepView(viewModel: viewModel)
        case .confirmation:
            ConfirmationStepView(viewModel: viewModel)
        case .generation:
            GenerationStepView(viewModel: viewModel)
        }
    }

    // MARK: - 下部ボタン

    @ViewBuilder
    private var bottomBar: some View {
        HStack(spacing: Theme.Spacing.medium) {
            switch viewModel.step {
            case .businessInfo:
                PrimaryButton(title: "次へ", trailingSystemImage: "chevron.right", fill: .solid) {
                    viewModel.next()
                }
                .disabled(!viewModel.canProceed)
                .opacity(viewModel.canProceed ? 1 : 0.5)
            case .conditions:
                WizardOutlineButton(title: "戻る") { viewModel.back() }
                PrimaryButton(title: "次へ", trailingSystemImage: "chevron.right", fill: .solid) {
                    viewModel.next()
                }
            case .confirmation:
                WizardOutlineButton(title: "戻って修正") { viewModel.back() }
                PrimaryButton(title: "この内容で作成", leadingSystemImage: "sparkles", fill: .gradient) {
                    viewModel.next()
                }
            case .generation:
                EmptyView()
            }
        }
        .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Color.screenBackground)
    }
}

// MARK: - Step 1 事業情報

private struct BusinessInfoStepView: View {
    @Bindable var viewModel: PostGenerationViewModel

    var body: some View {
        VStack(spacing: Theme.Layout.cardSpacing) {
            GenInputCard(title: "業種", subtitle: "例：Web制作", required: true) {
                TextField("業種を入力", text: $viewModel.businessType)
                    .textFieldStyle(.plain)
            }
            GenInputCard(title: "商品・サービス", subtitle: "例：個人事業主向けホームページ制作", required: true) {
                TextField("商品・サービスを入力", text: $viewModel.serviceName)
                    .textFieldStyle(.plain)
            }
            GenInputCard(title: "ターゲット", subtitle: "例：ホームページを持っていない個人事業主", required: true) {
                TextField("ターゲットを入力", text: $viewModel.targetAudience)
                    .textFieldStyle(.plain)
            }
            GenInputCard(title: "投稿目的", subtitle: "例：認知拡大と問い合わせ獲得", required: false) {
                TextField("投稿目的を入力", text: $viewModel.postingGoal)
                    .textFieldStyle(.plain)
            }
            GenInputCard(title: "自社・自分の強み", subtitle: "例：専門用語を使わず、分かりやすく説明できる", required: false) {
                TextField("強みを入力", text: $viewModel.strength)
                    .textFieldStyle(.plain)
            }
        }
    }
}

// MARK: - Step 2 投稿条件

private struct ConditionsStepView: View {
    @Bindable var viewModel: PostGenerationViewModel

    var body: some View {
        VStack(spacing: Theme.Layout.cardSpacing) {
            GenInputCard(title: "投稿先SNS", subtitle: nil, required: false) {
                Picker("投稿先SNS", selection: $viewModel.platform) {
                    ForEach(SocialPlatform.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            GenInputCard(title: "投稿数", subtitle: nil, required: false) {
                Picker("投稿数", selection: $viewModel.postCount) {
                    ForEach(viewModel.postCountOptions, id: \.self) { Text("\($0)件").tag($0) }
                }
                .pickerStyle(.segmented)
            }
            GenInputCard(title: "文章の雰囲気", subtitle: nil, required: false) {
                Picker("文章の雰囲気", selection: $viewModel.tone) {
                    ForEach(PostTone.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            GenInputCard(title: "宣伝投稿の割合", subtitle: nil, required: false) {
                Picker("宣伝投稿の割合", selection: $viewModel.promotionLevel) {
                    ForEach(PromotionLevel.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            GenInputCard(title: "避けたい表現", subtitle: "自由入力", required: false) {
                TextField("避けたい表現を入力", text: $viewModel.prohibitedExpressions)
                    .textFieldStyle(.plain)
            }
            GenInputCard(title: "投稿日の開始日", subtitle: nil, required: false) {
                DatePicker("開始日", selection: $viewModel.startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
            GenInputCard(title: "投稿時刻", subtitle: nil, required: false) {
                DatePicker("投稿時刻", selection: $viewModel.scheduledTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Step 3 確認

private struct ConfirmationStepView: View {
    let viewModel: PostGenerationViewModel

    var body: some View {
        VStack(spacing: Theme.Layout.cardSpacing) {
            confirmCard(title: "事業情報", rows: [
                ("業種", viewModel.businessType),
                ("商品・サービス", viewModel.serviceName),
                ("ターゲット", viewModel.targetAudience),
                ("投稿目的", viewModel.postingGoal),
                ("強み", viewModel.strength)
            ])
            confirmCard(title: "投稿条件", rows: [
                ("SNS", viewModel.platform.displayName),
                ("投稿数", "\(viewModel.postCount)件"),
                ("文章の雰囲気", viewModel.tone.displayName),
                ("宣伝割合", viewModel.promotionLevel.displayName),
                ("開始日", viewModel.startDateText()),
                ("投稿時刻", viewModel.scheduledTimeText()),
                ("避けたい表現", viewModel.prohibitedExpressions)
            ])
        }
    }

    private func confirmCard(title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(title)
                .font(.headline)
            ForEach(rows, id: \.0) { row in
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(row.1.isEmpty ? "（未入力）" : row.1)
                        .font(.body)
                        .foregroundStyle(row.1.isEmpty ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

// MARK: - Step 4 生成中 / 完了

private struct GenerationStepView: View {
    let viewModel: PostGenerationViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            switch viewModel.phase {
            case .generating(let current, let total):
                generatingView(current: current, total: total)
            case .completed:
                completedView
            case .idle:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.large * 2)
    }

    private func generatingView(current: Int, total: Int) -> some View {
        VStack(spacing: Theme.Spacing.large) {
            ProgressView(value: total > 0 ? Double(current) / Double(total) : 0)
                .tint(Theme.Color.accent)
                .padding(.horizontal, Theme.Spacing.large)

            Text("30日分の投稿を作成しています")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("\(current) / \(total)件 作成中")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.accentText)

            WizardOutlineButton(title: "キャンセル") { viewModel.cancelGeneration() }
                .padding(.horizontal, Theme.Spacing.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("30日分の投稿を作成中。\(current) / \(total)件")
    }

    private var completedView: some View {
        VStack(spacing: Theme.Spacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.Color.success)
                .accessibilityHidden(true)

            Text("\(viewModel.generatedCount)件の投稿を作成しました")
                .font(.headline)
                .multilineTextAlignment(.center)

            VStack(spacing: Theme.Spacing.small) {
                infoRow("生成件数", "\(viewModel.generatedCount)件")
                infoRow("開始日", viewModel.startDateText())
                infoRow("対象SNS", viewModel.completedPlatformName)
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity)
            .cardSurface()

            VStack(spacing: Theme.Spacing.medium) {
                PrimaryButton(title: "投稿一覧を見る", leadingSystemImage: "list.bullet", fill: .gradient) {
                    viewModel.goToPostList()
                }
                WizardOutlineButton(title: "ホームへ戻る") { viewModel.goHome() }
            }
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

// MARK: - 部品

/// ラベル付きの入力カード。
private struct GenInputCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let required: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if required {
                    Text("必須")
                        .font(.caption2)
                        .foregroundStyle(Theme.Color.accentText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Color.accentSoft)
                        .clipShape(Capsule())
                }
            }
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(Theme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}

/// アウトライン系の二次ボタン（戻る・キャンセル等）。
private struct WizardOutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Theme.Layout.primaryButtonHeight)
                .foregroundStyle(Theme.Color.accentText)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Layout.buttonCornerRadius)
                        .stroke(Theme.Color.border, lineWidth: 1)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("1. Step1 通常") {
    PostGenerationView(viewModel: PostGenerationPreviewData.step1Filled())
}

#Preview("2. Step1 必須未入力") {
    PostGenerationView(viewModel: PostGenerationPreviewData.step1Empty())
}

#Preview("3. Step2 投稿条件") {
    PostGenerationView(viewModel: PostGenerationPreviewData.step(.conditions))
}

#Preview("4. Step3 確認") {
    PostGenerationView(viewModel: PostGenerationPreviewData.step(.confirmation))
}

#Preview("5. Step4 生成中") {
    PostGenerationView(viewModel: PostGenerationPreviewData.generating(current: 12, total: 30))
}

#Preview("6. 生成完了") {
    PostGenerationView(viewModel: PostGenerationPreviewData.completed(count: 30))
}

#Preview("7. ダークモード") {
    PostGenerationView(viewModel: PostGenerationPreviewData.step1Filled())
        .preferredColorScheme(.dark)
}

#Preview("8. 大きい文字サイズ") {
    PostGenerationView(viewModel: PostGenerationPreviewData.step1Filled())
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
