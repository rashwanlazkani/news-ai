import SwiftUI

struct ArticleRow: View {
    let article: PersonalizedArticle
    @State private var showSafari = false

    private var articleURL: URL? { URL(string: article.url) }

    var body: some View {
        Button {
            showSafari = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {

                // Source + relevance badge
                HStack {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                        Text(article.source.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    RelevanceBadge(score: article.relevanceScore)
                }

                // Title
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // AI-generated one-liner
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Matched topics + time
                HStack {
                    if !article.matchedTopics.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(article.matchedTopics, id: \.self) { topic in
                                Text(topic)
                                    .font(.footnote.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 0.5))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    Spacer()
                    if let date = article.publishedDate {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let url = articleURL {
                Button {
                    UIApplication.shared.open(url)
                } label: {
                    Label("Open in Safari", systemImage: "safari")
                }
                ShareLink(item: url) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .fullScreenCover(isPresented: $showSafari) {
            if let url = articleURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

// ─── Relevance score pill ─────────────────────────────────────────────────────

private struct RelevanceBadge: View {
    let score: Int

    private var color: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .gray
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "sparkles")
                .font(.caption2)
            Text("\(score)%")
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 0.5))
    }
}
