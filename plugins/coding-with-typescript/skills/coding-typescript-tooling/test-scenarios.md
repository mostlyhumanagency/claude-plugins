# Coding TypeScript Test Scenarios

Three scenarios testing paradigm selection and modern TypeScript patterns.

## Table of Contents

- [Scenario 1: Paradigm-Agnostic (Agent Decides)](#scenario-1-paradigm-agnostic-agent-decides)
- [Scenario 2: Functional Programming Approach](#scenario-2-functional-programming-approach)
- [Scenario 3: Protocol-Oriented Approach](#scenario-3-protocol-oriented-approach)
- [Testing Instructions](#testing-instructions)
- [Expected Outputs](#expected-outputs)

## Scenario 1: Paradigm-Agnostic (Agent Decides)

**Task:** Implement a configuration manager that loads, validates, and provides typed access to application settings.

**Requirements:**
- Load config from JSON file
- Validate required fields exist
- Provide type-safe access to settings
- Support default values
- Handle missing/invalid config gracefully
- Use TypeScript 5.5+ features

**Input Example:**
```json
{
  "api": {
    "baseUrl": "https://api.example.com",
    "timeout": 5000,
    "retries": 3
  },
  "features": {
    "enableAnalytics": true,
    "enableCache": false
  }
}
```

**Expected Interface:**
```typescript
interface Config {
  readonly api: {
    readonly baseUrl: string;
    readonly timeout: number;
    readonly retries: number;
  };
  readonly features: {
    readonly enableAnalytics: boolean;
    readonly enableCache: boolean;
  };
}

// Usage
const config = await loadConfig("./config.json");
if (config.ok) {
  console.log(config.value.api.baseUrl);
}
```

**Success Criteria:**
- Immutable config types
- Runtime validation
- Type-safe access
- Error handling with Result type
- No `any` types
- Uses modern TS features (5.5+)

---

## Scenario 2: Functional Programming Approach

**Task:** Implement a data transformation pipeline for processing financial transactions.

**Requirements:**
- Parse CSV transaction data
- Validate each transaction (amount > 0, valid date, category exists)
- Calculate running balance
- Group by category
- Generate summary statistics (total, average, count per category)
- All transformations must be pure functions
- Use function composition
- Immutable data structures throughout

**Input Example:**
```csv
date,description,amount,category
2024-01-01,Groceries,-50.00,food
2024-01-02,Salary,3000.00,income
2024-01-03,Rent,-1200.00,housing
```

**Expected Types:**
```typescript
interface Transaction {
  readonly date: Date;
  readonly description: string;
  readonly amount: number;
  readonly category: Category;
}

type Category = "food" | "income" | "housing" | "transport" | "entertainment";

interface CategorySummary {
  readonly category: Category;
  readonly total: number;
  readonly average: number;
  readonly count: number;
}

interface TransactionReport {
  readonly transactions: readonly Transaction[];
  readonly finalBalance: number;
  readonly summaries: readonly CategorySummary[];
}
```

**Success Criteria:**
- Pure functions only (no side effects in business logic)
- Function composition (pipe/compose)
- Immutable operations (no .push, .sort(), etc)
- ADTs (Option/Result) for error handling
- Separate pure core from I/O shell
- Type-safe transformations
- Uses iterator helpers if applicable (5.6+)

---

## Scenario 3: Protocol-Oriented Approach

**Task:** Implement a multi-backend notification system that can send notifications via email, SMS, and push notifications.

**Requirements:**
- Define protocols for notification channels
- Support multiple backends per channel type (e.g., SendGrid + AWS SES for email)
- Implement retry logic as a protocol extension
- Support rate limiting as a composable capability
- Logging as a cross-cutting concern
- Easy to add new channels without modifying existing code
- Type-safe dependency injection

**Expected Protocols:**
```typescript
interface NotificationChannel {
  send(notification: Notification): Promise<Result<void>>;
}

interface RateLimited {
  readonly limit: number;
  readonly window: number; // ms
}

interface Retriable {
  readonly maxAttempts: number;
  readonly backoff: number; // ms
}

interface Loggable {
  log(message: string): void;
}

type Notification = EmailNotification | SMSNotification | PushNotification;

interface EmailNotification {
  readonly type: "email";
  readonly to: string;
  readonly subject: string;
  readonly body: string;
}

interface SMSNotification {
  readonly type: "sms";
  readonly to: string;
  readonly message: string;
}

interface PushNotification {
  readonly type: "push";
  readonly deviceToken: string;
  readonly title: string;
  readonly body: string;
}
```

**Expected Usage:**
```typescript
// Compose capabilities
type EmailChannel = NotificationChannel & Retriable & Loggable;

// Multiple implementations
class SendGridEmailChannel implements EmailChannel { }
class AWSEmailChannel implements EmailChannel { }
class TwilioSMSChannel implements NotificationChannel & RateLimited { }

// Protocol-based orchestrator
class NotificationService {
  constructor(
    private emailChannel: NotificationChannel,
    private smsChannel: NotificationChannel,
    private pushChannel: NotificationChannel
  ) {}

  async send(notification: Notification): Promise<Result<void>> {
    switch (notification.type) {
      case "email": return this.emailChannel.send(notification);
      case "sms": return this.smsChannel.send(notification);
      case "push": return this.pushChannel.send(notification);
    }
  }
}
```

**Success Criteria:**
- Small, focused interfaces (SRP)
- Interface composition with `&`
- Multiple implementations per protocol
- Generic constraints for type safety
- Dependency injection via protocols
- Easy to extend (add new channel = implement interface)
- No concrete type dependencies
- Immutable notification types
- Uses discriminated unions for notification types

---

## Testing Instructions

For each scenario:

1. **Invoke coding-typescript agent** with the scenario
2. **Verify paradigm selection:**
   - Scenario 1: Should choose based on problem characteristics
   - Scenario 2: Should recognize FP requirements and use functional patterns
   - Scenario 3: Should recognize extensibility needs and use POP patterns
3. **Check language features:**
   - All scenarios use TS 5.5+ features appropriately
   - Immutability enforced (`readonly`)
   - No `any` types
   - Type-safe throughout
4. **Verify code quality:**
   - Follows skill patterns
   - Clean, idiomatic TypeScript
   - Proper error handling
   - Well-structured and maintainable

## Expected Outputs

**Scenario 1:** Could use simple class-based approach, or functional composition, or protocol-based - agent decides based on simplicity.

**Scenario 2:** Must use functional patterns - pure functions, function composition, immutable data, ADTs.

**Scenario 3:** Must use protocol-oriented patterns - small interfaces, composition, dependency injection, generic constraints.

All three must demonstrate mastery of modern TypeScript (5.5+) and clean, idiomatic code.
