import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, it } from "node:test";

import {
  didacticRealtimeSessionPolicy,
  guidedLearningActionSchema,
  handleRequest,
  learnerAttemptFeedbackSchema,
  learningActionSchema,
  learningPlannerPolicy,
  realtimeSessionPolicy,
  reportAttemptTool,
} from "../src/index.js";

const installToken = "t".repeat(48);
const productInstallToken = "p".repeat(48);
const OPENAI_RESPONSES_URL_FOR_TESTS = "https://api.openai.com/v1/responses";
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

function validGuidedLearningReport(overrides = {}) {
  return {
    schema_version: 2,
    report_id: "00000000-0000-4000-8000-000000000011",
    scene_plan: {
      scene_id: "restaurant",
      obligation_id: "restaurant.party-size.one",
      learner_level: "zero_beginner",
      target_phrase_id: "restaurant.party-size.hitori-desu",
    },
    attempt_summary: {
      taught_phrase: {
        attempt_count: 1,
        last_review: "close",
        scaffold: "full",
      },
      restaurant_turn: {
        attempt_count: 1,
        last_review: "matched",
        scaffold: "full",
      },
    },
    lesson_finished: true,
    raw_audio_included: false,
    transcript_included: false,
    self_assessment_included: false,
    ...overrides,
  };
}

function guidedLearningUpstreamResponse(recommendation = {}) {
  return Response.json({
    status: "completed",
    output: [{
      type: "message",
      content: [{
        type: "output_text",
        text: JSON.stringify({
          action: "reduce_scaffold",
          reason: "matched_with_support",
          obligation_id: "restaurant.party-size.one",
          ...recommendation,
        }),
      }],
    }],
  });
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

  it("fails closed when probe and product credentials are identical", async () => {
    const response = await handleRequest(
      request("/product/realtime/client-secret", {
        method: "POST",
        headers: realtimeAuthorizedHeaders(),
        body: "{}",
      }),
      environment({ MA_PRODUCT_INSTALL_TOKEN: installToken }),
      async () => assert.fail("ambiguous roles must not call upstream"),
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

    const productRealtimeWithProbeToken = await handleRequest(
      request("/product/realtime/client-secret", {
        method: "POST",
        headers: realtimeAuthorizedHeaders(),
        body: "{}",
      }),
      environment(),
      async () => assert.fail("cross-role token must not call upstream"),
    );
    assert.equal(productRealtimeWithProbeToken.status, 401);

    const productRealtimeWithProductToken = await handleRequest(
      request("/product/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: "{}",
      }),
      environment(),
      async () => Response.json({
        value: "ek_product_ephemeral_only",
        expires_at: 1234567890,
      }),
    );
    assert.equal(productRealtimeWithProductToken.status, 200);
  });

  it("mints a separate fixed push-to-talk teaching policy for the product", async () => {
    let observedRequest;
    const response = await handleRequest(
      request("/product/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: "{}",
      }),
      environment(),
      async (url, options) => {
        observedRequest = { url, options };
        return Response.json({
          value: "ek_product_ephemeral_only",
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
    assert.equal(
      result.expected_configuration_hash,
      "903205f1f3b40b8fac4b48c9f5ea699c524fae8a27b6aec99abc46c7cc570f8e",
      "The Swift verifier and Worker must share the exact cross-runtime policy hash",
    );
    assert.equal(observedRequest.url, "https://api.openai.com/v1/realtime/client_secrets");
    assert.match(
      observedRequest.options.headers["OpenAI-Safety-Identifier"],
      /^ma_[a-f0-9]{48}$/,
    );

    const upstreamBody = JSON.parse(observedRequest.options.body);
    assert.deepEqual(upstreamBody.session, didacticRealtimeSessionPolicy);
    assert.deepEqual(upstreamBody.session.reasoning, { effort: "low" });
    assert.equal(upstreamBody.session.audio.input.turn_detection, null);
    assert.equal(
      upstreamBody.session.audio.input.transcription.model,
      "gpt-4o-mini-transcribe-2025-12-15",
    );
    assert.equal(upstreamBody.session.audio.input.transcription.language, "ja");
    assert.deepEqual(upstreamBody.session.tools, [reportAttemptTool]);
    assert.deepEqual(reportAttemptTool.parameters, learnerAttemptFeedbackSchema);
    assert.deepEqual(Object.keys(learnerAttemptFeedbackSchema.properties).sort(), [
      "assessment",
      "evidence_code",
      "retry_focus_code",
      "target_phrase_id",
    ]);
    assert.equal(upstreamBody.session.tool_choice, "none");
    assert.equal(upstreamBody.session.tracing, null);
    assert.notDeepEqual(didacticRealtimeSessionPolicy, realtimeSessionPolicy);
    assert.equal(JSON.stringify(result).includes("must-not-be-forwarded"), false);
    assert.equal(JSON.stringify(result).includes(productInstallToken), false);
  });

  it("rejects caller-selected configuration on the product realtime route", async () => {
    const response = await handleRequest(
      request("/product/realtime/client-secret", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify({ tool_choice: "auto" }),
      }),
      environment(),
      async () => assert.fail("caller configuration must not call upstream"),
    );

    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), {
      error: "caller_configuration_forbidden",
    });
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

  it("rejects at the limiter before touching an authenticated request body", async () => {
    let bodyAccesses = 0;
    const guardedRequest = {
      url: "https://broker.test/product/realtime/client-secret",
      method: "POST",
      headers: new Headers(authorizedHeaders()),
      get body() {
        bodyAccesses += 1;
        throw new Error("body must not be read while rate limited");
      },
    };
    const response = await handleRequest(
      guardedRequest,
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
    assert.equal(bodyAccesses, 0);
  });

  it("charges quota before rejecting oversized or dishonest realtime bodies", async () => {
    let limiterCalls = 0;
    const env = environment({
      RATE_LIMITER: {
        async limit() {
          limiterCalls += 1;
          return { success: true };
        },
      },
    });
    const bodies = [
      { body: "x".repeat(2_000_001), contentLength: null },
      { body: "{}", contentLength: "-1" },
      { body: "{}", contentLength: "not-a-number" },
      { body: "x".repeat(300), contentLength: "1" },
    ];

    for (const sample of bodies) {
      const headers = authorizedHeaders();
      if (sample.contentLength !== null) {
        headers["content-length"] = sample.contentLength;
      }
      const response = await handleRequest(
        request("/product/realtime/client-secret", {
          method: "POST",
          headers,
          body: sample.body,
        }),
        env,
        async () => assert.fail("invalid body must not call upstream"),
      );
      assert.equal(response.status, 400);
    }
    assert.equal(limiterCalls, bodies.length);
  });

  it("charges malformed requests to four isolated endpoint buckets", async () => {
    const keys = [];
    const env = environment({
      RATE_LIMITER: {
        async limit({ key }) {
          keys.push(key);
          return { success: true };
        },
      },
    });
    const cases = [
      ["/realtime/client-secret", realtimeAuthorizedHeaders(), "probe-realtime"],
      ["/product/realtime/client-secret", authorizedHeaders(), "product-realtime"],
      ["/learning/next", authorizedHeaders(), "learning"],
      ["/learning/guided-next", authorizedHeaders(), "guided-learning"],
    ];
    for (const [path, headers, suffix] of cases) {
      const response = await handleRequest(
        request(path, { method: "POST", headers, body: "{" }),
        env,
        async () => assert.fail("malformed body must not call upstream"),
      );
      assert.equal(response.status, 400);
      assert.equal(keys.at(-1).endsWith(`:${suffix}`), true, suffix);
    }
    assert.equal(new Set(keys).size, 4);
  });

  it("requires the exact JSON media type on every authenticated route", async () => {
    const cases = [
      {
        path: "/realtime/client-secret",
        headers: realtimeAuthorizedHeaders(),
        body: "{}",
        upstream: () => Response.json({
          value: "ek_probe_ephemeral_only",
          expires_at: 1234567890,
        }),
      },
      {
        path: "/product/realtime/client-secret",
        headers: authorizedHeaders(),
        body: "{}",
        upstream: () => Response.json({
          value: "ek_product_ephemeral_only",
          expires_at: 1234567890,
        }),
      },
      {
        path: "/learning/next",
        headers: authorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
        upstream: learningUpstreamResponse,
      },
      {
        path: "/learning/guided-next",
        headers: authorizedHeaders(),
        body: JSON.stringify(validGuidedLearningReport()),
        upstream: guidedLearningUpstreamResponse,
      },
    ];

    for (const testCase of cases) {
      let limiterCalls = 0;
      let upstreamCalls = 0;
      const env = environment({
        RATE_LIMITER: {
          async limit() {
            limiterCalls += 1;
            return { success: true };
          },
        },
      });
      const invalidMediaTypes = [null, "text/plain", "application/jsonp"];
      for (const mediaType of invalidMediaTypes) {
        const invalidHeaders = new Headers(testCase.headers);
        if (mediaType === null) {
          invalidHeaders.delete("content-type");
        } else {
          invalidHeaders.set("content-type", mediaType);
        }
        const rejected = await handleRequest(
          request(testCase.path, {
            method: "POST",
            headers: invalidHeaders,
            body: testCase.body,
          }),
          env,
          async () => {
            upstreamCalls += 1;
            return testCase.upstream();
          },
        );
        assert.equal(rejected.status, 400, `${testCase.path} ${mediaType}`);
        assert.deepEqual(
          await rejected.json(),
          { error: "invalid_content_type" },
          `${testCase.path} ${mediaType}`,
        );
        assert.equal(upstreamCalls, 0, testCase.path);
      }
      assert.equal(limiterCalls, invalidMediaTypes.length, testCase.path);

      const acceptedHeaders = {
        ...testCase.headers,
        "content-type": "Application/JSON; charset=utf-8",
      };
      const accepted = await handleRequest(
        request(testCase.path, {
          method: "POST",
          headers: acceptedHeaders,
          body: testCase.body,
        }),
        env,
        async () => {
          upstreamCalls += 1;
          return testCase.upstream();
        },
      );
      assert.equal(accepted.status, 200, testCase.path);
      assert.equal(limiterCalls, invalidMediaTypes.length + 1, testCase.path);
      assert.equal(upstreamCalls, 1, testCase.path);
    }
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
    assert.equal(learningPlannerPolicy.upstreamTimeoutMs, 10_000);
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

  it("sends only aggregate guided reviews to fixed gpt-5.6-sol", async () => {
    const report = validGuidedLearningReport();
    let observedRequest;
    const response = await handleRequest(
      request("/learning/guided-next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(report),
      }),
      environment(),
      async (url, options) => {
        observedRequest = { url, options };
        return guidedLearningUpstreamResponse();
      },
    );

    assert.equal(response.status, 200);
    const result = await response.json();
    assert.deepEqual(result, {
      schema_version: 2,
      report_id: report.report_id,
      model: "gpt-5.6-sol",
      source: "model",
      action: "reduce_scaffold",
      reason: "matched_with_support",
      explanation_en: "Try the same exchange again with less visible help.",
      explanation_es: "Haz el mismo intercambio otra vez con menos ayuda visible.",
      evidence_reason_en: "MA recognized the expected answer while it was visible.",
      evidence_reason_es: "MA reconoció la respuesta esperada mientras estaba visible.",
      obligation_id: "restaurant.party-size.one",
    });
    assert.equal(observedRequest.url, "https://api.openai.com/v1/responses");
    const upstreamBody = JSON.parse(observedRequest.options.body);
    assert.equal(upstreamBody.model, "gpt-5.6-sol");
    assert.equal(upstreamBody.store, false);
    assert.deepEqual(upstreamBody.text.format.schema, guidedLearningActionSchema);
    const forwarded = JSON.parse(upstreamBody.input[0].content[0].text);
    assert.deepEqual(forwarded, {
      learning_report: {
        schema_version: 2,
        scene_plan: report.scene_plan,
        attempt_summary: report.attempt_summary,
        lesson_finished: true,
      },
    });
    const serialized = JSON.stringify(forwarded);
    for (const forbidden of [
      "audio",
      "transcript",
      "heard_japanese",
      "feedback",
      "self_assessment",
      "report_id",
    ]) {
      assert.equal(serialized.includes(forbidden), false, forbidden);
    }
  });

  it("retries the guided planner once after a transient upstream timeout", async () => {
    let calls = 0;
    const response = await handleRequest(
      request("/learning/guided-next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validGuidedLearningReport()),
      }),
      environment(),
      async () => {
        calls += 1;
        if (calls === 1) {
          throw new DOMException("The operation timed out", "TimeoutError");
        }
        return guidedLearningUpstreamResponse();
      },
    );

    assert.equal(response.status, 200);
    assert.equal(calls, 2);
    assert.equal(learningPlannerPolicy.maxAttempts, 2);
    assert.equal(learningPlannerPolicy.upstreamTimeoutMs, 10_000);
  });

  it("retries one guided 502 with the identical sanitized fixed request", async () => {
    let limiterCalls = 0;
    const upstreamRequests = [];
    const response = await handleRequest(
      request("/learning/guided-next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validGuidedLearningReport()),
      }),
      environment({
        RATE_LIMITER: {
          async limit() {
            limiterCalls += 1;
            return { success: true };
          },
        },
      }),
      async (url, options) => {
        upstreamRequests.push({ url, options });
        return upstreamRequests.length === 1
          ? new Response("private transient body", { status: 502 })
          : guidedLearningUpstreamResponse();
      },
    );

    assert.equal(response.status, 200);
    assert.equal(limiterCalls, 1);
    assert.equal(upstreamRequests.length, 2);
    assert.equal(upstreamRequests[0].url, OPENAI_RESPONSES_URL_FOR_TESTS);
    assert.equal(upstreamRequests[1].url, OPENAI_RESPONSES_URL_FOR_TESTS);
    assert.equal(upstreamRequests[0].options.method, "POST");
    assert.equal(upstreamRequests[1].options.method, "POST");
    assert.equal(
      upstreamRequests[0].options.headers.authorization,
      "Bearer test-server-api-key",
    );
    assert.equal(
      upstreamRequests[1].options.headers.authorization,
      "Bearer test-server-api-key",
    );
    assert.equal(
      upstreamRequests[0].options.body,
      upstreamRequests[1].options.body,
    );
    assert.ok(upstreamRequests[0].options.signal instanceof AbortSignal);
    assert.ok(upstreamRequests[1].options.signal instanceof AbortSignal);

    const upstreamBody = JSON.parse(upstreamRequests[0].options.body);
    assert.equal(upstreamBody.model, "gpt-5.6-sol");
    assert.equal(upstreamBody.store, false);
    assert.deepEqual(upstreamBody.text.format.schema, guidedLearningActionSchema);
    assert.match(upstreamBody.safety_identifier, /^ma_[a-f0-9]{48}$/);
    const serialized = JSON.stringify(upstreamBody);
    for (const forbidden of [productInstallToken, "test-server-api-key"]) {
      assert.equal(serialized.includes(forbidden), false, forbidden);
    }
    const forwarded = upstreamBody.input[0].content[0].text;
    for (const forbidden of [
      "report_id",
      "raw_audio",
      "transcript",
      "heard_japanese",
    ]) {
      assert.equal(forwarded.includes(forbidden), false, forbidden);
    }
  });

  it("stops guided 502 retries at two without forwarding the upstream body", async () => {
    let calls = 0;
    const response = await handleRequest(
      request("/learning/guided-next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validGuidedLearningReport()),
      }),
      environment(),
      async () => {
        calls += 1;
        return new Response("private upstream diagnostic", { status: 502 });
      },
    );

    assert.equal(calls, 2);
    assert.equal(response.status, 502);
    const body = await response.json();
    assert.deepEqual(body, { error: "upstream_rejected" });
    assert.equal(JSON.stringify(body).includes("private upstream diagnostic"), false);
  });

  it("does not retry permanent or rate-limited guided upstream failures", async () => {
    for (const status of [400, 401, 403, 422, 429]) {
      let calls = 0;
      const response = await handleRequest(
        request("/learning/guided-next", {
          method: "POST",
          headers: authorizedHeaders(),
          body: JSON.stringify(validGuidedLearningReport()),
        }),
        environment(),
        async () => {
          calls += 1;
          return new Response("must not be forwarded", { status });
        },
      );

      assert.equal(calls, 1, `status ${status}`);
      assert.equal(response.status, 502, `status ${status}`);
      assert.deepEqual(await response.json(), { error: "upstream_rejected" });
    }
  });

  it("keeps legacy and guided learning schemas isolated", async () => {
    const guidedOnLegacy = await handleRequest(
      request("/learning/next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validGuidedLearningReport()),
      }),
      environment(),
      async () => assert.fail("guided v2 must not reach the legacy planner"),
    );
    assert.equal(guidedOnLegacy.status, 400);

    const legacyOnGuided = await handleRequest(
      request("/learning/guided-next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(validLearningReport()),
      }),
      environment(),
      async () => assert.fail("legacy v1 must not reach the guided planner"),
    );
    assert.equal(legacyOnGuided.status, 400);
  });

  it("rejects privacy sentinels and out-of-range guided summaries", async () => {
    const invalidReports = [
      validGuidedLearningReport({ raw_audio_included: true }),
      validGuidedLearningReport({ transcript_included: true }),
      validGuidedLearningReport({ self_assessment_included: true }),
      validGuidedLearningReport({
        attempt_summary: {
          ...validGuidedLearningReport().attempt_summary,
          restaurant_turn: {
            attempt_count: 9,
            last_review: "matched",
            scaffold: "full",
          },
        },
      }),
    ];
    for (const report of invalidReports) {
      const response = await handleRequest(
        request("/learning/guided-next", {
          method: "POST",
          headers: authorizedHeaders(),
          body: JSON.stringify(report),
        }),
        environment(),
        async () => assert.fail("invalid guided report must not call upstream"),
      );
      assert.equal(response.status, 400);
    }
  });

  it("prevents guided advance while the answer was visible", async () => {
    const report = validGuidedLearningReport();
    const response = await handleRequest(
      request("/learning/guided-next", {
        method: "POST",
        headers: authorizedHeaders(),
        body: JSON.stringify(report),
      }),
      environment(),
      async () => guidedLearningUpstreamResponse({
        action: "advance",
        reason: "matched_without_support",
      }),
    );
    assert.equal(response.status, 502);
    assert.deepEqual(await response.json(), { error: "upstream_invalid_response" });
  });

  it("accepts every and only evidence-supported guided action pair", async () => {
    const supported = [
      ["unclear", "full", "repeat", "review_unclear"],
      ["close", "full", "repeat", "target_close"],
      ["different", "full", "repeat", "target_not_matched"],
      ["matched", "full", "reduce_scaffold", "matched_with_support"],
      ["matched", "none", "advance", "matched_without_support"],
      ["matched", "full", "abstain", "insufficient_evidence"],
    ];
    for (const [review, scaffold, action, reason] of supported) {
      const report = validGuidedLearningReport();
      report.attempt_summary.restaurant_turn.last_review = review;
      report.attempt_summary.restaurant_turn.scaffold = scaffold;
      const response = await handleRequest(
        request("/learning/guided-next", {
          method: "POST",
          headers: authorizedHeaders(),
          body: JSON.stringify(report),
        }),
        environment(),
        async () => guidedLearningUpstreamResponse({ action, reason }),
      );
      assert.equal(response.status, 200, `${action}:${reason}`);
    }
  });
});
