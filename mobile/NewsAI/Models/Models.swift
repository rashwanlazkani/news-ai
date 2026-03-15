import Foundation

// ─── Mirror the backend TypeScript types ──────────────────────────────────────

struct ArticleSource: Decodable {
    let name: String
}

struct PersonalizedArticle: Decodable, Identifiable {
    // Identifiable by URL — guaranteed unique by the backend dedup step
    var id: String { url }

    let title: String
    let description: String?
    let url: String
    let source: ArticleSource
    let publishedAt: String
    let relevanceScore: Int
    let summary: String
    let matchedTopics: [String]

    var publishedDate: Date? {
        ISO8601DateFormatter().date(from: publishedAt)
    }
}

struct PersonalizationResult: Decodable {
    let articles: [PersonalizedArticle]
    let generatedAt: String
}

struct UserPreferences: Decodable {
    let userId: String
    let topics: [String]
    let interestDescription: String?
    let language: String?
    let maxArticles: Int?
    let updatedAt: String
}

// ─── Generic API envelope ─────────────────────────────────────────────────────

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

// ─── Topic catalogue (mirrors backend validation list) ────────────────────────

struct Topic: Identifiable, Hashable {
    let id: String
    let displayName: String
    let symbol: String
    let subInterests: [String]

    static func == (lhs: Topic, rhs: Topic) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static let all: [Topic] = [
        Topic(id: "technology",    displayName: "Technology",    symbol: "cpu",
              subInterests: ["Mobile Apps", "Web Dev", "Cloud", "Startups", "Open Source", "Cybersecurity"]),
        Topic(id: "ai",            displayName: "AI",            symbol: "brain",
              subInterests: ["LLMs", "Agents", "Computer Vision", "Robotics", "AI Coding", "MLOps"]),
        Topic(id: "finance",       displayName: "Finance",       symbol: "chart.line.uptrend.xyaxis",
              subInterests: ["Stocks", "Real Estate", "FinTech", "Personal Finance", "Venture Capital"]),
        Topic(id: "business",      displayName: "Business",      symbol: "briefcase",
              subInterests: ["Startups", "Leadership", "Marketing", "E-commerce", "Remote Work"]),
        Topic(id: "science",       displayName: "Science",       symbol: "flask",
              subInterests: ["Space", "Physics", "Biology", "Neuroscience", "Quantum"]),
        Topic(id: "health",        displayName: "Health",        symbol: "heart",
              subInterests: ["Mental Health", "Nutrition", "Fitness", "Medical Research", "Longevity"]),
        Topic(id: "sports",        displayName: "Sports",        symbol: "sportscourt",
              subInterests: ["Football", "Basketball", "F1", "MMA", "Tennis", "Olympics"]),
        Topic(id: "entertainment", displayName: "Entertainment", symbol: "tv",
              subInterests: ["Movies", "Gaming", "Music", "Streaming", "Anime"]),
        Topic(id: "politics",      displayName: "Politics",      symbol: "building.columns",
              subInterests: ["US Politics", "EU Policy", "Geopolitics", "Elections", "Regulation"]),
        Topic(id: "climate",       displayName: "Climate",       symbol: "leaf",
              subInterests: ["Renewables", "EV", "Carbon", "Biodiversity", "Climate Policy"]),
        Topic(id: "world",         displayName: "World",         symbol: "globe",
              subInterests: ["Middle East", "Asia", "Europe", "Africa", "Latin America"]),
        Topic(id: "crypto",        displayName: "Crypto",        symbol: "bitcoinsign.circle",
              subInterests: ["Bitcoin", "Ethereum", "DeFi", "NFTs", "Web3", "Regulation"]),
    ]
}
