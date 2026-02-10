# Node Crypto (v24)

## Hashing

- Use `createHash(algorithm)` to create a hash instance.
- Supported algorithms: `sha256`, `sha512`, `sha384`, `sha1`, `md5` (checksums only).
- Call `.update(data)` one or more times for streaming, then `.digest(encoding)`.

```js
import { createHash } from 'node:crypto';

// Single-shot
const hash = createHash('sha256').update('hello world').digest('hex');

// Streaming
const h = createHash('sha512');
h.update('part1');
h.update('part2');
const result = h.digest('base64');
```

## HMAC

- Use `createHmac(algorithm, key)` for keyed message authentication.
- Same streaming interface as `createHash`.

```js
import { createHmac } from 'node:crypto';

const hmac = createHmac('sha256', 'secret-key')
  .update('message')
  .digest('hex');
```

## Encryption / Decryption

- Use `createCipheriv` and `createDecipheriv` — never `createCipher` (deprecated).
- Recommended: AES-256-GCM (authenticated encryption).
- IV must be unique per encryption; 12 bytes for GCM.

```js
import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';

function encrypt(text, key) {
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return { iv, encrypted, tag };
}

function decrypt({ iv, encrypted, tag }, key) {
  const decipher = createDecipheriv('aes-256-gcm', key, iv);
  decipher.setAuthTag(tag);
  const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  return decrypted.toString('utf8');
}
```

## Password Hashing

### scrypt (preferred)

- CPU and memory-hard; resistant to GPU attacks.
- Use `promisify(scrypt)` for async usage.
- Always generate a unique salt per password with `randomBytes(16)`.

```js
import { scrypt, randomBytes, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scryptAsync = promisify(scrypt);

async function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const hash = await scryptAsync(password, salt, 64);
  return `${salt}:${hash.toString('hex')}`;
}

async function verifyPassword(password, stored) {
  const [salt, hash] = stored.split(':');
  const hashBuffer = Buffer.from(hash, 'hex');
  const derived = await scryptAsync(password, salt, 64);
  return timingSafeEqual(hashBuffer, derived);
}
```

### pbkdf2 (acceptable alternative)

```js
import { pbkdf2, randomBytes } from 'node:crypto';
import { promisify } from 'node:util';

const pbkdf2Async = promisify(pbkdf2);

async function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const hash = await pbkdf2Async(password, salt, 100000, 64, 'sha512');
  return `${salt}:${hash.toString('hex')}`;
}
```

### Timing-safe comparison

- Always use `timingSafeEqual` when comparing secrets, hashes, or tokens.
- Both buffers must be the same byte length.

```js
import { timingSafeEqual } from 'node:crypto';

const a = Buffer.from('secret1');
const b = Buffer.from('secret2');
// Only compare if lengths match
if (a.length === b.length) {
  const equal = timingSafeEqual(a, b);
}
```

## Random Values

```js
import { randomBytes, randomUUID, randomInt } from 'node:crypto';

// 32 random bytes as hex
const bytes = randomBytes(32).toString('hex');

// RFC 4122 v4 UUID
const uuid = randomUUID();

// Random integer in range [0, 100)
const num = randomInt(100);

// Random integer in range [10, 20)
const ranged = randomInt(10, 20);
```

- `randomFillSync(buffer)` fills an existing buffer with random bytes (sync).
- `randomBytes` is async when given a callback, sync when called without one.

## Key Generation

```js
import { generateKeyPair, generateKey } from 'node:crypto';
import { promisify } from 'node:util';

const generateKeyPairAsync = promisify(generateKeyPair);

// RSA key pair
const { publicKey, privateKey } = await generateKeyPairAsync('rsa', {
  modulusLength: 4096,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});

// ECDSA key pair
const ec = await generateKeyPairAsync('ec', {
  namedCurve: 'P-256',
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});

// Symmetric key (AES-256)
const generateKeyAsync = promisify(generateKey);
const key = await generateKeyAsync('aes', { length: 256 });
```

## Signing and Verifying

```js
import { createSign, createVerify } from 'node:crypto';

// Sign with RSA
const sign = createSign('SHA256');
sign.update('data to sign');
const signature = sign.sign(privateKey, 'hex');

// Verify
const verify = createVerify('SHA256');
verify.update('data to sign');
const isValid = verify.verify(publicKey, signature, 'hex');
```

## Web Crypto API

- Available at `globalThis.crypto.subtle` (no import needed).
- Use for browser-compatible code or when Web Crypto is specifically required.
- `node:crypto` is generally more convenient for server-side Node code.

```js
// Web Crypto hashing
const data = new TextEncoder().encode('hello');
const hashBuffer = await globalThis.crypto.subtle.digest('SHA-256', data);
const hashHex = Buffer.from(hashBuffer).toString('hex');
```

## Quick Reference

| Task | API | Notes |
|---|---|---|
| Hash data | `createHash('sha256')` | Use .update().digest() |
| HMAC | `createHmac('sha256', key)` | Keyed hash for authentication |
| Encrypt | `createCipheriv('aes-256-gcm', key, iv)` | Always use iv; GCM recommended |
| Decrypt | `createDecipheriv('aes-256-gcm', key, iv)` | Set auth tag for GCM |
| Password hash | `scrypt(password, salt, 64)` | Promisify for async |
| Random bytes | `randomBytes(32)` | Cryptographically secure |
| Random UUID | `randomUUID()` | RFC 4122 v4 |
| Random int | `randomInt(min, max)` | Exclusive upper bound |
| Key pair | `generateKeyPair('rsa', opts)` | RSA, ECDSA, Ed25519 |
| Sign | `createSign('SHA256')` | .update().sign(key) |
| Verify | `createVerify('SHA256')` | .update().verify(key, sig) |
| Compare secrets | `timingSafeEqual(a, b)` | Same-length buffers only |

## Common Mistakes

**Using MD5 or SHA for passwords** — These are fast hashes, not password hashes. Use `scrypt` or `pbkdf2` with a unique salt.

**Hardcoded encryption keys** — Store keys in environment variables or a secrets manager. Never commit keys to source control.

**Using ECB mode** — ECB encrypts identical blocks to identical ciphertext. Use GCM or CBC with random IV.

**Reusing IVs** — Each encryption must use a unique IV. Use `randomBytes(12)` for GCM.

**Comparing secrets with `===`** — Use `timingSafeEqual` to prevent timing attacks.

**Using `createCipher` (deprecated)** — Always use `createCipheriv` with an explicit IV.

## Do / Don't

- Do use AES-256-GCM for symmetric encryption.
- Do use scrypt for password hashing.
- Do use timingSafeEqual for comparing secrets.
- Do generate a unique salt/IV per operation.
- Don't use MD5 or SHA for passwords.
- Don't hardcode keys or secrets in source code.
- Don't reuse IVs across encryptions.
- Don't use ECB mode or deprecated APIs.
