import type { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { getPreferences } from "../services/dynamoService";
import { fetchArticlesForTopics } from "../services/newsApiService";
import { personalizeArticles } from "../services/strandsService";
import type { GetNewsQueryParams, PersonalizationResult } from "../types";
import { badRequest, notFound, ok, serverError } from "../utils/response";

export async function handler(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  const requestId = event.requestContext?.requestId;

  try {
    const { userId } = (event.queryStringParameters ?? {}) as GetNewsQueryParams;

    if (!userId?.trim()) {
      return badRequest("userId query parameter is required", requestId);
    }

    console.log("getNews called with userId:", userId);

    // 1. Load user preferences from DynamoDB
    const preferences = await getPreferences(userId);
    if (!preferences) {
      console.log("No preferences found for userId:", userId);
      return notFound(
        `No preferences found for userId "${userId}". POST /preferences first.`,
        requestId
      );
    }

    if (preferences.topics.length === 0) {
      return badRequest("User has no topics configured", requestId);
    }

    // 2. Fetch raw articles from NewsAPI for all topics in parallel
    const rawArticles = await fetchArticlesForTopics(preferences.topics, {
      language: preferences.language,
      pageSize: Math.min((preferences.maxArticles ?? 10) * 3, 100), // over-fetch so the AI has room to filter
      excludedSources: preferences.excludedSources,
    });

    if (rawArticles.length === 0) {
      return ok<PersonalizationResult>(
        { articles: [], generatedAt: new Date().toISOString() },
        requestId
      );
    }

    // 3. Personalise with Strands / Claude
    const personalizedArticles = await personalizeArticles(rawArticles, preferences);

    const result: PersonalizationResult = {
      articles: personalizedArticles,
      generatedAt: new Date().toISOString(),
    };

    return ok(result, requestId);
  } catch (err) {
    console.error("getNews error:", err);
    return serverError("An unexpected error occurred", requestId);
  }
}
