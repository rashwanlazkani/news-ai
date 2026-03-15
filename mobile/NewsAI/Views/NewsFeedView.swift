import SwiftUI

struct NewsFeedView: View {
    @StateObject private var vm: NewsFeedViewModel
    let onEditTopics: () -> Void

    init(userId: String, onEditTopics: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: NewsFeedViewModel(userId: userId))
        self.onEditTopics = onEditTopics
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                Group {
                    if vm.isLoading && vm.articles.isEmpty {
                        loadingState
                    } else if let error = vm.errorMessage {
                        errorState(error)
                    } else if vm.articles.isEmpty {
                        emptyState
                    } else {
                        articleList
                    }
                }
            }
            .navigationTitle("Your News")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onEditTopics()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .fontWeight(.medium)
                    }
                }
            }
            .task { await vm.load() }
            .refreshable { await vm.refresh() }
        }
    }

    // ─── Sub-views ─────────────────────────────────────────────────────────────

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.articles) { article in
                    ArticleRow(article: article)
                }

                if let ts = vm.generatedAt {
                    Text("Personalized \(relativeDate(ts))")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Fetching your news…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Could not load news", systemImage: "wifi.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") { Task { await vm.load() } }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No articles yet", systemImage: "newspaper")
        } description: {
            Text("Set your topic preferences so we can personalise your feed.")
        } actions: {
            Button("Choose Topics", action: onEditTopics)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
        }
    }

    // ─── Helpers ───────────────────────────────────────────────────────────────

    private func relativeDate(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: iso) else { return iso }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: .now)
    }
}
