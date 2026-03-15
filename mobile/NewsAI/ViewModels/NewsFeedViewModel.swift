import SwiftUI

@MainActor
final class NewsFeedViewModel: ObservableObject {
    @Published var articles: [PersonalizedArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var generatedAt: String?

    private let userId: String

    init(userId: String) {
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await APIClient.shared.fetchNews(userId: userId)
            articles = result.articles
            generatedAt = result.generatedAt
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        await load()
    }
}
