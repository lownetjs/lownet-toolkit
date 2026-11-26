# LOWNET Toolkit

Verifiable digital artifacts — signed notices and encrypted messages that exist independently of any platform.

**Single HTML file. No server. No dependencies. Offline-first.**

> **Status:** The LOWNET formats (CNP-1, ENV-1.3, ENV-F-2, SCP-1) are our own protocols. We test them ourselves. They are not externally audited, and this is no security guarantee.

## What's Inside

| File | Purpose |
|------|---------|
| `toolkit.html` | Full application — open in any browser |
| `lownet.js` | Core library — for developers building on LOWNET, served from [lownet.org](https://lownet.org/lownet.js), not part of this repository |
| `verify.html` | Dual-channel integrity verification |
| `sw.js` | Service Worker for PWA caching |
| `hashes.json` | Published release hashes (second channel) |

## Protocols

| Protocol | Description |
|----------|-------------|
| **CNP-1** | Commitment Notice Protocol — signed, timestamped notices; `ln_bind` signs the whole notice, work chain and links included |
| **ENV-1.3** | Encrypted Envelope v1.3 — E2E encrypted messages with sender-minimization; the sender's signature names the recipient |
| **ENV-F-2** | Encrypted file envelope — the sender's signature covers the encrypted content |
| **SCP-1** | Signed Commitment Packet — 110-byte binary format for constrained channels |
| **Sequential PoW** | Non-parallelizable chain of SHA-256 hashes (time = only resource) |

## Cryptography

- **Signing**: Ed25519
- **Key Exchange**: ECDH P-256 (ephemeral on the sender's side, see [Known Limits](#known-limits))
- **Encryption**: AES-256-GCM with HKDF-SHA256
- **Identity**: PBKDF2-SHA256 (600,000 iterations)
- **Canonicalization**: RFC 8785 (JCS), strings exactly as written (older formats: normalized to NFC)
- **Fingerprint**: 128 bit (SHA-256 of the signing key, first 16 bytes) for people to compare; the 48-bit `fp` stays inside the formats as an index

## Changes in 1.2

1.2 answers an independent review of 1.1.3 (seven findings, F-1 to F-7) and contains 1.1.4, which was finished but never published (see below). Older formats still open. They are marked as older format and are never shown as valid where the old format cannot back that up.

**Messages: ENV-1.3 (finding F-2, F-7)**

- New envelopes are ENV-1.3. In private mode the sender's signature covers the whole clear header, including the ephemeral key, the recipient hint, the TTL and the mode, together with the content. In ENV-1.2 it covered only id, time and content, so a recipient could put content and signature into a new envelope for someone else, who then saw a valid message from the original sender.
- A private ENV-1.2 envelope still opens, marked as older format: the content and the sender are shown, never as valid, with the note that it may have been passed on. Public ENV-1.2 envelopes and ENV-1.1 stay valid: their outer signature names the recipient. 1.1.4 and earlier do not open ENV-1.3.

**Notices: `ln_bind` and a minimum of work (finding F-3, F-7)**

- A notice from 1.2 carries `ln_bind`, a second signature over the whole notice as it stands, byte for byte: the work chain, the links and `ln_signature` included. `ln_signature` keeps the reduced projection, so 1.1.x pages and LOWNET Pocket read new notices as before. lownet-node checks `ln_bind` from its 1.2 build on; an older node refuses notices that carry it, and the page then publishes the board copy without `ln_bind` (that copy reads as older format).
- A notice is valid only when its chain recomputes, reaches the minimum the page itself computes for its sequence number, and is covered by `ln_bind`. A notice without a chain, with an unknown or the classic chain format, below the minimum or without `ln_bind` (every notice before 1.2) shows its signature and content in amber, never as valid. A changed chain, an added or swapped link and a rewritten name break `ln_bind` and are refused.

**Strings exactly as written (finding F-7)**

- ENV-1.3, ENV-F-2 and `ln_bind` sign strings as they are, as RFC 8785 does. A name rewritten from NFC to NFD broke no signature in 1.1.3; it does now. A key `__proto__` is refused.

**Senders and fingerprints (finding F-5)**

- After opening a message or a file, the card says whether the sender's key is yours, a contact's (with the name you stored) or unknown. An unknown key, or a contact signing under another name, turns the result amber; it stays amber until that check has answered.
- People compare a 128-bit fingerprint (32 hex digits). It appears in every result, in the Keys tab for unlocked identities, in the contact form and in the terminal (`whoami`). The 48-bit `fp` stays inside the formats as an index. A contact whose stated `fp` does not belong to its key is refused.

**Files (finding F-1, F-4, F-6)**

- ENV-F-2 (from 1.1.4) binds the sender's signature to the encrypted content (F-1) and writes no license into the clear header (F-4).
- More than 200 recipients are refused before encrypting: a reader finds the end of the header only in the first 64 KB, so a longer header could be written but never opened (F-6). An empty file with padding opens empty (F-6, already in 1.1.4).
- Opening a file needs no license any more. Encrypting stays PRO. Your own files never depend on a license.

**Other**

- The card notes an envelope that was opened here before. A copy stays valid until it expires; the page can show a repeat, not prevent it on other devices.
- The result field `forwardSecrecy` says `"sender"` instead of `true`.

## Changes in 1.1.4 (lownet.js 1.0.2, published as part of 1.2)

1.1.4 was finished on 6 November 2026 and never published on its own. In 1.1.4, notices, ENV-1.2 envelopes and SCP-1 packets kept their format; only file envelopes got a new one.

**File envelopes**

- New files are ENV-F-2. The sender's signature covers the SHA-256 of the encrypted content, and a file is valid only after that hash was recomputed. In ENV-F-1 the signature of a public file covered only the header, so a co-recipient could replace the content.
- ENV-F-1 files still open, marked as older format, never as valid. 1.1.3 does not open ENV-F-2 files.
- No license is written into the clear header of a file any more.

**Toolkit and lownet.js**

- A check no longer throws on what it is given: a key that is no string, broken Base64, a missing sender, a value without a text form. It answers with a refusal, and what cannot be displayed ends in a visible error. The Verify card used to stay silent or keep the previous result.
- An envelope with an unreadable timestamp, or a TTL that is no number above 0, is refused. It used to never expire.
- SCP-1 refuses to encode an unknown type, a sequence number above 65535 and a hash that is not 32 bytes. Such input used to be changed silently before signing. Timestamps read correctly after 19 January 2038.
- Public envelopes keep a content field named `_pad` and accept `null` as content.
- `requiredRounds` stops at the limit of 50,000,000 rounds, above which verifiers refuse a chain, and it no longer returns `NaN`.

**Toolkit only**

- A notice or a file header with an unreadable timestamp is refused. It used to pass the check for future dates. A file whose name, type or sender name is no text is refused as well.
- The Verify card and the file card are emptied before every check, ignore the answer of an earlier check and show an error if a result cannot be displayed. A render that stopped halfway could show a new signer or sender beside the content of the previous result, and a slow check could overwrite the answer to a later one. A file only becomes available for download once it could be shown completely.
- The same rule now holds everywhere an asynchronous result reaches the page: the hash card, the board, recipient fields, lists, unlocking, the camera. Only the newest run may write, and no failure stays silent. A passphrase on its way no longer unlocks after Cancel, and an older paste no longer replaces the recipient in the field.
- The board shows the full fingerprint, as the Verify card does, and says how many posts it left out.
- The older chain format `sequential` is no longer checked. No version since 1.0.0 wrote it, its seed was free, so the chain belonged to nothing, and without a seed the page hung, in the Verify card and on the board. Such a chain now counts for nothing: the notice is judged by its signature, and the card says `Chain not checked`.
- The card shows only what a signed SCP-1 packet says, and envelope content no longer reads `undefined`.
- The page says what forward secrecy covers here, see [Known Limits](#known-limits). Its help no longer promises blocked framing, proof of when something was said, or a tamper check from inside the page.

**lownet.js only**

- `security.assess` gives a level above 0 only with `context.verified === true`, so a call without context now gives 0. `ots_proof` counts only with `otsVerified: true`. A failed check can no longer be raised by an `ots_proof` or by a notice inside an envelope.
- Base64 is decoded the same way in Node and in the browser. In Node, a signature with a stray character used to verify.
- `cnp.sign`, `pow.signWithPoW` and `env.encrypt` in private mode refuse a payload that JSON changes in transport, such as a `Date` or `undefined` in an array. Its signature would fail on arrival.
- `env.encrypt` refuses an unknown `mode` and a `ttl_ms` that is no number above 0.
- `pow.compute` refuses rounds that are no whole number. It used to hang on `NaN`.

## Known Limits

- **Not externally audited.** This is no security guarantee.
- **Forward secrecy covers the sender's side only.** Every envelope uses a fresh key on the sender's side. The recipient's key is long-lived, so whoever obtains it later can read old envelopes sent to it.
- **Older formats remain readable.** A private ENV-1.2 envelope does not name its recipient in the signature, a notice before 1.2 has no `ln_bind`, an ENV-F-1 file does not cover its content. Such items open, marked as older format, never as valid.
- **Names are self-descriptions.** Only the fingerprint, derived from the key, says who signed. The page says whether a sender's key is yours or a contact's; for any other key you have to compare the fingerprint yourself.
- **Times are the sender's own statement.** A notice can be backdated. A future date is refused for notices and envelopes, not for SCP-1 packets.
- **Older formats normalize strings to NFC.** ENV-1.1, ENV-1.2, ENV-F-1 and the reduced projection of `ln_signature` do. New formats and `ln_bind` sign strings exactly.
- **The notice formats of `lownet.js` and the toolkit do not verify in each other.** The toolkit signs a reduced projection, `lownet.js` the whole notice. lownet-node and LOWNET Pocket accept both. `cnp.verify` checks signature and fingerprint only, not the time and not the chain, which is what `pow.verify` is for. `env.verify` checks the signature only, expiry is checked by `env.decrypt`.
- **`ln_bind` and ENV-1.3 are new.** Pages 1.1.x, `lownet.js` 1.0.2 and LOWNET Pocket ignore `ln_bind`; for them the chain stays outside the signature, and none of them opens ENV-1.3. lownet-node checks `ln_bind` and carries ENV-1.3 and ENV-F-2 from its 1.2 build on. The board relay on lownet.org does not know `ln_bind` yet: the page then publishes the notice without it, so the board's copy reads as older format while the notice you keep stays bound.
- **The minimum of work is the page's own rule.** It follows `requiredRounds` for the sequence number the signer states, so claiming sequence 6 gives the lowest minimum (600,000 rounds). From about sequence 476 on the minimum is above what the Verify card recomputes (10 million rounds), and such a notice is never green here. Work says nothing about elapsed time; a faster machine does the same work sooner.
- **The board does not recompute long chains.** It recomputes up to 400,000 rounds, below every minimum, so its list marks notices "Signed · work not rechecked". Check a notice in the Verify card.
- **Replays.** An envelope stays valid until it expires, an SCP-1 packet has no expiry. The page notes a repeat it has seen itself; it cannot know about other devices.
- **Proof of work shows work, not elapsed time.** A faster machine does the same work sooner.
- **A public key bundle does not bind its encryption key to its signing key.** The fingerprint is derived from the signing key; a bundle can pair someone's signing key with another party's encryption key, and what you encrypt to it goes to whoever holds that encryption key. Take bundles from the person, not from a third party.
- **A compact recipient key (`lownet:e:`) carries no fingerprint.** Encrypting to it works, but the recipient's toolkit refuses the envelope as not addressed to it. Use the full public key.
- **The verify page runs on the server it checks.** It looks at the file on the server, not at the copy your open tab or service worker runs, and a tampered server can serve a tampered verify page.

## Verify Integrity

The toolkit's SHA-256 hash is published in two places. Only the terminal check against GitHub does not rely on the server: a tampered server can also serve a tampered verify page.

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
| `.verify(notice)` | Recompute and verify PoW on a notice; compare the returned `rounds` with your own minimum |
| `.signWithPoW(identity, type, payload, options)` | Sign notice with PoW in one step |
| `.buildSeed(fp, seq, prev, payloadHash)` | Build deterministic seed string |
| `.requiredRounds(seq)` | Calculate rounds for a sequence number |

### `lownet.security`

| Method | Description |
|--------|-------------|
| `.assess(artifact, context)` | Return security level (0–3) with reasons; 0 unless `context.verified === true` |

### `lownet.util`

`b64`, `unb64`, `sha256`, `canonicalize`, `fingerprint`, `bytesToHex`

## License

MIT

© 2024–2026 LOWNET Contributors

---

*If you don't need cryptography, you don't need LOWNET.
If you suddenly do — you're already too late.*
