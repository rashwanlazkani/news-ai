import type { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { getPreferences, putPreferences, updatePreferences } from "../services/dynamoService";
import type { UpdatePreferencesBody, UserPreferences } from "../types";
import { badRequest, ok, serverError } from "../utils/response";

const VALID_TOPICS = new Set([
  "technology", "finance", "business", "science", "health", "sports",
  "entertainment", "politics", "climate", "ai", "crypto", "world",
]);

function validate(body: Partial<UpdatePreferencesBody>): string | null {
  if (!body.userId?.trim()) return "userId is required";
  if (!Array.isArray(body.topics) || body.topics.length === 0)
    return "topics must be a non-empty array";

  const invalidTopics = body.topics.filter((t) => !VALID_TOPICS.has(t));
  if (invalidTopics.length > 0)
    return `Unknown topics: ${invalidTopics.join(", ")}. Valid: ${[...VALID_TOPICS].join(", ")}`;

  if (body.maxArticles !== undefined && (body.maxArticles < 1 || body.maxArticles > 50))
    return "maxArticles must be between 1 and 50";

  return null;
}

export async function handler(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  const requestId = event.requestContext?.requestId;

  try {
    if (!event.body) return badRequest("Request body is required", requestId);

    let parsed: Partial<UpdatePreferencesBody>;
    try {
      parsed = JSON.parse(event.body) as Partial<UpdatePreferencesBody>;
    } catch {
      return badRequest("Invalid JSON body", requestId);
    }

    const validationError = validate(parsed);
    if (validationError) return badRequest(validationError, requestId);

    const body = parsed as UpdatePreferencesBody;
    const existing = await getPreferences(body.userId);

    let preferences: UserPreferences;

    if (!existing) {
      // First time — create a full record
      preferences = {
        userId: body.userId,
        topics: body.topics,
        interestDescription: body.interestDescription ?? "",
        excludedSources: body.excludedSources ?? [],
        language: body.language ?? "en",
        maxArticles: body.maxArticles ?? 10,
        updatedAt: new Date().toISOString(),
      };
      await putPreferences(preferences);
    } else {
      // Subsequent updates — only patch provided fields
      preferences = await updatePreferences(body.userId, {
        topics: body.topics,
        ...(body.interestDescription !== undefined && {
          interestDescription: body.interestDescription,
        }),
        ...(body.excludedSources !== undefined && {
          excludedSources: body.excludedSources,
        }),
        ...(body.language !== undefined && { language: body.language }),
        ...(body.maxArticles !== undefined && { maxArticles: body.maxArticles }),
      });
    }

    return ok(preferences, requestId);
  } catch (err) {
    console.error("updatePreferences error:", err);
    return serverError("An unexpected error occurred", requestId);
  }
}
