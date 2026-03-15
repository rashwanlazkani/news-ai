import Foundation

/// Thin async/await wrapper around the news-ai Lambda API.
/// Swap `baseURL` for your API Gateway URL after `sls deploy`.
actor APIClient {
    static let shared = APIClient()

    // ── Configuration ─────────────────────────────────────────────────────────
    // Dev:  http://localhost:3000  (serverless-offline)
    // Prod: your API Gateway invoke URL, e.g. https://abc123.execute-api.eu-north-1.amazonaws.com/dev
    private let baseURL: URL = {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
            ?? "http://localhost:3000"
        guard let url = URL(string: urlString) else {
            fatalError("API_BASE_URL is not a valid URL")
        }
        return url
    }()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    private let decoder = JSONDecoder()

    // ── Endpoints ─────────────────────────────────────────────────────────────

    func fetchNews(userId: String) async throws -> PersonalizationResult {
        var components = URLComponents(url: baseURL.appendingPathComponent("news"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "userId", value: userId)]

        let (data, response) = try await session.data(from: components.url!)
        try assertHTTP200(response)

        let envelope = try decoder.decode(APIResponse<PersonalizationResult>.self, from: data)
        guard let result = envelope.data else {
            throw APIError.serverError(envelope.error ?? "Unknown error")
        }
        return result
    }

    func updatePreferences(userId: String, topics: [String], interestDescription: String = "", maxArticles: Int = 10) async throws -> UserPreferences {
        let url = baseURL.appendingPathComponent("preferences")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = [
            "userId": userId,
            "topics": topics,
            "maxArticles": maxArticles,
        ]
        if !interestDescription.isEmpty {
            body["interestDescription"] = interestDescription
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try assertHTTP200(response)

        let envelope = try decoder.decode(APIResponse<UserPreferences>.self, from: data)
        guard let prefs = envelope.data else {
            throw APIError.serverError(envelope.error ?? "Unknown error")
        }
        return prefs
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func assertHTTP200(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }
    }
}

enum APIError: LocalizedError {
    case httpError(Int)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "Server returned HTTP \(code)"
        case .serverError(let msg): return msg
        }
    }
}
