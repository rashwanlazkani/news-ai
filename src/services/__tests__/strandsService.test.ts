import { personalizeArticles } from "../strandsService";
import type { RawArticle, UserPreferences } from "../../types";

jest.mock("@strands-agents/sdk", () => {
  const mockInvoke = jest.fn().mockResolvedValue({
    lastMessage: {
      content: [
        {
          type: "text",
          text: JSON.stringify([
            {
              index: 0,
              relevanceScore: 90,
              summary: "A major AI breakthrough in language models.",
              matchedTopics: ["technology", "ai"],
            },
          ]),
        },
      ],
    },
  });

  return {
    Agent: jest.fn().mockImplementation(() => ({
      invoke: mockInvoke,
    })),
    BedrockModel: jest.fn(),
  };
});

const MOCK_ARTICLES: RawArticle[] = [
  {
    title: "OpenAI releases new model",
    description: "A new frontier model was released",
    url: "https://example.com/article-1",
    source: { name: "TechCrunch" },
    publishedAt: "2026-03-14T10:00:00Z",
    content: null,
  },
];

const MOCK_PREFS: UserPreferences = {
  userId: "user-123",
  topics: ["technology", "ai"],
  language: "en",
  maxArticles: 5,
  updatedAt: new Date().toISOString(),
};

describe("personalizeArticles", () => {
  beforeEach(() => {
    process.env.AWS_REGION = "eu-north-1";
  });

  it("returns personalised articles with scores and summaries", async () => {
    const result = await personalizeArticles(MOCK_ARTICLES, MOCK_PREFS);

    expect(result).toHaveLength(1);
    expect(result[0].relevanceScore).toBe(90);
    expect(result[0].summary).toBe("A major AI breakthrough in language models.");
    expect(result[0].matchedTopics).toEqual(["technology", "ai"]);
    expect(result[0].url).toBe(MOCK_ARTICLES[0].url);
  });

  it("returns empty array when given no articles", async () => {
    const result = await personalizeArticles([], MOCK_PREFS);
    expect(result).toHaveLength(0);
  });
});
