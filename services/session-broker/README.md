# MA private session and learning broker

This directory contains the minimal Cloudflare Worker for MA's server-only
OpenAI calls. It mints short-lived Realtime client secrets for the developer
probe and produces one bounded post-lesson recommendation for the product. The
standard OpenAI API key remains in Cloudflare's secret store and is never
returned, logged, or shipped in an app.

The client-secret endpoint accepts no caller model, prompt, voice, or session
configuration. It applies the server-owned `gpt-realtime-2.1` policy, a stable
privacy-preserving safety identifier, private install-token authentication, and
a Cloudflare rate-limit binding. The returned configuration hash is an expected
configuration comparison aid, not a cryptographic policy pin.

`POST /learning/next` accepts only the versioned restaurant LearningReport
contract. It rejects caller model/prompt fields, raw-audio claims, retained-audio
flags, unknown fields, inconsistent onset/presence evidence, and reports outside
the fixed scene/obligation. The Worker calls the Responses API with:

- fixed model `gpt-5.6-sol`;
- strict `text.format` JSON Schema;
- `store: false` and a salted safety identifier;
- low reasoning effort, 320 maximum output tokens, two attempts of seven seconds;
- no transcript, raw audio, learner name, email, or attempt/report UUID in model
  input.

Responses output is untrusted. The Worker requires one completed message with
one `output_text`, validates every action/reason pair against observed facts,
and derives all learner-facing evidence language from local canonical strings.
The iOS app performs the same validation again. A deterministic recommendation
is visible immediately and remains the result on missing credentials, timeout,
network failure, refusal, malformed output, contradiction, or stale report.

`MA_PRODUCT_INSTALL_TOKEN` is the separately revocable product token and is
accepted only by `/learning/next`; `MA_INSTALL_TOKEN` remains the probe token
and is accepted only by `/realtime/client-secret`. Neither role can authorize
the other endpoint. Both are secrets, never source or resource values. The
product launch provisions its token into
this-device-only Keychain storage and removes it from the process environment.

```sh
npm test
wrangler deploy --dry-run
wrangler secret put OPENAI_API_KEY
wrangler secret put MA_INSTALL_TOKEN
wrangler secret put MA_PRODUCT_INSTALL_TOKEN
wrangler secret put MA_SAFETY_SALT
wrangler deploy
```

The learning endpoint is post-lesson only and never enters the latency-critical
Gate 0 or product audio path.
