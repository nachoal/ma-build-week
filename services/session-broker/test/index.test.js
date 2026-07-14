import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, it } from "node:test";

import {
  handleRequest,
  learningActionSchema,
  learningPlannerPolicy,
  realtimeSessionPolicy,
} from "../src/index.js";

const installToken = "t".repeat(48);
const productInstallToken = "p".repeat(48);
const completedLearningReportFixture = JSON.parse(
  readFileSync(
    new URL(
      "../../../apps/MATests/Fixtures/learning-report-completed.json",
      import.meta.url,
    ),
    "utf8",
  ),
);
const completedLearningActionFixture = JSON.parse(
  readFileSync(
    new URL(
      "../../../apps/MATests/Fixtures/next-learning-action-completed.json",
      import.meta.url,
    ),
    "utf8",
  ),
);

function environment(overrides = {}) {
  return {
    OPENAI_API_KEY: "test-server-api-key",
    MA_INSTALL_TOKEN: installToken,
    MA_PRODUCT_INSTALL_TOKEN: productInstallToken,
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
    authorization: `Bearer ${productInstallToken}`,
    "content-type": "application/json",
  };
}

function realtimeAuthorizedHeaders() {
  return {
    authorization: `Bearer ${installToken}`,
    "content-type": "application/json",
  };
}

function validLearningReport() {
  return structuredClone(completedLearningReportFixture);
}

function learningUpstreamResponse(recommendation = {}) {
  return Response.json({
    id: "must-not-be-forwarded",
    status: "completed",
    output: [
      {
        type: "message",
        content: [
          {
            type: "output_text",
            text: JSON.stringify({
              action: "advance",
              reason: "completed_after_repair",
              explanation_es: "Ya resolviste la misma situación después de repararla.",
              obligation_id: "restaurant.party-size.one",
              ...recommendation,
            }),
          },
        ],
      },
    ],
  });
}

function modelSafeReport(report) {
  return {
    schema_version: report.schema_version,
    scene_plan: report.scene_plan,
    attempts: report.attempts.map((attempt) => ({
      obligation_id: attempt.obligation_id,
      scaffold: attempt.scaffold,
      attempt_number: attempt.attempt_number,
      captured_duration_ms: attempt.captured_duration_ms,
      estimated_voice_onset_ms: attempt.estimated_voice_onset_ms,
      speech_presence_detected: attempt.speech_presence_detected,
      self_reported_completed: attempt.self_reported_completed,
      repair_count: attempt.repair_count,
    })),
    current_obligation_completed: report.current_obligation_completed,
    repair_segment_id: report.repair_segment_id,
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
        headers: realtimeAuthorizedHeaders(),
        body: "{}",
      }),
      environment({ OPENAI_API_KEY: "" }),
      async () => assert.fail("missing bindings must not call upstream"),
    );

    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), { error: "service_unavailable" });
  });

  it("requires the product credential only on the learning route", async () => {
    const response = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
      }),
      environment({ MA_PRODUCT_INSTALL_TOKEN: "" }),
      async () => assert.fail("missing product binding must not call upstream"),
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

  it("accepts a separately revocable product install token", async () => {
    const report = validLearningReport();
    const response = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: {
          authorization: `Bearer ${productInstallToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify(report),
      }),
      environment({
        MA_PRODUCT_INSTALL_TOKEN: productInstallToken,
      }),
      async () => learningUpstreamResponse(),
    );

    assert.equal(response.status, 200);
  });

  it("scopes probe and product credentials to their own endpoints", async () => {
    const learningWithProbeToken = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: realtimeAuthorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
      }),
      environment(),
      async () => assert.fail("cross-role token must not call upstream"),
    );
    assert.equal(learningWithProbeToken.status, 401);

    const realtimeWithProductToken = await handleRequest(
      request("/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: "{}",
      }),
      environment(),
      async () => assert.fail("cross-role token must not call upstream"),
    );
    assert.equal(realtimeWithProductToken.status, 401);
  });

  it("rejects caller-selected session configuration", async () => {
    const response = await handleRequest(
      request("/realtime/client-secret", {
        method: "POST",
        headers: realtimeAuthorizedHeaders(),
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
        headers: realtimeAuthorizedHeaders(),
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
        headers: realtimeAuthorizedHeaders(),
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
        headers: realtimeAuthorizedHeaders(),
        body: "{}",
      }),
      environment(),
      async () => new Response("private upstream detail", { status: 400 }),
    );

    assert.equal(response.status, 502);
    assert.deepEqual(await response.json(), { error: "upstream_rejected" });
  });

  it("rejects caller configuration and any raw-audio claim on learning reports", async () => {
    const configured = {
      ...validLearningReport(),
      model: "caller-model",
    };
    const configuredResponse = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(configured),
      }),
      environment(),
      async () => assert.fail("invalid reports must not call upstream"),
    );
    assert.equal(configuredResponse.status, 400);
    assert.deepEqual(await configuredResponse.json(), {
      error: "invalid_learning_report",
    });

    const rawReport = validLearningReport();
    rawReport.raw_audio_included = true;
    rawReport.attempts[1].raw_audio_retained = true;
    const rawResponse = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(rawReport),
      }),
      environment(),
      async () => assert.fail("raw-audio reports must not call upstream"),
    );
    assert.equal(rawResponse.status, 400);
    assert.deepEqual(await rawResponse.json(), {
      error: "invalid_learning_report",
    });
  });

  it("calls only fixed gpt-5.6-sol structured policy with bounded evidence", async () => {
    const report = validLearningReport();
    let observedRequest;
    const response = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(report),
      }),
      environment(),
      async (url, options) => {
        observedRequest = { url, options };
        return learningUpstreamResponse();
      },
    );

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), completedLearningActionFixture);
    assert.equal(observedRequest.url, "https://api.openai.com/v1/responses");
    assert.equal(observedRequest.options.method, "POST");
    assert.equal(
      observedRequest.options.headers.authorization,
      "Bearer test-server-api-key",
    );

    const upstreamBody = JSON.parse(observedRequest.options.body);
    assert.equal(upstreamBody.model, learningPlannerPolicy.model);
    assert.equal(upstreamBody.store, false);
    assert.equal(upstreamBody.max_output_tokens, 320);
    assert.deepEqual(upstreamBody.reasoning, { effort: "low" });
    assert.match(upstreamBody.safety_identifier, /^ma_[a-f0-9]{48}$/);
    assert.equal(upstreamBody.text.format.type, "json_schema");
    assert.equal(upstreamBody.text.format.strict, true);
    assert.deepEqual(upstreamBody.text.format.schema, learningActionSchema);
    const forwarded = JSON.parse(upstreamBody.input[0].content[0].text);
    assert.deepEqual(forwarded, { learning_report: modelSafeReport(report) });
    assert.equal(JSON.stringify(upstreamBody).includes(installToken), false);
    assert.equal(JSON.stringify(upstreamBody).includes("test-server-api-key"), false);
    assert.equal(JSON.stringify(forwarded).includes("transcript"), false);
    assert.equal(JSON.stringify(forwarded).includes("report_id"), false);
    assert.equal(JSON.stringify(forwarded).includes("raw_audio"), false);
  });

  it("uses exactly one bounded retry for a transient planner failure", async () => {
    let calls = 0;
    const response = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
      }),
      environment(),
      async () => {
        calls += 1;
        return calls === 1
          ? new Response("temporary", { status: 503 })
          : learningUpstreamResponse();
      },
    );

    assert.equal(response.status, 200);
    assert.equal(calls, 2);
    assert.equal(learningPlannerPolicy.maxAttempts, 2);
    assert.equal(learningPlannerPolicy.upstreamTimeoutMs, 7_000);
  });

  it("stops after the declared planner retry budget", async () => {
    let calls = 0;
    const response = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
      }),
      environment(),
      async () => {
        calls += 1;
        throw new Error("network down");
      },
    );

    assert.equal(response.status, 502);
    assert.equal(calls, 2);
    assert.deepEqual(await response.json(), { error: "upstream_unavailable" });
  });

  it("rejects a model advance when the learner did not complete the obligation", async () => {
    const report = validLearningReport();
    report.attempts[1].self_reported_completed = false;
    report.current_obligation_completed = false;
    const response = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(report),
      }),
      environment(),
      async () => learningUpstreamResponse({
        reason: "incomplete_self_report",
      }),
    );

    assert.equal(response.status, 502);
    assert.deepEqual(await response.json(), {
      error: "upstream_invalid_response",
    });
  });

  it("rejects invented evidence and extra fields in a model recommendation", async () => {
    const mismatched = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
      }),
      environment(),
      async () => learningUpstreamResponse({
        action: "advance",
        reason: "insufficient_evidence",
      }),
    );
    assert.equal(mismatched.status, 502);

    const invented = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
      }),
      environment(),
      async () => learningUpstreamResponse({
        action: "repeat",
        reason: "speech_presence_missing",
      }),
    );
    assert.equal(invented.status, 502);

    const extra = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
      }),
      environment(),
      async () => learningUpstreamResponse({ score: 99 }),
    );
    assert.equal(extra.status, 502);
  });

  it("validates every action and reason as one semantic pair", async () => {
    const allowed = new Set([
      "repeat:incomplete_self_report",
      "repeat:speech_presence_missing",
      "reduce_scaffold:scaffold_still_present",
      "isolate_segment:repair_needed",
      "isolate_segment:speech_presence_missing",
      "advance:completed_after_repair",
      "abstain:insufficient_evidence",
    ]);
    const actions = learningActionSchema.properties.action.enum;
    const reasons = learningActionSchema.properties.reason.enum;

    for (const reason of reasons) {
      const report = validLearningReport();
      if (reason === "incomplete_self_report" || reason === "repair_needed") {
        report.attempts[1].self_reported_completed = false;
        report.current_obligation_completed = false;
      }
      if (reason === "speech_presence_missing") {
        report.attempts[1].speech_presence_detected = false;
        report.attempts[1].estimated_voice_onset_ms = null;
        report.attempts[1].captured_duration_ms = 0;
      }
      if (reason === "scaffold_still_present") {
        report.attempts[1].scaffold = "rhythm_only";
      }

      for (const action of actions) {
        const response = await handleRequest(
          request("/learning/next", {
            method: "POST",
            headers: authorizedHeaders(),
            body: JSON.stringify(report),
          }),
          environment(),
          async () => learningUpstreamResponse({ action, reason }),
        );
        const key = `${action}:${reason}`;
        assert.equal(
          response.status,
          allowed.has(key) ? 200 : 502,
          `unexpected result for ${key}`,
        );
      }
    }
  });

  it("rejects incomplete, refused, ambiguous, or unexpected Responses output", async () => {
    const recommendationText = JSON.stringify({
      action: "advance",
      reason: "completed_after_repair",
      explanation_es: "Avanza.",
      obligation_id: "restaurant.party-size.one",
    });
    const validMessage = {
      type: "message",
      content: [{ type: "output_text", text: recommendationText }],
    };
    const invalidPayloads = [
      { output: [validMessage] },
      {
        status: "incomplete",
        incomplete_details: { reason: "max_output_tokens" },
        output: [validMessage],
      },
      {
        status: "completed",
        error: { code: "private_error" },
        output: [validMessage],
      },
      {
        status: "completed",
        output: [validMessage, validMessage],
      },
      {
        status: "completed",
        output: [{ type: "message", content: [{ type: "refusal", refusal: "no" }] }],
      },
      {
        status: "completed",
        output: [{ type: "custom_tool_call", name: "unexpected" }],
      },
      {
        status: "completed",
        output: [{
          type: "message",
          content: [
            { type: "output_text", text: recommendationText },
            { type: "output_text", text: recommendationText },
          ],
        }],
      },
    ];

    for (const payload of invalidPayloads) {
      const response = await handleRequest(
        request("/learning/next", {
          method: "POST",
          headers: authorizedHeaders(),
          body: JSON.stringify(validLearningReport()),
        }),
        environment(),
        async () => Response.json(payload),
      );
      assert.equal(response.status, 502);
      assert.deepEqual(await response.json(), {
        error: "upstream_invalid_response",
      });
    }
  });
});
