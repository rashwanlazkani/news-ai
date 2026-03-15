import type { APIGatewayProxyResult } from "aws-lambda";
import type { ApiResponse } from "../types";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Credentials": "true",
  "Content-Type": "application/json",
};

export function ok<T>(data: T, requestId?: string): APIGatewayProxyResult {
  const body: ApiResponse<T> = { success: true, data, requestId };
  return { statusCode: 200, headers: CORS_HEADERS, body: JSON.stringify(body) };
}

export function created<T>(data: T, requestId?: string): APIGatewayProxyResult {
  const body: ApiResponse<T> = { success: true, data, requestId };
  return { statusCode: 201, headers: CORS_HEADERS, body: JSON.stringify(body) };
}

export function badRequest(message: string, requestId?: string): APIGatewayProxyResult {
  const body: ApiResponse<never> = { success: false, error: message, requestId };
  return { statusCode: 400, headers: CORS_HEADERS, body: JSON.stringify(body) };
}

export function notFound(message: string, requestId?: string): APIGatewayProxyResult {
  const body: ApiResponse<never> = { success: false, error: message, requestId };
  return { statusCode: 404, headers: CORS_HEADERS, body: JSON.stringify(body) };
}

export function serverError(message: string, requestId?: string): APIGatewayProxyResult {
  const body: ApiResponse<never> = { success: false, error: message, requestId };
  return { statusCode: 500, headers: CORS_HEADERS, body: JSON.stringify(body) };
}
