// ─── Domain types ──────────────────────────────────────────────────────────────

export interface UserPreferences {
  userId: string;
  topics: string[];              // e.g. ["technology", "finance", "climate"]
  interestDescription?: string;  // free-text: "I care about LLMs, agent frameworks, not image gen"
  excludedSources?: string[];    // e.g. ["tabloid.com"]
  language?: string;             // ISO 639-1, default "en"
  maxArticles?: number;          // default 10
  updatedAt: string;             // ISO 8601
}

export interface RawArticle {
  title: string;
  description: string | null;
  url: string;
  source: { name: string };
  publishedAt: string;
  content: string | null;
}

export interface PersonalizedArticle extends RawArticle {
  relevanceScore: number;     // 0-100 computed by the AI layer
  summary: string;            // AI-generated one-liner
  matchedTopics: string[];    // which of the user's topics triggered this
}

// ─── Request / response bodies ─────────────────────────────────────────────────

export interface UpdatePreferencesBody {
  userId: string;
  topics: string[];
  interestDescription?: string;
  excludedSources?: string[];
  language?: string;
  maxArticles?: number;
}

export interface GetNewsQueryParams {
  userId: string;
  page?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  requestId?: string;
}

// ─── Internal service interfaces ───────────────────────────────────────────────

export interface NewsApiResponse {
  status: string;
  totalResults: number;
  articles: RawArticle[];
}

export interface PersonalizationResult {
  articles: PersonalizedArticle[];
  generatedAt: string;
}
