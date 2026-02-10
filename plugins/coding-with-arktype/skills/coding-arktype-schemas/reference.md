# ArkType Keywords Reference

## String Keywords

| Keyword | Description |
|---|---|
| `string` | Any string |
| `string.alpha` | Alphabetic only |
| `string.alphanumeric` | Alphanumeric only |
| `string.creditCard` | Credit card number |
| `string.date` | Parseable date string |
| `string.date.iso` | ISO 8601 date |
| `string.date.epoch` | Epoch timestamp string |
| `string.digits` | Digit characters only |
| `string.email` | Email address |
| `string.hex` | Hexadecimal string |
| `string.integer` | Integer string |
| `string.ip` | IPv4 or IPv6 |
| `string.ip.v4` | IPv4 address |
| `string.ip.v6` | IPv6 address |
| `string.json` | Valid JSON string |
| `string.numeric` | Numeric string |
| `string.semver` | Semantic version |
| `string.url` | URL string |
| `string.uuid` | UUID (any version) |
| `string.uuid.v4` | UUID v4 |
| `string.uuid.v7` | UUID v7 |
| `string.base64` | Base64 encoded |
| `string.base64.url` | URL-safe base64 |

### String Transform Morphs

| Keyword | Effect |
|---|---|
| `string.trim` | Trim whitespace |
| `string.lower` | To lowercase |
| `string.upper` | To uppercase |
| `string.capitalize` | Capitalize first |
| `string.normalize.NFC` | Unicode NFC |
| `string.normalize.NFD` | Unicode NFD |
| `string.normalize.NFKC` | Unicode NFKC |
| `string.normalize.NFKD` | Unicode NFKD |

### String Parse Morphs

| Keyword | Input → Output |
|---|---|
| `string.numeric.parse` | numeric string → `number` |
| `string.integer.parse` | integer string → `number` |
| `string.json.parse` | JSON string → `object` |
| `string.date.parse` | date string → `Date` |
| `string.date.iso.parse` | ISO date → `Date` |
| `string.date.epoch.parse` | epoch string → `Date` |
| `string.url.parse` | URL string → `URL` |

### String Constraints (length)

```typescript
"string > 0"            // length > 0
"string >= 3"           // length >= 3
"string < 100"          // length < 100
"string <= 255"         // length <= 255
"3 <= string < 100"     // range
```

### String Pattern (regex)

```typescript
"string & /^[a-z]+$/"   // intersection with regex
"/^\\d{3}-\\d{4}$/"     // standalone regex pattern
```

## Number Keywords

| Keyword | Description |
|---|---|
| `number` | Any number (excludes NaN) |
| `number.integer` | Integer |
| `number.safe` | Safe integer range |
| `number.epoch` | Unix epoch timestamp |
| `number.Infinity` | Positive infinity |
| `number.NegativeInfinity` | Negative infinity |
| `number.NaN` | NaN value |

### Number Constraints

```typescript
"number > 0"                  // positive
"number >= 0"                 // non-negative
"number < 100"                // less than
"number <= 100"               // at most
"0 < number <= 100"           // range
"number % 2"                  // divisible by 2
"-50 < (number % 2) < 50"    // combined divisor + range
```

## Other Primitives

| Keyword | Description |
|---|---|
| `bigint` | Any bigint |
| `symbol` | Any symbol |
| `boolean` | `true \| false` |
| `true` | Literal true |
| `false` | Literal false |
| `null` | Null |
| `undefined` | Undefined |
| `unknown` | Any value |
| `never` | No value |
| `Date` | Date instance |

### Literals

```typescript
"'hello'"          // string literal
"42"               // number literal (in string syntax)
"1337n"            // bigint literal
"true"             // boolean literal
"null"             // null literal
```

## Object Syntax

| Syntax | Meaning |
|---|---|
| `key: "type"` | Required property |
| `"key?": "type"` | Optional property |
| `key: "type = value"` | Defaultable property |
| `"[string]": "type"` | String index signature |
| `"[symbol]": "type"` | Symbol index signature |
| `"+": "reject"` | Reject undeclared keys |
| `"+": "delete"` | Strip undeclared keys |
| `"+": "ignore"` | Allow undeclared keys (default) |
| `"...": OtherType` | Spread/merge another type |

## Array Syntax

| Syntax | Meaning |
|---|---|
| `"type[]"` | Array of type |
| `"type[] > 0"` | Non-empty array |
| `"type[] >= N"` | Min length N |
| `"type[] <= N"` | Max length N |
| `"N < type[] <= M"` | Length range |

## Tuple Syntax

```typescript
["string", "number"]                    // [string, number]
["string", "boolean = false"]           // defaultable element
["string", "number?"]                   // optional element
["string", "...", "number[]"]           // variadic
["...", "number[]", "boolean"]          // postfix after variadic
```

## Type API Quick Reference

| Method | Description |
|---|---|
| `Type(data)` | Validate → data or ArkErrors |
| `Type.assert(data)` | Validate → data or throw |
| `Type.allows(data)` | Boolean check, no morphs |
| `Type.from(data)` | Typed alias for assert |
| `Type.infer` | Output TS type (inference only) |
| `Type.inferIn` | Input TS type (inference only) |
| `Type.array()` | Array of this type |
| `Type.optional()` | Make optional |
| `Type.default(val)` | Add default value |
| `Type.and(...)` | Intersection |
| `Type.or(...)` | Union |
| `Type.pipe(...)` | Transform chain |
| `Type.to(def)` | Pipe to type (sugar) |
| `Type.narrow(pred)` | Custom validation |
| `Type.filter(pred)` | Validate input (pre-morph) |
| `Type.brand(name)` | Compile-time brand |
| `Type.pick(...)` | Pick keys |
| `Type.omit(...)` | Omit keys |
| `Type.partial()` | All optional |
| `Type.required()` | All required |
| `Type.merge({...})` | Merge objects |
| `Type.keyof()` | Key union |
| `Type.get(k, ...)` | Extract property type |
| `Type.extends(def)` | Subtype check |
| `Type.equals(other)` | Identity check |
| `Type.overlaps(other)` | Overlap check |
| `Type.extract(def)` | Extract union branches |
| `Type.exclude(def)` | Exclude union branches |
| `Type.json` | Internal JSON |
| `Type.toJsonSchema()` | JSON Schema export |
| `Type.expression` | TS-like syntax string |
| `Type.description` | Human-readable description |
| `Type.configure({})` | Add metadata/config |
| `Type.describe(str)` | Shorthand for description |
| `Type.select(...)` | Query internal nodes |
