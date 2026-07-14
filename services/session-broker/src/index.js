const OPENAI_CLIENT_SECRET_URL = "https://api.openai.com/v1/realtime/client_secrets";
const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses";
const REALTIME_UPSTREAM_TIMEOUT_MS = 10_000;

const RESTAURANT_SCENE_ID = "restaurant";
const RESTAURANT_OBLIGATION_ID = "restaurant.party-size.one";
const RESTAURANT_REPAIR_SEGMENT_ID = "restaurant.arrival.kochira-e-dozo";

export const learningPlannerPolicy = Object.freeze({
  model: "gpt-5.6-sol",
  reasoningEffort: "low",
  maxOutputTokens: 320,
  upstreamTimeoutMs: 7_000,
  maxAttempts: 2,
});

export const learningActionSchema = Object.freeze({
  type: "object",
  additionalProperties: false,
  properties: {
    action: {
      type: "string",
      enum: [
        "repeat",
        "reduce_scaffold",
        "isolate_segment",
        "advance",
        "abstain",
      ],
    },
    reason: {
      type: "string",
      enum: [
        "completed_after_repair",
        "incomplete_self_report",
        "speech_presence_missing",
        "scaffold_still_present",
        "repair_needed",
        "insufficient_evidence",
      ],
    },
    explanation_es: { type: "string" },
    obligation_id: { type: "string" },
  },
  required: ["action", "reason", "explanation_es", "obligation_id"],
});

export const guidedLearningActionSchema = Object.freeze({
  type: "object",
  additionalProperties: false,
  properties: {
    action: {
      type: "string",
      enum: ["repeat", "reduce_scaffold", "advance", "abstain"],
    },
    reason: {
      type: "string",
      enum: [
        "review_unclear",
        "target_close",
        "target_not_matched",
        "matched_with_support",
        "matched_without_support",
        "insufficient_evidence",
      ],
    },
    obligation_id: { type: "string" },
  },
  required: ["action", "reason", "obligation_id"],
});

const learningPlannerInstructions = [
  "You are MA's bounded post-lesson pedagogy planner for one zero-beginner Japanese restaurant obligation.",
  "Use only the supplied structured facts. Never infer a transcript, pronunciation quality, identity, or retained audio.",
  "Choose exactly one allowed action. Advance only when current_obligation_completed is true.",
  "If evidence is contradictory or insufficient, abstain.",
  "Write one plain-Spanish explanation of at most 140 characters and do not add facts beyond the selected reason code.",
].join(" ");

const guidedLearningPlannerInstructions = [
  "You are MA's bounded post-lesson planner for one zero-beginner Japanese restaurant obligation.",
  "Use only two aggregate qualitative Realtime review summaries and their visible-support level.",
  "Never infer a transcript, pronunciation quality, identity, confidence, score, mastery, or retained audio.",
  "Advance only when the restaurant turn matched with scaffold=none.",
  "If the final review is unclear, close, or different, repeat. If it matched with visible support, reduce scaffold.",
  "If evidence is contradictory or insufficient, abstain.",
].join(" ");

const canonicalActionExplanations = Object.freeze({
  repeat: "Repite la misma respuesta antes de cambiar de situación.",
  reduce_scaffold: "Haz otro intento con menos ayuda visible.",
  isolate_segment: "Aísla una parte breve antes de volver a la situación.",
  advance: "Ya puedes pasar al siguiente objetivo práctico.",
  abstain: "Mantén el plan local porque faltan hechos suficientes.",
});

const canonicalEvidenceReasons = Object.freeze({
  completed_after_repair: "Confirmaste la misma obligación después de una reparación.",
  incomplete_self_report: "Marcaste el intento más reciente como incompleto.",
  speech_presence_missing: "No hubo señal local suficiente de voz en el intento.",
  scaffold_still_present: "El intento más reciente todavía usó ayuda visible.",
  repair_needed: "El intento siguió incompleto después de pedir ayuda.",
  insufficient_evidence: "Los hechos disponibles no justifican cambiar de objetivo.",
});

const canonicalGuidedActionExplanations = Object.freeze({
  repeat: {
    en: "Repeat hitori desu with the model before another scene.",
    es: "Repite hitori desu con el modelo antes de otra escena.",
  },
  reduce_scaffold: {
    en: "Try the same exchange again with less visible help.",
    es: "Haz el mismo intercambio otra vez con menos ayuda visible.",
  },
  advance: {
    en: "Try a new beginner scene while keeping this phrase as support.",
    es: "Prueba otra escena inicial conservando esta frase como apoyo.",
  },
  abstain: {
    en: "Keep the local plan because the available facts are not enough.",
    es: "Mantén el plan local porque los hechos disponibles no bastan.",
  },
});

const canonicalGuidedEvidenceReasons = Object.freeze({
  review_unclear: {
    en: "The restaurant-turn review could not verify the words.",
    es: "La revisión del turno no pudo verificar las palabras.",
  },
  target_close: {
    en: "The restaurant answer was close to the expected phrase.",
    es: "La respuesta del restaurante fue cercana a la frase esperada.",
  },
  target_not_matched: {
    en: "The restaurant answer did not match the expected phrase.",
    es: "La respuesta del restaurante no coincidió con la frase esperada.",
  },
  matched_with_support: {
    en: "MA recognized the expected answer while it was visible.",
    es: "MA reconoció la respuesta esperada mientras estaba visible.",
  },
  matched_without_support: {
    en: "MA recognized the expected answer without visible help.",
    es: "MA reconoció la respuesta esperada sin ayuda visible.",
  },
  insufficient_evidence: {
    en: "The aggregate lesson facts do not justify a change.",
    es: "Los hechos agregados de la lección no justifican un cambio.",
  },
});

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

export const learnerAttemptFeedbackSchema = Object.freeze({
  type: "object",
  additionalProperties: false,
  properties: {
    target_phrase_id: {
      type: "string",
      enum: ["restaurant.party-size.hitori-desu"],
    },
    assessment: {
      type: "string",
      enum: ["matched", "close", "different", "unclear"],
    },
    evidence_code: {
      type: "string",
      enum: [
        "full_target_in_transcript",
        "partial_target_in_transcript",
        "speech_turn_completed",
        "audio_unclear",
      ],
    },
    retry_focus_code: {
      type: "string",
      enum: [
        "use_with_waiter",
        "complete_target",
        "use_visible_phrase",
        "move_closer",
      ],
    },
  },
  required: [
    "target_phrase_id",
    "assessment",
    "evidence_code",
    "retry_focus_code",
  ],
});

export const reportAttemptTool = Object.freeze({
  type: "function",
  name: "report_attempt",
  description: [
    "Return one conservative qualitative review of the just-committed learner attempt.",
    "Use only the declared evidence and retry-focus enum codes; never author learner-facing prose.",
    "Never return a numeric pronunciation, fluency, confidence, or mastery score.",
    "If the audio is ambiguous, use assessment=unclear, evidence_code=audio_unclear, and retry_focus_code=move_closer.",
  ].join(" "),
  parameters: learnerAttemptFeedbackSchema,
});

export const didacticRealtimeSessionPolicy = Object.freeze({
  type: "realtime",
  model: "gpt-realtime-2.1",
  output_modalities: ["audio"],
  max_output_tokens: 512,
  instructions: [
    "You are MA, a patient English- or Spanish-speaking Japanese coach for a genuine zero-level learner.",
    "The fixed target is 一人です (hitori desu), meaning one person, in a restaurant.",
    "Use the interface language explicitly named in each response request; default to English. Use Japanese only for the visible target, a short model, or one brief waiter turn.",
    "Never produce an unexplained Japanese monologue.",
    "The app owns push-to-talk, turn order, retry, and progression.",
    "When explicitly asked to review the committed attempt, call report_attempt exactly once.",
    "The tool response contains only assessment/evidence/focus codes; the app supplies canonical English and Spanish feedback.",
    "Be conservative: if you cannot verify what was said, report unclear rather than guessing.",
    "Never give numeric pronunciation, fluency, confidence, or mastery scores and never claim phoneme-level measurement.",
    "Give at most one concrete retry focus. Spoken feedback must be no more than two short sentences.",
  ].join(" "),
  tools: [reportAttemptTool],
  tool_choice: "none",
  tracing: null,
  audio: {
    input: {
      format: {
        type: "audio/pcm",
        rate: 24_000,
      },
      noise_reduction: {
        type: "near_field",
      },
      transcription: {
        model: "gpt-4o-mini-transcribe-2025-12-15",
        language: "ja",
        prompt: "一人です。ひとりです。hitori desu。レストランで一名と答える短い練習。",
      },
      turn_detection: null,
    },
    output: {
      format: {
        type: "audio/pcm",
        rate: 24_000,
      },
      voice: "marin",
      speed: 0.92,
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

  const isProbeRealtime =
    request.method === "POST" && url.pathname === "/realtime/client-secret";
  const isProductRealtime =
    request.method === "POST" && url.pathname === "/product/realtime/client-secret";
  const isLearning =
    request.method === "POST" && url.pathname === "/learning/next";
  const isGuidedLearning =
    request.method === "POST" && url.pathname === "/learning/guided-next";
  if (!isProbeRealtime && !isProductRealtime && !isLearning && !isGuidedLearning) {
    return jsonResponse(404, { error: "not_found" });
  }

  const role = isProbeRealtime ? "probe" : "product";
  if (!hasRequiredBindings(env, role)) {
    return jsonResponse(503, { error: "service_unavailable" });
  }

  const authorization = request.headers.get("authorization");
  const installToken = role === "probe"
    ? env.MA_INSTALL_TOKEN
    : env.MA_PRODUCT_INSTALL_TOKEN;
  if (!(await constantTimeEqual(
    authorization ?? "",
    `Bearer ${installToken}`,
  ))) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  const safetyIdentifier = await makeSafetyIdentifier(
    env.MA_SAFETY_SALT,
    installToken,
  );
  let rateLimit;
  try {
    rateLimit = await env.RATE_LIMITER.limit({
      key: `${safetyIdentifier}:${isGuidedLearning
        ? "guided-learning"
        : isLearning ? "learning" : `${role}-realtime`}`,
    });
  } catch {
    return jsonResponse(503, { error: "service_unavailable" });
  }
  if (!rateLimit.success) {
    return jsonResponse(429, { error: "rate_limited" }, { "retry-after": "60" });
  }

  // Consume the endpoint-specific authenticated quota before reading any
  // caller body. A malformed or oversized request must not become a free body
  // parsing path for a leaked private-demo credential.
  let bodyResult;
  if (isProbeRealtime || isProductRealtime) {
    bodyResult = await parseEmptyObjectBody(request);
  } else if (isGuidedLearning) {
    bodyResult = await parseGuidedLearningReportBody(request);
  } else {
    bodyResult = await parseLearningReportBody(request);
  }
  if (!bodyResult.ok) {
    return jsonResponse(400, { error: bodyResult.error });
  }

  if (isLearning) {
    return handleLearningNext(
      bodyResult.value,
      env,
      safetyIdentifier,
      upstreamFetch,
    );
  }
  if (isGuidedLearning) {
    return handleGuidedLearningNext(
      bodyResult.value,
      env,
      safetyIdentifier,
      upstreamFetch,
    );
  }
  const policy = isProductRealtime
    ? didacticRealtimeSessionPolicy
    : realtimeSessionPolicy;
  return handleRealtimeClientSecret(
    env,
    safetyIdentifier,
    policy,
    upstreamFetch,
  );
}

async function handleRealtimeClientSecret(
  env,
  safetyIdentifier,
  sessionPolicy,
  upstreamFetch,
) {
  const expectedConfigurationHash = await sha256Hex(
    stableStringify(sessionPolicy),
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
        session: sessionPolicy,
      }),
      signal: AbortSignal.timeout(REALTIME_UPSTREAM_TIMEOUT_MS),
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

async function handleLearningNext(
  learningReport,
  env,
  safetyIdentifier,
  upstreamFetch,
) {
  const upstreamBody = {
    model: learningPlannerPolicy.model,
    instructions: learningPlannerInstructions,
    input: [
      {
        role: "user",
        content: [
          {
            type: "input_text",
            text: JSON.stringify({
              learning_report: modelSafeLearningReport(learningReport),
            }),
          },
        ],
      },
    ],
    text: {
      format: {
        type: "json_schema",
        name: "ma_next_learning_action",
        strict: true,
        schema: learningActionSchema,
      },
      verbosity: "low",
    },
    reasoning: { effort: learningPlannerPolicy.reasoningEffort },
    max_output_tokens: learningPlannerPolicy.maxOutputTokens,
    safety_identifier: safetyIdentifier,
    store: false,
  };

  let upstreamResponse;
  for (let attempt = 0; attempt < learningPlannerPolicy.maxAttempts; attempt += 1) {
    try {
      upstreamResponse = await upstreamFetch(OPENAI_RESPONSES_URL, {
        method: "POST",
        headers: {
          authorization: `Bearer ${env.OPENAI_API_KEY}`,
          "content-type": "application/json",
        },
        body: JSON.stringify(upstreamBody),
        signal: AbortSignal.timeout(learningPlannerPolicy.upstreamTimeoutMs),
      });
    } catch {
      if (attempt + 1 < learningPlannerPolicy.maxAttempts) {
        continue;
      }
      return jsonResponse(502, { error: "upstream_unavailable" });
    }

    if (upstreamResponse.ok) {
      break;
    }
    if (
      attempt + 1 < learningPlannerPolicy.maxAttempts &&
      isRetryableUpstreamStatus(upstreamResponse.status)
    ) {
      continue;
    }
    return jsonResponse(502, { error: "upstream_rejected" });
  }

  if (!upstreamResponse?.ok) {
    return jsonResponse(502, { error: "upstream_unavailable" });
  }

  let payload;
  try {
    payload = await upstreamResponse.json();
  } catch {
    return jsonResponse(502, { error: "upstream_invalid_response" });
  }

  const recommendationResult = parseLearningRecommendation(
    payload,
    learningReport,
  );
  if (!recommendationResult.ok) {
    return jsonResponse(502, { error: "upstream_invalid_response" });
  }

  return jsonResponse(200, {
    schema_version: 1,
    report_id: learningReport.report_id,
    model: learningPlannerPolicy.model,
    source: "model",
    ...recommendationResult.value,
  });
}

async function handleGuidedLearningNext(
  learningReport,
  env,
  safetyIdentifier,
  upstreamFetch,
) {
  const upstreamBody = {
    model: learningPlannerPolicy.model,
    instructions: guidedLearningPlannerInstructions,
    input: [
      {
        role: "user",
        content: [
          {
            type: "input_text",
            text: JSON.stringify({
              learning_report: modelSafeGuidedLearningReport(learningReport),
            }),
          },
        ],
      },
    ],
    text: {
      format: {
        type: "json_schema",
        name: "ma_guided_next_learning_action",
        strict: true,
        schema: guidedLearningActionSchema,
      },
      verbosity: "low",
    },
    reasoning: { effort: learningPlannerPolicy.reasoningEffort },
    max_output_tokens: learningPlannerPolicy.maxOutputTokens,
    safety_identifier: safetyIdentifier,
    store: false,
  };

  let upstreamResponse;
  for (let attempt = 0; attempt < learningPlannerPolicy.maxAttempts; attempt += 1) {
    try {
      upstreamResponse = await upstreamFetch(OPENAI_RESPONSES_URL, {
        method: "POST",
        headers: {
          authorization: `Bearer ${env.OPENAI_API_KEY}`,
          "content-type": "application/json",
        },
        body: JSON.stringify(upstreamBody),
        signal: AbortSignal.timeout(learningPlannerPolicy.upstreamTimeoutMs),
      });
    } catch {
      if (attempt + 1 < learningPlannerPolicy.maxAttempts) {
        continue;
      }
      return jsonResponse(502, { error: "upstream_unavailable" });
    }
    if (upstreamResponse.ok) {
      break;
    }
    if (
      attempt + 1 < learningPlannerPolicy.maxAttempts &&
      isRetryableUpstreamStatus(upstreamResponse.status)
    ) {
      continue;
    }
    return jsonResponse(502, { error: "upstream_rejected" });
  }

  if (!upstreamResponse?.ok) {
    return jsonResponse(502, { error: "upstream_unavailable" });
  }
  let payload;
  try {
    payload = await upstreamResponse.json();
  } catch {
    return jsonResponse(502, { error: "upstream_invalid_response" });
  }
  const recommendationResult = parseGuidedLearningRecommendation(
    payload,
    learningReport,
  );
  if (!recommendationResult.ok) {
    return jsonResponse(502, { error: "upstream_invalid_response" });
  }
  return jsonResponse(200, {
    schema_version: 2,
    report_id: learningReport.report_id,
    model: learningPlannerPolicy.model,
    source: "model",
    ...recommendationResult.value,
  });
}

function parseGuidedLearningRecommendation(payload, report) {
  if (
    payload?.status !== "completed" ||
    payload.error != null ||
    payload.incomplete_details != null ||
    !Array.isArray(payload?.output)
  ) {
    return { ok: false };
  }
  const messages = [];
  for (const item of payload.output) {
    if (item?.type === "reasoning") {
      continue;
    }
    if (item?.type !== "message" || !Array.isArray(item.content)) {
      return { ok: false };
    }
    messages.push(item);
  }
  if (
    messages.length !== 1 ||
    messages[0].content.length !== 1 ||
    messages[0].content[0]?.type !== "output_text" ||
    typeof messages[0].content[0].text !== "string" ||
    messages[0].content[0].text.length > 4_096
  ) {
    return { ok: false };
  }
  let value;
  try {
    value = JSON.parse(messages[0].content[0].text);
  } catch {
    return { ok: false };
  }
  return validateGuidedLearningRecommendation(value, report);
}

function validateGuidedLearningRecommendation(value, report) {
  if (!isPlainObject(value) || !hasExactKeys(value, [
    "action",
    "reason",
    "obligation_id",
  ])) {
    return { ok: false };
  }
  if (
    !guidedLearningActionSchema.properties.action.enum.includes(value.action) ||
    !guidedLearningActionSchema.properties.reason.enum.includes(value.reason) ||
    value.obligation_id !== report.scene_plan.obligation_id ||
    !isGuidedActionReasonSupported(value.action, value.reason, report)
  ) {
    return { ok: false };
  }
  const explanation = canonicalGuidedActionExplanations[value.action];
  const evidence = canonicalGuidedEvidenceReasons[value.reason];
  if (!explanation || !evidence) {
    return { ok: false };
  }
  return {
    ok: true,
    value: {
      action: value.action,
      reason: value.reason,
      explanation_en: explanation.en,
      explanation_es: explanation.es,
      evidence_reason_en: evidence.en,
      evidence_reason_es: evidence.es,
      obligation_id: value.obligation_id,
    },
  };
}

function isGuidedActionReasonSupported(action, reason, report) {
  const restaurant = report.attempt_summary.restaurant_turn;
  switch (`${action}:${reason}`) {
    case "repeat:review_unclear":
      return restaurant.last_review === "unclear";
    case "repeat:target_close":
      return restaurant.last_review === "close";
    case "repeat:target_not_matched":
      return restaurant.last_review === "different";
    case "reduce_scaffold:matched_with_support":
      return restaurant.last_review === "matched" && restaurant.scaffold === "full";
    case "advance:matched_without_support":
      return restaurant.last_review === "matched" && restaurant.scaffold === "none";
    case "abstain:insufficient_evidence":
      return true;
    default:
      return false;
  }
}

function isRetryableUpstreamStatus(status) {
  return status === 408 || status === 409 || status === 429 || status >= 500;
}

function parseLearningRecommendation(payload, report) {
  if (
    payload?.status !== "completed" ||
    payload.error != null ||
    payload.incomplete_details != null
  ) {
    return { ok: false };
  }
  if (!Array.isArray(payload?.output)) {
    return { ok: false };
  }

  const messages = [];
  for (const item of payload.output) {
    if (item?.type === "reasoning") {
      continue;
    }
    if (item?.type !== "message" || !Array.isArray(item.content)) {
      return { ok: false };
    }
    messages.push(item);
  }
  if (
    messages.length !== 1 ||
    messages[0].content.length !== 1 ||
    messages[0].content[0]?.type !== "output_text" ||
    typeof messages[0].content[0].text !== "string" ||
    messages[0].content[0].text.length > 4_096
  ) {
    return { ok: false };
  }

  let value;
  try {
    value = JSON.parse(messages[0].content[0].text);
  } catch {
    return { ok: false };
  }
  return validateLearningRecommendation(value, report);
}

function validateLearningRecommendation(value, report) {
  if (!isPlainObject(value)) {
    return { ok: false };
  }
  if (!hasExactKeys(value, [
    "action",
    "reason",
    "explanation_es",
    "obligation_id",
  ])) {
    return { ok: false };
  }

  const allowedActions = new Set(learningActionSchema.properties.action.enum);
  const allowedReasons = new Set(learningActionSchema.properties.reason.enum);
  if (!allowedActions.has(value.action) || !allowedReasons.has(value.reason)) {
    return { ok: false };
  }
  if (value.obligation_id !== report.scene_plan.obligation_id) {
    return { ok: false };
  }
  const explanation = normalizedBoundedString(value.explanation_es, 1, 140);
  if (explanation === null) {
    return { ok: false };
  }

  const lastAttempt = report.attempts.at(-1);
  if (!isActionSupported(value.action, report, lastAttempt)) {
    return { ok: false };
  }
  if (!isReasonSupported(value.reason, report, lastAttempt)) {
    return { ok: false };
  }
  if (!isActionReasonPairSupported(value.action, value.reason)) {
    return { ok: false };
  }

  return {
    ok: true,
    value: {
      action: value.action,
      reason: value.reason,
      explanation_es: canonicalActionExplanations[value.action],
      evidence_reason_es: canonicalEvidenceReasons[value.reason],
      obligation_id: value.obligation_id,
    },
  };
}

function isActionReasonPairSupported(action, reason) {
  const allowedReasons = {
    repeat: new Set(["incomplete_self_report", "speech_presence_missing"]),
    reduce_scaffold: new Set(["scaffold_still_present"]),
    isolate_segment: new Set(["repair_needed", "speech_presence_missing"]),
    advance: new Set(["completed_after_repair"]),
    abstain: new Set(["insufficient_evidence"]),
  };
  return allowedReasons[action]?.has(reason) === true;
}

function isActionSupported(action, report, lastAttempt) {
  switch (action) {
    case "advance":
      return report.current_obligation_completed === true;
    case "reduce_scaffold":
      return lastAttempt.self_reported_completed && lastAttempt.scaffold !== "none";
    case "isolate_segment":
      return lastAttempt.repair_count > 0;
    case "repeat":
    case "abstain":
      return true;
    default:
      return false;
  }
}

function isReasonSupported(reason, report, lastAttempt) {
  switch (reason) {
    case "completed_after_repair":
      return report.current_obligation_completed && lastAttempt.repair_count > 0;
    case "incomplete_self_report":
      return !lastAttempt.self_reported_completed;
    case "speech_presence_missing":
      return !lastAttempt.speech_presence_detected;
    case "scaffold_still_present":
      return lastAttempt.scaffold !== "none";
    case "repair_needed":
      return !lastAttempt.self_reported_completed && lastAttempt.repair_count > 0;
    case "insufficient_evidence":
      return true;
    default:
      return false;
  }
}

function hasRequiredBindings(env, role) {
  const probeToken = env?.MA_INSTALL_TOKEN;
  const productToken = env?.MA_PRODUCT_INSTALL_TOKEN;
  return (
    typeof env?.OPENAI_API_KEY === "string" &&
    env.OPENAI_API_KEY.length > 0 &&
    isValidInstallToken(role === "probe" ? probeToken : productToken) &&
    isValidInstallToken(probeToken) &&
    isValidInstallToken(productToken) &&
    probeToken !== productToken &&
    typeof env?.MA_SAFETY_SALT === "string" &&
    env.MA_SAFETY_SALT.length > 0 &&
    env?.RATE_LIMITER !== undefined &&
    env.RATE_LIMITER !== null
  );
}

function isValidInstallToken(token) {
  return typeof token === "string" &&
    token.length >= 32 &&
    token.length <= 512 &&
    !/[\u0000-\u0020\u007f]/u.test(token);
}

async function parseEmptyObjectBody(request) {
  if (!hasJSONContentType(request)) {
    return { ok: false, error: "invalid_content_type" };
  }
  const body = await readBoundedBody(request, 256);
  if (!body.ok) {
    return { ok: false, error: "invalid_request" };
  }
  const text = body.text;
  if (text.trim().length === 0) {
    return { ok: true, value: {} };
  }

  let value;
  try {
    value = JSON.parse(text);
  } catch {
    return { ok: false, error: "invalid_json" };
  }

  if (!isPlainObject(value)) {
    return { ok: false, error: "invalid_request" };
  }
  if (Object.keys(value).length > 0) {
    return { ok: false, error: "caller_configuration_forbidden" };
  }
  return { ok: true, value };
}

async function parseLearningReportBody(request) {
  if (!hasJSONContentType(request)) {
    return { ok: false, error: "invalid_content_type" };
  }
  const body = await readBoundedBody(request, 16_384);
  if (!body.ok || body.text.length === 0) {
    return { ok: false, error: "invalid_learning_report" };
  }
  const text = body.text;

  let value;
  try {
    value = JSON.parse(text);
  } catch {
    return { ok: false, error: "invalid_json" };
  }

  if (!validateLearningReport(value)) {
    return { ok: false, error: "invalid_learning_report" };
  }
  return { ok: true, value };
}

async function parseGuidedLearningReportBody(request) {
  if (!hasJSONContentType(request)) {
    return { ok: false, error: "invalid_content_type" };
  }
  const body = await readBoundedBody(request, 16_384);
  if (!body.ok || body.text.length === 0) {
    return { ok: false, error: "invalid_guided_learning_report" };
  }
  const text = body.text;
  let value;
  try {
    value = JSON.parse(text);
  } catch {
    return { ok: false, error: "invalid_json" };
  }
  if (!validateGuidedLearningReport(value)) {
    return { ok: false, error: "invalid_guided_learning_report" };
  }
  return { ok: true, value };
}

function hasJSONContentType(request) {
  const rawValue = request.headers.get("content-type") ?? "";
  const mediaType = rawValue.split(";", 1)[0].trim().toLowerCase();
  return mediaType === "application/json";
}

async function readBoundedBody(request, maximumBytes) {
  const rawLength = request.headers.get("content-length");
  if (rawLength !== null) {
    if (!/^(0|[1-9][0-9]*)$/u.test(rawLength)) {
      return { ok: false };
    }
    const declaredLength = Number(rawLength);
    if (!Number.isSafeInteger(declaredLength) || declaredLength > maximumBytes) {
      return { ok: false };
    }
  }

  if (request.body === null) {
    return { ok: true, text: "" };
  }
  const reader = request.body.getReader();
  const decoder = new TextDecoder("utf-8", { fatal: true });
  let bytesRead = 0;
  let text = "";
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        text += decoder.decode();
        return { ok: true, text };
      }
      bytesRead += value.byteLength;
      if (bytesRead > maximumBytes) {
        await reader.cancel();
        return { ok: false };
      }
      text += decoder.decode(value, { stream: true });
    }
  } catch {
    try {
      await reader.cancel();
    } catch {
      // The body already failed; cancellation is best-effort only.
    }
    return { ok: false };
  }
}

function validateGuidedLearningReport(value) {
  if (!isPlainObject(value) || !hasExactKeys(value, [
    "schema_version",
    "report_id",
    "scene_plan",
    "attempt_summary",
    "lesson_finished",
    "raw_audio_included",
    "transcript_included",
    "self_assessment_included",
  ])) {
    return false;
  }
  if (
    value.schema_version !== 2 ||
    !isUUIDString(value.report_id) ||
    value.lesson_finished !== true ||
    value.raw_audio_included !== false ||
    value.transcript_included !== false ||
    value.self_assessment_included !== false ||
    !validateRestaurantScenePlan(value.scene_plan)
  ) {
    return false;
  }
  const summary = value.attempt_summary;
  return isPlainObject(summary) && hasExactKeys(summary, [
    "taught_phrase",
    "restaurant_turn",
  ]) && validateGuidedStageSummary(summary.taught_phrase)
    && validateGuidedStageSummary(summary.restaurant_turn);
}

function validateRestaurantScenePlan(plan) {
  return isPlainObject(plan) && hasExactKeys(plan, [
    "scene_id",
    "obligation_id",
    "learner_level",
    "target_phrase_id",
  ]) && plan.scene_id === RESTAURANT_SCENE_ID
    && plan.obligation_id === RESTAURANT_OBLIGATION_ID
    && plan.learner_level === "zero_beginner"
    && plan.target_phrase_id === "restaurant.party-size.hitori-desu";
}

function validateGuidedStageSummary(summary) {
  return isPlainObject(summary) && hasExactKeys(summary, [
    "attempt_count",
    "last_review",
    "scaffold",
  ]) && isIntegerInRange(summary.attempt_count, 1, 8)
    && ["matched", "close", "different", "unclear"].includes(summary.last_review)
    && ["full", "none"].includes(summary.scaffold);
}

function validateLearningReport(value) {
  if (!isPlainObject(value) || !hasExactKeys(value, [
    "schema_version",
    "report_id",
    "scene_plan",
    "attempts",
    "current_obligation_completed",
    "repair_segment_id",
    "raw_audio_included",
  ])) {
    return false;
  }
  if (
    value.schema_version !== 1 ||
    !isUUIDString(value.report_id) ||
    value.raw_audio_included !== false
  ) {
    return false;
  }

  const plan = value.scene_plan;
  if (!isPlainObject(plan) || !hasExactKeys(plan, [
    "scene_id",
    "obligation_id",
    "learner_level",
    "target_phrase_id",
  ])) {
    return false;
  }
  if (
    plan.scene_id !== RESTAURANT_SCENE_ID ||
    plan.obligation_id !== RESTAURANT_OBLIGATION_ID ||
    plan.learner_level !== "zero_beginner" ||
    plan.target_phrase_id !== "restaurant.party-size.hitori-desu" ||
    value.repair_segment_id !== RESTAURANT_REPAIR_SEGMENT_ID
  ) {
    return false;
  }
  if (
    typeof value.current_obligation_completed !== "boolean" ||
    !Array.isArray(value.attempts) ||
    value.attempts.length !== 2
  ) {
    return false;
  }

  const attempts = value.attempts;
  if (!attempts.every((attempt) => validateLearningAttempt(attempt, plan))) {
    return false;
  }
  if (
    attempts[0].attempt_number >= attempts[1].attempt_number ||
    attempts[0].repair_count !== 0 ||
    attempts[1].repair_count < 1 ||
    attempts[0].id === attempts[1].id ||
    value.current_obligation_completed !== attempts[1].self_reported_completed
  ) {
    return false;
  }
  return true;
}

function validateLearningAttempt(attempt, plan) {
  if (!isPlainObject(attempt) || !hasExactKeys(attempt, [
    "id",
    "obligation_id",
    "scaffold",
    "attempt_number",
    "captured_duration_ms",
    "estimated_voice_onset_ms",
    "speech_presence_detected",
    "self_reported_completed",
    "repair_count",
    "raw_audio_retained",
  ])) {
    return false;
  }
  if (
    !isUUIDString(attempt.id) ||
    attempt.obligation_id !== plan.obligation_id ||
    !["full", "rhythm_only", "none"].includes(attempt.scaffold) ||
    !isIntegerInRange(attempt.attempt_number, 1, 20) ||
    !isIntegerInRange(attempt.captured_duration_ms, 0, 8_000) ||
    typeof attempt.speech_presence_detected !== "boolean" ||
    typeof attempt.self_reported_completed !== "boolean" ||
    !isIntegerInRange(attempt.repair_count, 0, 10) ||
    attempt.raw_audio_retained !== false
  ) {
    return false;
  }
  if (!attempt.speech_presence_detected) {
    return attempt.estimated_voice_onset_ms === null;
  }
  return (
    attempt.captured_duration_ms > 0 &&
    isIntegerInRange(attempt.estimated_voice_onset_ms, 0, 8_000) &&
    attempt.estimated_voice_onset_ms <= attempt.captured_duration_ms
  );
}

function modelSafeLearningReport(report) {
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

function modelSafeGuidedLearningReport(report) {
  return {
    schema_version: report.schema_version,
    scene_plan: report.scene_plan,
    attempt_summary: report.attempt_summary,
    lesson_finished: report.lesson_finished,
  };
}

function isPlainObject(value) {
  return value !== null && !Array.isArray(value) && typeof value === "object";
}

function hasExactKeys(value, expectedKeys) {
  const actual = Object.keys(value).sort();
  const expected = [...expectedKeys].sort();
  return actual.length === expected.length &&
    actual.every((key, index) => key === expected[index]);
}

function isIntegerInRange(value, minimum, maximum) {
  return Number.isInteger(value) && value >= minimum && value <= maximum;
}

function isBoundedString(value, minimum, maximum) {
  return typeof value === "string" &&
    value.length >= minimum &&
    value.length <= maximum &&
    !/[\u0000-\u001f\u007f]/u.test(value);
}

function isUUIDString(value) {
  return typeof value === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/iu.test(value);
}

function normalizedBoundedString(value, minimum, maximum) {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  return isBoundedString(normalized, minimum, maximum) ? normalized : null;
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
