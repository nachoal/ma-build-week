# MA private session and learning broker

This directory contains the minimal Cloudflare Worker for MA's server-only
OpenAI calls. It mints separate short-lived Realtime client secrets for the
developer probe and the shipping push-to-talk tutor, and produces one bounded
post-lesson recommendation for the product. The standard OpenAI API key remains
in Cloudflare's secret store and is never returned, logged, or shipped in an
app.

Neither client-secret endpoint accepts a caller model, prompt, voice, tool, or
session configuration. `/realtime/client-secret` applies the frozen Gate 0
probe policy. `/product/realtime/client-secret` applies a distinct server-owned
`gpt-realtime-2.1` teaching policy: explicit push-to-talk, Japanese
transcription, one schema-guided function whose enum arguments are treated as
untrusted and exactly validated by the app, bounded English/Spanish spoken
feedback, and one captioned waiter turn. Both use a stable
privacy-preserving safety identifier, role-scoped install-token authentication,
and endpoint-scoped rate limiting. The returned configuration hash is an
expected configuration comparison aid, not a cryptographic policy pin.

`POST /learning/guided-next` accepts only the guided v2 restaurant report: fixed
scene/obligation/phrase identifiers plus per-stage attempt count, last
qualitative review, and visible scaffold. It explicitly rejects audio,
transcript, free-form feedback, self-assessment, unknown fields, and reports
outside the fixed scene. The older `/learning/next` v1 contract remains isolated
for the frozen replay/audit path; neither endpoint accepts the other's schema.
The Worker calls the Responses API with:

- fixed model `gpt-5.6-sol`;
- strict `text.format` JSON Schema;
- `store: false` and a salted safety identifier;
- low reasoning effort, 320 maximum output tokens, two attempts of ten seconds;
- no transcript, raw audio, heard-Japanese text, free-form feedback, learner
  name, email, or attempt/report UUID in guided model input.

Responses output is untrusted. The Worker requires one completed message with
one `output_text`, validates every action/reason pair against observed facts,
and derives all learner-facing evidence language from local canonical strings.
The iOS app performs the same validation again. A deterministic recommendation
is visible immediately and remains the result on missing credentials, timeout,
network failure, refusal, malformed output, contradiction, or stale report.

`MA_PRODUCT_INSTALL_TOKEN` is the separately revocable product token accepted
by `/product/realtime/client-secret`, `/learning/guided-next`, and the isolated
legacy `/learning/next`. `MA_INSTALL_TOKEN` remains the probe token accepted
only by `/realtime/client-secret`. Neither role can authorize the other role's
endpoint. Both are secrets, never source or resource values. Product launch
provisions its token into this-device-only Keychain storage and removes it from
the process environment.

```sh
npm test
wrangler deploy --dry-run
wrangler secret put OPENAI_API_KEY
wrangler secret put MA_INSTALL_TOKEN
wrangler secret put MA_PRODUCT_INSTALL_TOKEN
wrangler secret put MA_SAFETY_SALT
wrangler deploy
```

Both learning endpoints are post-lesson only and never enter the product audio
path. The iPhone connects directly to OpenAI for learner audio; this Worker
never receives PCM, transcription, or Realtime tool arguments.
