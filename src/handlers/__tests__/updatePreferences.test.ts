import type { APIGatewayProxyEvent } from "aws-lambda";
import { handler } from "../updatePreferences";

jest.mock("../../services/dynamoService", () => ({
  getPreferences: jest.fn().mockResolvedValue(null),
  putPreferences: jest.fn().mockResolvedValue(undefined),
  updatePreferences: jest.fn(),
}));

const mockEvent = (body: unknown): APIGatewayProxyEvent =>
  ({
    body: JSON.stringify(body),
    requestContext: { requestId: "test-req-id" },
    queryStringParameters: null,
    pathParameters: null,
    headers: {},
    multiValueHeaders: {},
    httpMethod: "POST",
    isBase64Encoded: false,
    path: "/preferences",
    multiValueQueryStringParameters: null,
    stageVariables: null,
    resource: "",
  }) as unknown as APIGatewayProxyEvent;

describe("POST /preferences handler", () => {
  it("returns 400 when userId is missing", async () => {
    const res = await handler(mockEvent({ topics: ["technology"] }));
    expect(res.statusCode).toBe(400);
    expect(JSON.parse(res.body).error).toContain("userId");
  });

  it("returns 400 when topics array is empty", async () => {
    const res = await handler(mockEvent({ userId: "u1", topics: [] }));
    expect(res.statusCode).toBe(400);
  });

  it("returns 400 for unknown topics", async () => {
    const res = await handler(mockEvent({ userId: "u1", topics: ["unicorns"] }));
    expect(res.statusCode).toBe(400);
    expect(JSON.parse(res.body).error).toContain("Unknown topics");
  });

  it("returns 200 and creates preferences for a new user", async () => {
    const res = await handler(
      mockEvent({ userId: "u1", topics: ["technology", "ai"] })
    );
    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.body);
    expect(body.success).toBe(true);
    expect(body.data.topics).toEqual(["technology", "ai"]);
  });
});
