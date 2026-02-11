---
name: using-node-crypto
description: Use when hashing passwords, encrypting data, generating secure tokens, creating digital signatures, computing checksums, or implementing HMAC authentication in Node.js — covers node:crypto for SHA-256, bcrypt/scrypt, AES-GCM encryption, randomBytes, key pair generation, HMAC, and timing-safe comparison. Triggers on ERR_CRYPTO_INVALID_STATE, ERR_OSSL_*, ERR_CRYPTO_TIMING_SAFE_EQUAL_LENGTH.
---

# Using Node Crypto

## Overview

Use built-in cryptographic primitives for hashing, encryption, and secure random generation.

## Version Scope

Covers Node.js v24 (current) through latest LTS. Features flagged as v24+ may not exist in older releases.

## When to Use

- Hashing data (SHA-256, SHA-512, MD5 for checksums).
- HMAC for message authentication.
- Encrypting/decrypting data (AES-256-GCM recommended).
- Password hashing (scrypt preferred, pbkdf2 acceptable).
- Generating secure random values (randomBytes, randomUUID).
- Signing and verifying data.

## When Not to Use

- TLS/SSL configuration — use node:tls directly.
- JWT handling — use a library like jose.
- You need Web Crypto API specifically — use globalThis.crypto.subtle.

## Quick Reference

- Use `createHash('sha256').update(data).digest('hex')` for hashing.
- Use `randomBytes(32)` for secure random, `randomUUID()` for UUIDs.
- Use `scrypt` for password hashing (not MD5/SHA).
- Use `createCipheriv`/`createDecipheriv` with AES-256-GCM for encryption.
- Always use `timingSafeEqual` for comparing secrets.
- Prefer async versions (scrypt, pbkdf2, randomBytes with callback/promisify).

## Examples

### Hash a string

```js
import { createHash } from 'node:crypto';
const hash = createHash('sha256').update('hello').digest('hex');
```

### Generate random UUID

```js
import { randomUUID } from 'node:crypto';
const id = randomUUID(); // '1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed'
```

### Password hashing with scrypt

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

### AES-256-GCM encryption

```js
import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';

function encrypt(text, key) {
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return { iv, encrypted, tag };
}
```

## Common Errors

| Code | Message Fragment | Fix |
|---|---|---|
| ERR_CRYPTO_INVALID_STATE | Invalid state | Check cipher/decipher lifecycle; don't reuse after final() |
| ERR_OSSL_EVP_BAD_DECRYPT | Bad decrypt | Wrong key, IV, or corrupted ciphertext |
| ERR_CRYPTO_TIMING_SAFE_EQUAL_LENGTH | Buffers must have same length | Ensure both buffers are the same byte length |
| ERR_INVALID_ARG_TYPE | Not a Buffer | Convert strings to Buffers with Buffer.from() |
| ERR_OSSL_UNSUPPORTED | Algorithm not supported | Use a supported algorithm (check openssl list) |

## References

- `crypto.md`
