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

## Request shape

- Client secret: `POST https://api.openai.com/v1/realtime/client_secrets`
- Session: `type=realtime`, `model=gpt-realtime-2.1`
- Connection: `wss://api.openai.com/v1/realtime?model=gpt-realtime-2.1`
- Authentication: short-lived client secret in the WebSocket Authorization
  header; the standard API key remained in the server-side shell environment.
