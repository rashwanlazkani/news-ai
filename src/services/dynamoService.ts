import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  PutCommand,
  UpdateCommand,
} from "@aws-sdk/lib-dynamodb";
import type { UserPreferences } from "../types";

const client = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(client, {
  marshallOptions: { removeUndefinedValues: true },
});

const TABLE = process.env.PREFERENCES_TABLE!;

export async function getPreferences(userId: string): Promise<UserPreferences | null> {
  const { Item } = await ddb.send(
    new GetCommand({ TableName: TABLE, Key: { userId } })
  );
  return (Item as UserPreferences) ?? null;
}

export async function putPreferences(prefs: UserPreferences): Promise<void> {
  await ddb.send(new PutCommand({ TableName: TABLE, Item: prefs }));
}

export async function updatePreferences(
  userId: string,
  updates: Partial<Omit<UserPreferences, "userId">>
): Promise<UserPreferences> {
  const now = new Date().toISOString();
  const entries = Object.entries({ ...updates, updatedAt: now });

  const ExpressionAttributeNames: Record<string, string> = {};
  const ExpressionAttributeValues: Record<string, unknown> = {};
  const setParts: string[] = [];

  for (const [k, v] of entries) {
    const nameToken = `#${k}`;
    const valToken = `:${k}`;
    ExpressionAttributeNames[nameToken] = k;
    ExpressionAttributeValues[valToken] = v;
    setParts.push(`${nameToken} = ${valToken}`);
  }

  const { Attributes } = await ddb.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { userId },
      UpdateExpression: `SET ${setParts.join(", ")}`,
      ExpressionAttributeNames,
      ExpressionAttributeValues,
      ReturnValues: "ALL_NEW",
    })
  );

  return Attributes as UserPreferences;
}
