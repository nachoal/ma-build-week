# Gate 0 broker evidence

Checked from the root implementation task after the Gate 0 clock started.

## Implemented boundary

- Cloudflare Worker: `ma-session-broker`; the network endpoint is public, while
  every mint request is protected by the private revocable install token.
- `GET /health` returns only service/status.
- `POST /realtime/client-secret` requires a revocable install token and accepts
  only an empty object.
- Caller-selected model, prompt, voice, and session configuration are rejected.
- The server selects `gpt-realtime-2.1`, 24 kHz PCM, `marin`, 120-second secret
  TTL, and server VAD with automatic response/interruption disabled.
- A stable salted hash becomes `OpenAI-Safety-Identifier`; neither source value
  is returned.
- The standard API key, install token, and salt are Cloudflare secrets. The
  generated install token and salt are also recoverable only from the local
  macOS Keychain for private device setup.
- The response contains only the ephemeral value, expiry, and expected-policy
  hash. The hash helps compare effective configuration and is not a
  cryptographic policy pin.

## Verification

- Node contract/security suite: 7 passed, 0 failed.
- Wrangler dry run: passed; rate-limit binding recognized.
- Deployed version: `d2a6368b-dee5-412e-9fd1-984a8ebd328d`.
- Live health: 200.
- Live unauthorized request: 401.
- Live caller override: 400 `caller_configuration_forbidden`.
- Live authorized request: 200; ephemeral format, numeric expiry, and 64-digit
  policy hash validated without printing the value in the passing smoke test.
- Real secrets are absent from the tracked set.

## Rate-limit scope

The Cloudflare binding is configured for 12 calls per 60 seconds per stable
private-client key. A same-client burst was not rejected. Current Cloudflare
documentation describes this API as per-location, permissive, eventually
consistent, and unsuitable for accurate accounting. The binding remains
defense-in-depth; the revocable install token is the primary private-MVP gate.
No stronger rate-limit claim is made.

## Contained diagnostic incident

A later diagnostic command expected a rate-limited response and printed the
JSON body when Cloudflare permissively returned 200. This placed one newly
minted 120-second client-secret value in private root-task tool output. It was
not written to Git or a repository file, the standard API key was not exposed,
and the value expired automatically. Subsequent commands must project only
status/type/length fields before printing.

Because the Gate protocol requires client-secret values to be absent from logs,
this incident prevents a PASS verdict even if the later audio characterization
is strong. Experiment 0 continues because its independent result determines
whether PARTIAL may use live explicit non-overlap Realtime.
