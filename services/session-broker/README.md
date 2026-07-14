# Realtime session broker

This directory contains the minimal Cloudflare Worker that mints short-lived
Realtime client secrets. The standard OpenAI API key remains in Cloudflare's
secret store and is never returned, logged, or shipped in an app.

The client-secret endpoint accepts no caller model, prompt, voice, or session
configuration. It applies the server-owned `gpt-realtime-2.1` policy, a stable
privacy-preserving safety identifier, private install-token authentication, and
a Cloudflare rate-limit binding. The returned configuration hash is an expected
configuration comparison aid, not a cryptographic policy pin.

```sh
npm test
wrangler deploy --dry-run
wrangler secret put OPENAI_API_KEY
wrangler secret put MA_INSTALL_TOKEN
wrangler secret put MA_SAFETY_SALT
wrangler deploy
```

`POST /learning/next` is added only with the bounded post-lesson planner in
WP-5; it does not enter the latency-critical Gate 0 path.
