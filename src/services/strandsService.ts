import { Agent, BedrockModel } from "@strands-agents/sdk";
import type { PersonalizedArticle, RawArticle, UserPreferences } from "../types";

const SYSTEM_PROMPT = `You are a news personalization engine. Given a user's topic preferences, their specific interest description, and a list of news articles, you score each article (0-100) on relevance to the user, write a one-sentence summary, and identify which of the user's topics it matches.

When the user provides a detailed interest description, use it to score more precisely — articles that closely match their specific interests should score much higher than articles that only match the broad topic category. Tailor the summary to highlight why the article is relevant to THIS user's specific interests.

Always respond with a valid JSON array — no markdown fences, no extra text.`;

// Reuse the agent across warm Lambda invocations
let _agent: Agent | null = null;

function getAgent(): Agent {
  if (!_agent) {
    _agent = new Agent({
      model: new BedrockModel({
        modelId: "eu.anthropic.claude-sonnet-4-6",
        region: process.env.AWS_REGION ?? "eu-north-1",
        maxTokens: 4096,
      }),
      systemPrompt: SYSTEM_PROMPT,
    });
  }
  return _agent;
}

/**
 * Score, summarize, and rank raw articles against a user's preferences using Strands.
 * Returns at most `preferences.maxArticles` results, sorted by relevance.
 */
export async function personalizeArticles(
  articles: RawArticle[],
  preferences: UserPreferences
): Promise<PersonalizedArticle[]> {
  if (articles.length === 0) return [];

  const agent = getAgent();

  const articleList = articles.map((a, i) => ({
    index: i,
    title: a.title,
    description: a.description ?? "",
    source: a.source.name,
    publishedAt: a.publishedAt,
  }));

  const descriptionBlock = preferences.interestDescription?.trim()
    ? `- Specific interests: ${preferences.interestDescription}`
    : "";

  const prompt = `User preferences:
- Topics of interest: ${preferences.topics.join(", ")}
${descriptionBlock}
- Language: ${preferences.language ?? "en"}

Articles to evaluate (${articleList.length} total):
${JSON.stringify(articleList, null, 2)}

Respond with a JSON array where each element has:
{
  "index": <original index>,
  "relevanceScore": <0-100>,
  "summary": "<one sentence>",
  "matchedTopics": ["<topic>"]
}

Only include articles with relevanceScore >= 30.
Sort by relevanceScore descending.
Limit to ${preferences.maxArticles ?? 10} results.`;

  const result = await agent.invoke(prompt);

  // AgentResult.toString() extracts and concatenates all text content blocks
  let rawText = result.toString().trim();

  // Strip markdown code fences if the model wraps the JSON
  if (rawText.startsWith("```")) {
    rawText = rawText.replace(/^```(?:json)?\n?/, "").replace(/\n?```$/, "").trim();
  }

  let scored: Array<{
    index: number;
    relevanceScore: number;
    summary: string;
    matchedTopics: string[];
  }>;

  try {
    scored = JSON.parse(rawText);
  } catch {
    console.error("Strands agent returned unexpected format:", rawText);
    throw new Error("Strands agent returned an unexpected format");
  }

  return scored.map((s) => ({
    ...articles[s.index],
    relevanceScore: s.relevanceScore,
    summary: s.summary,
    matchedTopics: s.matchedTopics,
  }));
}
