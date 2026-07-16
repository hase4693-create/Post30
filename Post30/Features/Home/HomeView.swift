//
//  HomeView.swift
//  Post30
//
//  ホーム画面（デザイン案 2 準拠）。
//  挨拶／連続投稿バッジ／今月の投稿／今日の投稿／次回予定／AI生成CTA／今日のヒント を縦に配置。
//  大きな NavigationTitle は使わず、上部は挨拶から始める。
//  業務ロジックは HomeViewModel に委譲する。
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    private let onShowCalendar: () -> Void
    private let onRequestGeneration: () -> Void

    init(
        viewModel: HomeViewModel,
        onShowCalendar: @escaping () -> Void = {},
        onRequestGeneration: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onShowCalendar = onShowCalendar
        self.onRequestGeneration = onRequestGeneration
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack(path: $vm.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                    GreetingHeaderView(
                        greeting: viewModel.greeting,
                        emoji: viewModel.greetingEmoji,
                        dateText: viewModel.dateText
                    )

                    content
                }
                .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
                .padding(.top, Theme.Spacing.small)
                .padding(.bottom, Theme.Spacing.large)
            }
            .background(backgroundView)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeViewModel.Route.self) { route in
                switch route {
                case .edit(let post):
                    EditPlaceholderView(post: post)
                case .generate:
                    GeneratePlaceholderView()
                }
            }
            .overlay(alignment: .bottom) {
                if viewModel.showCopyToast {
                    copyToast
                }
            }
            .onChange(of: viewModel.showCopyToast) { _, newValue in
                guard newValue else { return }
                triggerCopyHaptic()
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    viewModel.showCopyToast = false
                }
            }
        }
    }

    // MARK: - 背景（上部に控えめな紫グラデーション）

    private var backgroundView: some View {
        Theme.Color.screenBackground
            .overlay(alignment: .top) {
                Theme.Gradient.topBackground
                    .frame(height: 220)
            }
            .ignoresSafeArea()
    }

    // MARK: - 状態別コンテンツ

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 200)

        case .empty:
            EmptyStateView(onCreate: { onRequestGeneration() })

        case .error(let message):
            errorView(message)

        case .content(let content):
            PostingStreakBadge(days: viewModel.postingStreakDays)

            ProgressSummaryCard(
                planTitle: viewModel.planTitle ?? "",
                publishedCount: viewModel.publishedCount,
                totalPostCount: viewModel.totalPostCount,
                unpublishedCount: viewModel.unpublishedCount,
                progressRate: viewModel.publishedProgressRate
            )

            todaySection(content)

            if let next = content.nextPost, content.todayPost != nil {
                // 今日の投稿がある場合でも、次回予定を簡潔に表示。
                nextSection(next, title: "次回の投稿", showBody: false)
            }

            PrimaryButton(
                title: "AIで30日分の投稿を作成",
                leadingSystemImage: "sparkles",
                trailingSystemImage: "chevron.right",
                fill: .gradient
            ) {
                onRequestGeneration()
            }

            DailyTipCard(text: viewModel.dailyTip)
        }
    }

    // MARK: - 今日の投稿セクション

    @ViewBuilder
    private func todaySection(_ content: HomeContent) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                Text("今日の投稿")
                    .font(.headline)
                Spacer()
                Button {
                    onShowCalendar()
                } label: {
                    Text("カレンダーを見る")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Color.accentText)
                }
                .accessibilityHint("カレンダータブへ移動します")
            }

            if let today = content.todayPost {
                TodayPostCard(
                    post: today,
                    dateText: viewModel.scheduledDateText(for: today),
                    onCopy: { viewModel.copy(today) },
                    onEdit: { viewModel.requestEdit(today) },
                    onMarkPublished: { viewModel.markAsPublished(today) }
                )
            } else if let next = content.nextPost {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text("今日は投稿予定がありません")
                        .foregroundStyle(.secondary)
                    Text("次回の投稿はこちら")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Color.accentText)
                    NextPostCard(
                        post: next,
                        dateText: viewModel.scheduledDateText(for: next),
                        showBody: true,
                        onTap: { viewModel.requestEdit(next) }
                    )
                }
            } else {
                Text("今日は投稿予定がありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - 次回予定セクション（今日ありの場合の簡潔表示）

    private func nextSection(_ post: Post, title: String, showBody: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(title)
                .font(.headline)
            NextPostCard(
                post: post,
                dateText: viewModel.scheduledDateText(for: post),
                showBody: showBody,
                onTap: { viewModel.requestEdit(post) }
            )
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("読み込みに失敗しました", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("再試行") { viewModel.reload() }
        }
    }

    // MARK: - コピー通知

    private var copyToast: some View {
        Text("コピーしました")
            .font(.subheadline)
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.small)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, Theme.Spacing.large)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityAddTraits(.isStaticText)
    }

    private func triggerCopyHaptic() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
}

// MARK: - 最小プレースホルダ（編集・生成）

/// 投稿編集のプレースホルダ。対象 Post を受け取れる構造だけ用意する（本格実装は Phase 4）。
private struct EditPlaceholderView: View {
    let post: Post

    var body: some View {
        ContentUnavailableView(
            "投稿の編集",
            systemImage: "pencil",
            description: Text("編集画面は今後のフェーズで実装します。")
        )
        .navigationTitle("編集")
    }
}

/// 30日分生成のプレースホルダ（本格実装は Phase 5）。
private struct GeneratePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "30日分の投稿を作成",
            systemImage: "sparkles",
            description: Text("生成機能は今後のフェーズで実装します。")
        )
        .navigationTitle("AIで30日分の投稿を作成")
    }
}

// MARK: - Previews（Preview 専用データを使用）

#if DEBUG
#Preview("1. 今日の投稿あり") {
    RootTabViewPreviewWrapper(viewModel: HomePreviewData.viewModelWithTodayPost())
}

#Preview("2. 今日なし・次回あり") {
    RootTabViewPreviewWrapper(viewModel: HomePreviewData.viewModelWithNextPostOnly())
}

#Preview("3. 計画なし") {
    RootTabViewPreviewWrapper(viewModel: HomePreviewData.viewModelWithNoPlan())
}

#Preview("4. 投稿0件") {
    RootTabViewPreviewWrapper(viewModel: HomePreviewData.viewModelWithZeroPosts())
}

#Preview("5. ダークモード") {
    RootTabViewPreviewWrapper(viewModel: HomePreviewData.viewModelWithTodayPost())
        .preferredColorScheme(.dark)
}

#Preview("6. 大きい文字サイズ") {
    RootTabViewPreviewWrapper(viewModel: HomePreviewData.viewModelWithTodayPost())
        .environment(\.dynamicTypeSize, .accessibility3)
}

/// Preview で HomeView を単体表示するためのラッパー。
private struct RootTabViewPreviewWrapper: View {
    let viewModel: HomeViewModel
    var body: some View {
        HomeView(viewModel: viewModel)
    }
}
#endif
