import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { handleRequest, realtimeSessionPolicy } from "../src/index.js";

const installToken = "test-install-token";

function environment(overrides = {}) {
  return {
    OPENAI_API_KEY: "test-server-api-key",
    MA_INSTALL_TOKEN: installToken,
    MA_SAFETY_SALT: "test-safety-salt",
    RATE_LIMITER: {
      async limit() {
        return { success: true };
      },
    },
    ...overrides,
  };
}

function request(path, options = {}) {
  return new Request(`https://broker.test${path}`, options);
}

function authorizedHeaders() {
  return {
    authorization: `Bearer ${installToken}`,
    "content-type": "application/json",
  };
}

describe("MA session broker", () => {
  it("serves a secret-free health response", async () => {
    const response = await handleRequest(
      request("/health"),
      environment(),
      async () => assert.fail("health must not call upstream"),
    );

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      service: "ma-session-broker",
      status: "ok",
    });
    assert.equal(response.headers.get("cache-control"), "no-store");
  });

  it("fails closed when a required binding is absent", async () => {
    const response = await handleRequest(
      request("/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: "{}",
      }),
      environment({ OPENAI_API_KEY: "" }),
      async () => assert.fail("missing bindings must not call upstream"),
    );

    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), { error: "service_unavailable" });
  });

  it("rejects an invalid install token", async () => {
    const response = await handleRequest(
      request("/realtime/client-secret", {
        method: "POST",
        headers: { authorization: "Bearer wrong" },
      }),
      environment(),
      async () => assert.fail("unauthorized requests must not call upstream"),
    );

    assert.equal(response.status, 401);
    assert.deepEqual(await response.json(), { error: "unauthorized" });
  });

  it("rejects caller-selected session configuration", async () => {
    const response = await handleRequest(
      request("/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify({ model: "caller-model" }),
      }),
      environment(),
      async () => assert.fail("caller configuration must not call upstream"),
    );

    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), {
      error: "caller_configuration_forbidden",
    });
  });

  it("enforces the configured rate limiter", async () => {
    const response = await handleRequest(
      request("/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: "{}",
      }),
      environment({
        RATE_LIMITER: {
          async limit() {
            return { success: false };
          },
        },
      }),
      async () => assert.fail("limited requests must not call upstream"),
    );

    assert.equal(response.status, 429);
    assert.equal(response.headers.get("retry-after"), "60");
  });

  it("mints only the fixed Realtime policy and returns a bounded response", async () => {
    let observedRequest;
    const response = await handleRequest(
      request("/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: "{}",
      }),
      environment(),
      async (url, options) => {
        observedRequest = { url, options };
        return Response.json({
          value: "ek_test_ephemeral_only",
          expires_at: 1234567890,
          session: { id: "must-not-be-forwarded" },
        });
      },
    );

    assert.equal(response.status, 200);
    const result = await response.json();
    assert.deepEqual(Object.keys(result).sort(), [
      "expected_configuration_hash",
      "expires_at",
      "value",
    ]);
    assert.equal(result.value, "ek_test_ephemeral_only");
    assert.equal(result.expected_configuration_hash.length, 64);
    assert.equal(observedRequest.url, "https://api.openai.com/v1/realtime/client_secrets");
    assert.equal(observedRequest.options.method, "POST");
    assert.equal(
      observedRequest.options.headers.authorization,
      "Bearer test-server-api-key",
    );
    assert.match(
      observedRequest.options.headers["OpenAI-Safety-Identifier"],
      /^ma_[a-f0-9]{48}$/,
    );

    const upstreamBody = JSON.parse(observedRequest.options.body);
    assert.deepEqual(upstreamBody.session, realtimeSessionPolicy);
    assert.deepEqual(upstreamBody.expires_after, {
      anchor: "created_at",
      seconds: 120,
    });
    assert.equal(JSON.stringify(result).includes("test-server-api-key"), false);
    assert.equal(JSON.stringify(result).includes("must-not-be-forwarded"), false);
  });

  it("does not forward an upstream error body", async () => {
    const response = await handleRequest(
      request("/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: "{}",
      }),
      environment(),
      async () => new Response("private upstream detail", { status: 400 }),
    );

    assert.equal(response.status, 502);
    assert.deepEqual(await response.json(), { error: "upstream_rejected" });
  });
});
