# NewsAI

AI-powered personalized news app built with AWS serverless services and a native iOS client. Uses the **Strands Agents SDK** with Claude on Amazon Bedrock to score, summarize, and rank news articles based on your specific interests.

## Monorepo Structure

```
news-ai/
├── src/                   # Backend (TypeScript / AWS Lambda)
│   ├── handlers/          # Lambda function handlers
│   │   ├── getNews.ts
│   │   └── updatePreferences.ts
│   ├── services/          # Business logic
│   │   ├── dynamoService.ts      # DynamoDB operations
│   │   ├── newsApiService.ts     # NewsAPI integration
│   │   └── strandsService.ts     # AI personalization (Strands + Bedrock)
│   ├── types/             # Shared TypeScript types
│   └── utils/             # HTTP response helpers
│
├── mobile/                # iOS app (SwiftUI)
│   ├── project.yml        # XcodeGen project definition
│   └── NewsAI/
│       ├── Models/        # Data models & topic catalog
│       ├── Views/         # SwiftUI views
│       ├── ViewModels/    # Observable view models
│       └── Services/      # API client
│
├── serverless.yml         # Infrastructure as Code (AWS)
├── package.json
└── tsconfig.json
```

## Architecture

```
iOS App (SwiftUI)
    │
    ▼
API Gateway (REST)
    ├── GET /news ──→ Lambda ──→ DynamoDB (read prefs)
    │                        ──→ NewsAPI (fetch articles)
    │                        ──→ Strands Agent / Claude on Bedrock
    │                             (score + summarize + rank)
    │
    └── POST /preferences ──→ Lambda ──→ DynamoDB (write prefs)
```

**AWS services used:** Lambda, API Gateway, DynamoDB, Bedrock, IAM

## Backend

The backend is a serverless Node.js (TypeScript) application deployed with Serverless Framework v3.

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/news?userId=<id>` | Fetch personalized news for a user |
| `POST` | `/preferences` | Create or update user topic preferences |

### How Personalization Works

1. User preferences (topics + sub-interests) are loaded from DynamoDB
2. Raw articles are fetched from NewsAPI in parallel for each topic
3. Articles are sent to a **Strands Agent** powered by Claude on Amazon Bedrock
4. Claude scores each article (0–100) on relevance, writes a summary, and tags matched topics
5. Results are filtered (score >= 30), sorted, and returned

### Key Dependencies

- `@strands-agents/sdk` — AI agent framework with native Bedrock support
- `@aws-sdk/client-dynamodb` + `@aws-sdk/lib-dynamodb` — DynamoDB access
- `axios` — HTTP client for NewsAPI
- `zod` — Request validation
- `serverless` + `serverless-esbuild` — Build & deploy

## Mobile App (iOS)

Native SwiftUI app targeting iOS 17+. Uses XcodeGen for project generation.

### Features

- Topic picker with 12 categories and sub-interest chips for deeper personalization
- AI-personalized news feed with relevance scores and summaries
- In-app article reading via SFSafariViewController
- Glass morphism UI with `.ultraThinMaterial`
- Dark mode support
- Local persistence with UserDefaults

### Views

| View | Purpose |
|------|---------|
| `RootView` | Navigation — first-launch topic picker vs. news feed |
| `TopicPickerView` | Topic grid + sub-interest chip selection |
| `NewsFeedView` | Scrollable feed of personalized articles |
| `ArticleRow` | Article card with score, summary, and topic tags |
| `SafariView` | In-app browser wrapper |

## Getting Started

### Prerequisites

- Node.js 20+
- AWS CLI configured with credentials
- [Serverless Framework v3](https://www.serverless.com/)
- A [NewsAPI](https://newsapi.org/) API key
- Amazon Bedrock access with Claude enabled (submit the use case form once per account)
- Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for the iOS app)

### Backend Setup

```bash
# Install dependencies
npm install

# Create .env from the example
cp .env.example .env
# Edit .env and add your NEWS_API_KEY

# Run locally
npm run offline
# API available at http://localhost:3000

# Deploy to AWS (dev stage)
npm run deploy

# Deploy to production
npm run deploy:prod
```

### iOS App Setup

```bash
cd mobile

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open NewsAI.xcodeproj
```

The API base URL is configured in `mobile/NewsAI/Info.plist` under `API_BASE_URL`. It defaults to the deployed API Gateway URL. For local development, change it to `http://localhost:3000`.

### Environment Variables

| Variable | Description |
|----------|-------------|
| `NEWS_API_KEY` | API key from newsapi.org |
| `PREFERENCES_TABLE` | DynamoDB table name (auto-set by Serverless) |
| `AWS_REGION` | AWS region (default: `eu-north-1`) |

### Running Tests

```bash
npm test              # Run all tests
npm run test:watch    # Watch mode
npm run lint          # Lint check
```

## Teardown

```bash
npm run remove    # Removes all AWS resources (Lambda, API Gateway, DynamoDB)
```
