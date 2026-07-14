# OpenAI API preflight

Checked: 2026-07-14 00:50 America/Mexico_City  
Scope: account/authentication readiness only; no iPhone probe or audio code

## Result

PASS — a standard server-side API key minted a 120-second Realtime client
secret for `gpt-realtime-2.1`, and that secret opened the current GA direct
WebSocket endpoint from a non-app laptop client. The connection emitted
`session.created` with model `gpt-realtime-2.1`.

Observed redacted output:

```text
client_secret_mint=ok
websocket_session_created=ok model=gpt-realtime-2.1
```

No API key or client-secret value was printed, saved, or added to the
repository. This closes only client-secret minting and the direct-WebSocket
server handshake. It does not start or satisfy Gate 0 and proves nothing about iPhone audio,
latency, AEC, floor control, or rendered-audio evidence.

## Post-lesson planner extension

Checked: 2026-07-14 05:27 America/Mexico_City

PASS — the private Worker called the Responses API with fixed model
`gpt-5.6-sol`, strict `text.format` JSON Schema, `store: false`, and a salted
`safety_identifier`. The canonical no-audio LearningReport returned a bounded
validated `advance / completed_after_repair` recommendation. The separately
revocable product token received HTTP 401 from the Realtime secret endpoint.

The Worker and iOS app both revalidate progression semantics. No model response
can mark an obligation complete, alter evidence, introduce a transcript, or
block the deterministic local recommendation. This live call proves only the
server contract; the product launch was still denied by the locked iPhone, so
device Keychain provisioning and on-device planner UI remain open.

Official contracts used for this implementation:

- https://developers.openai.com/api/docs/models/gpt-5.6-sol
- https://developers.openai.com/api/docs/guides/structured-outputs
- https://developers.openai.com/api/docs/guides/safety-best-practices

## Request shape

- Client secret: `POST https://api.openai.com/v1/realtime/client_secrets`
- Session: `type=realtime`, `model=gpt-realtime-2.1`
- Connection: `wss://api.openai.com/v1/realtime?model=gpt-realtime-2.1`
- Authentication: short-lived client secret in the WebSocket Authorization
  header; the standard API key remained in the server-side shell environment.
