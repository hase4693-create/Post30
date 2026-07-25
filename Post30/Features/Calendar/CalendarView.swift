//
//  CalendarView.swift
//  Post30
//
//  月間カレンダー画面。日付ごとの投稿有無・状態を表示し、選択日の投稿一覧から
//  既存の投稿編集画面へ遷移する。永続化は既存 PersistenceStore / 編集画面を再利用。
//

import SwiftUI

struct CalendarView: View {
    @State private var viewModel: CalendarViewModel
    @State private var path: [Post] = []
    private let store: PersistenceStore?

    init(viewModel: CalendarViewModel, store: PersistenceStore? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.store = store
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                    CalendarMonthHeader(
                        title: viewModel.monthTitle,
                        onPrevious: { viewModel.goToPreviousMonth() },
                        onNext: { viewModel.goToNextMonth() }
                    )

                    weekdayHeader

                    monthGrid

                    Divider()

                    DailyPostListView(
                        title: "\(viewModel.selectedDateTitle)の投稿",
                        posts: viewModel.selectedDatePosts,
                        dateText: { viewModel.dateText(for: $0) },
                        onSelect: { path.append($0) }
                    )
                }
                .padding(.horizontal, Theme.Layout.screenHorizontalPadding)
                .padding(.vertical, Theme.Spacing.medium)
            }
            .background(Theme.Color.screenBackground.ignoresSafeArea())
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("今日") {
                        viewModel.selectToday()
                    }
                    .disabled(viewModel.isViewingToday)
                    .accessibilityLabel("今日へ戻る")
                    .accessibilityHint("現在の月を表示し、今日の日付を選択します")
                }
            }
            .navigationDestination(for: Post.self) { post in
                PostEditorView(viewModel: PostEditorViewModel(post: post, store: store))
            }
        }
    }

    // MARK: - 曜日見出し

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - 月グリッド

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.days) { day in
                CalendarDayCell(
                    dayNumber: viewModel.dayNumber(day.date),
                    isInMonth: day.isInDisplayedMonth,
                    isToday: viewModel.isToday(day.date),
                    isSelected: viewModel.isSelected(day.date),
                    status: viewModel.dayStatus(for: day.date),
                    count: viewModel.postCount(on: day.date),
                    accessibilityLabel: viewModel.accessibilityLabel(for: day.date)
                )
                .onTapGesture { viewModel.select(day.date) }
            }
        }
    }
}

#if DEBUG
#Preview("複数の投稿日がある月") {
    CalendarView(viewModel: CalendarPreviewData.monthWithPosts())
        .previewPersistence()
}

#Preview("投稿がない月") {
    CalendarView(viewModel: CalendarPreviewData.emptyMonth())
        .previewPersistence()
}

#Preview("選択日に投稿がない") {
    CalendarView(viewModel: CalendarPreviewData.selectedWithoutPosts())
        .previewPersistence()
}

#Preview("選択日が混在") {
    CalendarView(viewModel: CalendarPreviewData.selectedMixed())
        .previewPersistence()
}

#Preview("ダークモード") {
    CalendarView(viewModel: CalendarPreviewData.monthWithPosts())
        .preferredColorScheme(.dark)
        .previewPersistence()
}

#Preview("大きい文字サイズ") {
    CalendarView(viewModel: CalendarPreviewData.monthWithPosts())
        .environment(\.dynamicTypeSize, .accessibility3)
        .previewPersistence()
}
#endif
