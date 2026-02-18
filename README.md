# LOWNET Toolkit

Verifiable digital artifacts — signed notices and encrypted messages that exist independently of any platform.

**Single HTML file. No server. No dependencies. Offline-first.**

## What's Inside

| File | Purpose |
|------|---------|
| `toolkit.html` | Full application — open in any browser |
| `lownet.js` | Core library — for developers building on LOWNET |
| `verify.html` | Dual-channel integrity verification |
| `sw.js` | Service Worker for PWA caching |
| `hashes.json` | Published release hashes (second channel) |
| `deploy.sh` | Deployment script with CSP hash injection |

## Protocols

| Protocol | Description |
|----------|-------------|
| **CNP-1** | Commitment Notice Protocol — signed, timestamped notices |
| **ENV-1.2** | Encrypted Envelope v1.2 — E2E encrypted messages with sender-minimization |
| **SCP-1** | Signed Commitment Packet — 110-byte binary format for constrained channels |
| **Sequential PoW** | Non-parallelizable chain of SHA-256 hashes (time = only resource) |

## Cryptography

- **Signing**: Ed25519
- **Key Exchange**: ECDH P-256 (ephemeral, forward secrecy)
- **Encryption**: AES-256-GCM with HKDF-SHA256
- **Identity**: PBKDF2-SHA256 (600,000 iterations)
- **Canonicalization**: RFC 8785 (JCS)

## Verify Integrity

The toolkit's SHA-256 hash is published in two independent locations. An attacker would need to compromise both to forge a match.

| Channel | Source |
|---------|--------|
| **GitHub** | [`hashes.json`](hashes.json) in this repository |
| **Server** | [lownet.org/verify](https://lownet.org/verify/) |

**Verify from the browser:**

Open [lownet.org/verify](https://lownet.org/verify/) — the page fetches the hash from both GitHub and the server, then computes the live hash client-side. All three must match.

**Verify from the terminal:**

```bash
curl -s https://lownet.org/toolkit.html | sha256sum
```

Compare the output against the hash in [`hashes.json`](hashes.json).

## Quick Start

### Toolkit

Open `toolkit.html` in your browser. That's it.

Works offline. Works on mobile. Works without an account.

### Library

```html
<script src="lownet.js"></script>
<script>
  lownet.identity.create('Alice').then(function(id) {
    return lownet.identity.load(id).then(function(loaded) {
      return lownet.cnp.sign(loaded, 'statement', {
        text: 'I agree to these terms.'
      });
    });
  }).then(function(notice) {
    console.log(JSON.stringify(notice, null, 2));
  });
</script>
```

```javascript
// Node.js
const lownet = require('./lownet.js');

const id = await lownet.identity.create('Alice');
const loaded = await lownet.identity.load(id);
const notice = await lownet.cnp.sign(loaded, 'statement', { text: 'Hello' });
const result = await lownet.cnp.verify(notice);
// result.valid === true
```

## API Reference

### `lownet.identity`

| Method | Description |
|--------|-------------|
| `.create(name)` | Generate new Ed25519 + ECDH identity |
| `.export(id, passphrase)` | Encrypt identity for storage |
| `.import(blob, passphrase)` | Decrypt identity (backward-compatible v1–v4) |
| `.load(id)` | Load CryptoKey objects (required before sign/encrypt) |
| `.publicBundle(id)` | Extract public keys for sharing |
| `.fingerprint(pubKey)` | Compute `AA:BB:CC:DD:EE:FF` fingerprint |

### `lownet.cnp`

| Method | Description |
|--------|-------------|
| `.sign(identity, type, payload)` | Create and sign a CNP-1 notice |
| `.verify(notice)` | Verify signature and fingerprint |

### `lownet.env`

| Method | Description |
|--------|-------------|
| `.encrypt(identity, recipientPub, content, options)` | Create ENV-1.2 envelope |
| `.decrypt(identity, envelope)` | Decrypt and verify (supports ENV-1/1.1/1.2) |
| `.verify(envelope)` | Verify outer signature (public mode only) |

Options: `{ mode: 'public' | 'private', ttl_ms: number }`

### `lownet.scp`

| Method | Description |
|--------|-------------|
| `.encode(identity, type, payloadHash)` | Create 110-byte SCP-1 packet |
| `.decode(data)` | Parse packet (hex, base64url, or bytes) |
| `.verify(data, pubKeyBytes)` | Decode and verify signature |

### `lownet.pow`

| Method | Description |
|--------|-------------|
| `.compute(seed, rounds, onProgress)` | Run sequential SHA-256 chain |
| `.verify(notice)` | Recompute and verify PoW on a notice |
| `.signWithPoW(identity, type, payload, options)` | Sign notice with PoW in one step |
| `.buildSeed(fp, seq, prev, payloadHash)` | Build deterministic seed string |
| `.requiredRounds(seq)` | Calculate rounds for a sequence number |

### `lownet.security`

| Method | Description |
|--------|-------------|
| `.assess(artifact, context)` | Return security level (0–3) with reasons |

### `lownet.util`

`b64`, `unb64`, `sha256`, `canonicalize`, `fingerprint`, `bytesToHex`

## License

MIT

© 2024–2026 LOWNET Contributors

---

*If you don't need cryptography, you don't need LOWNET.
If you suddenly do — you're already too late.*
