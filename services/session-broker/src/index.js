const OPENAI_CLIENT_SECRET_URL = "https://api.openai.com/v1/realtime/client_secrets";
const UPSTREAM_TIMEOUT_MS = 10_000;

export const realtimeSessionPolicy = Object.freeze({
  type: "realtime",
  model: "gpt-realtime-2.1",
  output_modalities: ["audio"],
  instructions: [
    "You are the waiter in one tightly bounded Japanese restaurant-arrival rehearsal.",
    "Speak natural Japanese, stay on the active restaurant obligation, and keep turns concise.",
    "Do not teach or grade during the live turn. The app owns repair, floor control, and pedagogy.",
  ].join(" "),
  audio: {
    input: {
      format: {
        type: "audio/pcm",
        rate: 24_000,
      },
      turn_detection: {
        type: "server_vad",
        threshold: 0.5,
        prefix_padding_ms: 300,
        silence_duration_ms: 500,
        create_response: false,
        interrupt_response: false,
      },
    },
    output: {
      format: {
        type: "audio/pcm",
        rate: 24_000,
      },
      voice: "marin",
    },
  },
});

const responseHeaders = Object.freeze({
  "cache-control": "no-store",
  "content-type": "application/json; charset=utf-8",
  "x-content-type-options": "nosniff",
});

export default {
  async fetch(request, env) {
    return handleRequest(request, env, fetch);
  },
};

export async function handleRequest(request, env, upstreamFetch) {
  const url = new URL(request.url);

  if (request.method === "GET" && url.pathname === "/health") {
    return jsonResponse(200, {
      service: "ma-session-broker",
      status: "ok",
    });
  }

  if (request.method !== "POST" || url.pathname !== "/realtime/client-secret") {
    return jsonResponse(404, { error: "not_found" });
  }

  if (!hasRequiredBindings(env)) {
    return jsonResponse(503, { error: "service_unavailable" });
  }

  const authorization = request.headers.get("authorization");
  const expectedAuthorization = `Bearer ${env.MA_INSTALL_TOKEN}`;
  if (!(await constantTimeEqual(authorization ?? "", expectedAuthorization))) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  const bodyResult = await parseEmptyObjectBody(request);
  if (!bodyResult.ok) {
    return jsonResponse(400, { error: bodyResult.error });
  }

  const safetyIdentifier = await makeSafetyIdentifier(
    env.MA_SAFETY_SALT,
    env.MA_INSTALL_TOKEN,
  );
  let rateLimit;
  try {
    rateLimit = await env.RATE_LIMITER.limit({ key: safetyIdentifier });
  } catch {
    return jsonResponse(503, { error: "service_unavailable" });
  }
  if (!rateLimit.success) {
    return jsonResponse(429, { error: "rate_limited" }, { "retry-after": "60" });
  }

  const expectedConfigurationHash = await sha256Hex(
    stableStringify(realtimeSessionPolicy),
  );

  let upstreamResponse;
  try {
    upstreamResponse = await upstreamFetch(OPENAI_CLIENT_SECRET_URL, {
      method: "POST",
      headers: {
        authorization: `Bearer ${env.OPENAI_API_KEY}`,
        "content-type": "application/json",
        "OpenAI-Safety-Identifier": safetyIdentifier,
      },
      body: JSON.stringify({
        expires_after: {
          anchor: "created_at",
          seconds: 120,
        },
        session: realtimeSessionPolicy,
      }),
      signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    });
  } catch {
    return jsonResponse(502, { error: "upstream_unavailable" });
  }

  if (!upstreamResponse.ok) {
    return jsonResponse(502, { error: "upstream_rejected" });
  }

  let payload;
  try {
    payload = await upstreamResponse.json();
  } catch {
    return jsonResponse(502, { error: "upstream_invalid_response" });
  }

  if (
    typeof payload?.value !== "string" ||
    payload.value.length === 0 ||
    typeof payload?.expires_at !== "number"
  ) {
    return jsonResponse(502, { error: "upstream_invalid_response" });
  }

  return jsonResponse(200, {
    value: payload.value,
    expires_at: payload.expires_at,
    expected_configuration_hash: expectedConfigurationHash,
  });
}

function hasRequiredBindings(env) {
  return (
    typeof env?.OPENAI_API_KEY === "string" &&
    env.OPENAI_API_KEY.length > 0 &&
    typeof env?.MA_INSTALL_TOKEN === "string" &&
    env.MA_INSTALL_TOKEN.length > 0 &&
    typeof env?.MA_SAFETY_SALT === "string" &&
    env.MA_SAFETY_SALT.length > 0 &&
    env?.RATE_LIMITER !== undefined &&
    env.RATE_LIMITER !== null
  );
}

async function parseEmptyObjectBody(request) {
  const text = await request.text();
  if (text.trim().length === 0) {
    return { ok: true };
  }

  let value;
  try {
    value = JSON.parse(text);
  } catch {
    return { ok: false, error: "invalid_json" };
  }

  if (value === null || Array.isArray(value) || typeof value !== "object") {
    return { ok: false, error: "invalid_request" };
  }
  if (Object.keys(value).length > 0) {
    return { ok: false, error: "caller_configuration_forbidden" };
  }
  return { ok: true };
}

async function constantTimeEqual(left, right) {
  const [leftDigest, rightDigest] = await Promise.all([
    sha256Bytes(left),
    sha256Bytes(right),
  ]);
  let difference = 0;
  for (let index = 0; index < leftDigest.length; index += 1) {
    difference |= leftDigest[index] ^ rightDigest[index];
  }
  return difference === 0;
}

async function makeSafetyIdentifier(salt, installToken) {
  return `ma_${(await sha256Hex(`${salt}\u0000${installToken}`)).slice(0, 48)}`;
}

async function sha256Bytes(value) {
  const data = new TextEncoder().encode(value);
  return new Uint8Array(await crypto.subtle.digest("SHA-256", data));
}

async function sha256Hex(value) {
  const digest = await sha256Bytes(value);
  return Array.from(digest, (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function stableStringify(value) {
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(",")}]`;
  }
  if (value !== null && typeof value === "object") {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

function jsonResponse(status, body, additionalHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...responseHeaders,
      ...additionalHeaders,
    },
  });
}
