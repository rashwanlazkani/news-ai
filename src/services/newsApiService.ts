import axios from "axios";
import type { NewsApiResponse, RawArticle } from "../types";

const BASE_URL = "https://newsapi.org/v2";

/**
 * Fetch top headlines for a list of topics from NewsAPI.
 * Calls are parallelised so we don't pay sequential latency per topic.
 */
export async function fetchArticlesForTopics(
  topics: string[],
  options: { language?: string; pageSize?: number; excludedSources?: string[] } = {}
): Promise<RawArticle[]> {
  const apiKey = process.env.NEWS_API_KEY;
  if (!apiKey) throw new Error("NEWS_API_KEY is not set");

  const { language = "en", pageSize = 20, excludedSources = [] } = options;

  const requests = topics.map((topic) =>
    axios.get<NewsApiResponse>(`${BASE_URL}/everything`, {
      params: {
        q: topic,
        language,
        pageSize,
        sortBy: "publishedAt",
        apiKey,
        ...(excludedSources.length > 0 && {
          excludeDomains: excludedSources.join(","),
        }),
      },
      timeout: 10_000,
    })
  );

  const responses = await Promise.allSettled(requests);

  const articles: RawArticle[] = [];
  for (const result of responses) {
    if (result.status === "fulfilled" && result.value.data.status === "ok") {
      articles.push(...result.value.data.articles);
    }
  }

  // Deduplicate by URL
  const seen = new Set<string>();
  return articles.filter((a) => {
    if (seen.has(a.url)) return false;
    seen.add(a.url);
    return true;
  });
}
