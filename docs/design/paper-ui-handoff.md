# MA — historical Paper UI handoff (fixture-driven, pre-Gate 0)

Original reference: https://app.paper.design/file/01KXF2S5M0T6YNPBRS2S1A66Y3/1-0
Extracted 2026-07-13 via Paper MCP `get_jsx` / `get_computed_styles` on the five
artboard roots. This records the original five-artboard design; it is no longer
the interaction source of truth. The code-first SwiftUI flow now owns
onboarding, home, self-assessment, navigation, accessibility, and fixture
honesty. Values below remain exact to the historical artboards, not screenshots.

Authorization scope: fixture-driven UI only (todo.md §8). No mic capture, no
provider transport, no credentials, no mocked-as-live states.

## Design tokens (verbatim from Paper)

```css
:root {
  --color-paper: #FFFFFF;   /* ground */
  --color-sumi: #090A0C;    /* primary ink: headlines, JP text, home indicator */
  --color-stone: #6F7480;   /* secondary text: romaji, captions, meta */
  --color-hairline: #E7E9EE;/* 1px rules, quiet borders */
  --color-ai: #145CFF;      /* the single accent: voice ink, live state, CTAs */
  --color-mist: #EAF1FF;    /* ai wash: halos, chips, micro-lesson card */
  --font-latin: Inter;              /* Spanish/Latin */
  --font-jp: "Hiragino Sans";       /* all Japanese; weight W6 (600) for display */
  --text-micro: 10px;    /* ALL-CAPS meta only, tracking 0.12em */
  --text-caption: 13px;
  --text-body: 16px;
  --text-heading: 20px;
  --text-title: 28px;
  --text-display: 36px;  /* line-height 40px, tracking -0.02em, weight 800 */
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-heavy: 800;
  --tracking-tight: -0.02em;
  --tracking-caps: 0.12em;
  --spacing-2: 8px; --spacing-3: 12px; --spacing-4: 16px;
  --spacing-6: 24px; /* page side margin */ --spacing-8: 32px; --spacing-12: 48px;
  --radius-chip: 10px; --radius-card: 20px; --radius-pill: 999px;
}
```

## Layout constants (identical on all five 390×844 artboards)

- Side margin 24px everywhere; content column 342px.
- Status bar: Apple-standard markup, black tint on white.
- Top chrome: `MA` wordmark (Inter 17/800, +0.02em) + `間` (Hiragino 11/W3,
  stone) left; fixture tag right — pill, 1px hairline border, radius pill,
  padding 4×9, 5px stone dot + 10px/600/0.12em stone label. Label text:
  `PROTOTIPO` (screens 01, 05) / `REPLAY · NO EN VIVO` (02, 03, 04).
- Section kicker: 13px/600/0.12em caps, ai-blue.
- Primary CTA: full-width pill, height 56, bg ai, white Inter 16/600, icon 16–18.
- Home indicator: 140×5 sumi pill, 8px vertical padding.
- Bottom action block bottom padding 8–10px; spacer `flex:1` above it.

## Per-screen exact values

### 01 Learn (`01 Learn — Fase de preparación`)

- Goal header: paddingTop 22; kicker `ESCENA 1 · LLEGAR AL RESTAURANTE`;
  display "Pide una mesa para uno." 36/800/-0.02em, lh 40, maxWidth 300.
- Phrase block: paddingTop 24, row gap 20; left ink rule 4px wide, radius pill,
  bg ai, stretch height. JP 一人です Hiragino 40/600/+0.02em lh 50. Romaji
  "hitori desu" 20/400 stone + 32px ai play dot (14px white triangle). Meaning
  "Una persona · voy solo." 16/500 sumi.
- Rhythm row: paddingLeft 48 (indent under ink rule), label `RITMO · 5 GOLPES`
  micro caps stone; five 48px-wide mist chips radius 10, paddingBlock 8, text
  13/600 ai: hi to ri de su. Caption "Andamio completo…" 13/400 stone lh 18.
- Controls section: paddingTop 24, gap 14; hairline borderTop then paddingTop 20.
  Rows: 40×40 glyph slot (flexShrink 0) + text column. Glyphs (36×36 SVG):
  - はい: circles r15 stroke2 ai, r8.5 stroke1.5 ai @0.45, r2.5 fill ai.
  - すみません: open arc `M 30.5 24 A 15 15 0 1 1 30.5 12` stroke2 round + r5 dot.
  JP 22/600 lh 28 + romaji 13 stone; claim 16/500 sumi; note 13/400 stone.
- CTA: "Escuchar al tutor", icon = ring r7.5 white @0.5 + dot r3 white.

### 02 Listen (`02 Listen — Tutor hablando`)

- State header: paddingTop 24; kicker `EL TUTOR HABLA · VELOCIDAD NATURAL`;
  sub 20/600/-0.02em lh 26 "Tu turno llegará. Escucha la intención, no cada palabra."
- Voice-ink hero (SVG 320×240, centered, paddingTop 20, gap 8). SPEAKING
  geometry — asymmetric loops with a directional bulge to the lower/right, NOT
  concentric circles. Exact paths:
  - mist fill @0.6: `M 152 54 C 184 46, 218 60, 230 84 C 240 102, 234 112, 246 128 C 256 144, 242 168, 218 180 C 194 192, 162 196, 140 187 C 114 177, 96 158, 92 132 C 88 104, 116 62, 152 54 Z`
  - outer stroke 1.5 @0.22: `M 150 28 C 198 18, 248 40, 262 74 C 272 98, 264 112, 280 134 C 294 156, 274 192, 240 206 C 206 220, 158 226, 126 213 C 94 200, 68 174, 64 140 C 60 102, 100 38, 150 28 Z`
  - mid stroke 2 @0.5: `M 152 52 C 186 44, 220 58, 232 84 C 242 104, 234 114, 246 130 C 258 146, 244 170, 219 182 C 194 194, 161 197, 138 188 C 112 178, 94 158, 90 132 C 86 102, 114 60, 152 52 Z`
  - inner stroke 2.5 @1: `M 152 80 C 178 74, 202 86, 210 104 C 217 118, 211 126, 219 138 C 226 149, 216 163, 198 170 C 180 177, 156 178, 141 170 C 124 161, 113 147, 112 130 C 111 108, 128 85, 152 80 Z`
  - center dot cx163 cy126 r4 ai.
  - State label row: `HABLANDO` micro caps ai + "la tinta respira con su voz" micro stone @+0.04em.
- Caption block: full-bleed hairline borderTop, paddingTop 24. JP 何名様ですか
  28/600 lh 34; support row gap 14: "nan-mei-sama desu ka" 13 stone ·
  "¿Cuántas personas?" 13/500 sumi.
- Heard timeline: paddingTop 28; label `LO QUE VAS OYENDO`; track height 28
  gap 6: strokes 34×10 @0.35, 52×14 @0.55, 44×12 @0.75, 60×18 @1 (all ai, radius
  pill), 8px live dot, then `flex:1` hairline 1px. Caption "Cada trazo es un
  golpe de voz que ya escuchaste."
- Bottom: mic state row (6px ai dot + "Te escucha mientras habla. Habla cuando
  quieras." 13/500 sumi — single text node, keep the space after the period);
  two hint chips h48 pill hairline border: はい 16/600 + "sigo contigo" 13 stone;
  すみません + "pausa".

### 03 Hai (`03 Hai — El tutor continúa`)

Diff vs 02 only:
- Kicker `TE OYÓ · EL TUTOR SIGUE HABLANDO`; sub "Dijiste «hai». Lo recibe y no
  se detiene."
- Hero SVG = 02 speaking geometry UNCHANGED (continuity is the message) plus a
  ripple entering from lower-left and *crossing* the outer/mid contours:
  - learner dot cx58 cy200 r5 ai
  - arc 1 stroke 2.5 round: `M 76 176 A 28 28 0 0 1 88 214`
  - arc 2 stroke 2 @0.6: `M 94 156 A 56 56 0 0 1 116 228`
  - arc 3 stroke 1.5 @0.32: `M 114 136 A 86 86 0 0 1 146 236`
- Label `HABLANDO · SIN PAUSA` + "tu onda cruzó la tinta sin romperla".
- Caption JP お一人様ですね。ご案内します; supports stacked column gap 2:
  "o-hitori-sama desu ne · go-annai shimasu" / "Una persona, ¿verdad? Te acompaño."
- Timeline gains a はい marker between strokes 3 and 4: 12×12 ring, border 2.5 ai,
  white fill. Caption "El anillo pequeño es tu はい. La voz del tutor no se cortó."
- はい chip active: border 1.5 ai, bg mist, both texts ai.

### 04 Sumimasen (`04 Sumimasen — Cesión y reparación`)

- Kicker `PEDISTE PAUSA · TE CEDE EL TURNO`; sub "La tinta se recoge. El foco
  ahora es tuyo."
- Yield strip (SVG 342×150, paddingTop 16): tutor contracted small loop
  `M 262 22 C 278 19, 292 28, 294 42 C 296 56, 285 67, 269 68 C 254 69, 241 60, 240 45 C 239 32, 248 24, 262 22 Z`
  stroke 2 @0.38 + dot cx267 cy45 r2.5 @0.38; dotted handoff trace
  `M 236 62 C 200 84, 158 96, 118 98` stroke 1.5 dasharray "1 7" @0.45; learner
  loop `M 74 62 C 96 58, 114 72, 116 92 C 118 112, 102 128, 80 129 C 58 130, 40 116, 39 95 C 38 76, 52 65, 74 62 Z`
  stroke 2.5 @1 + dot cx78 cy95 r5.5. Role labels row: `TÚ · TIENES EL TURNO`
  (ai) left, `TUTOR · EN PAUSA` (stone) right, micro caps.
- Beat section: hairline borderTop pad 16; label
  `LO QUE ESCUCHASTE · ÚLTIMOS 4 SEGUNDOS` (honest name — do not rename).
  Four strokes gap 8: 56×14 @0.35, 72×16 @0.5, **88×22 chosen (border 3 mist,
  full ai)**, 64×14 @0.5. Time marks: "−4 s" left, "momento de tu «sumimasen»"
  right, micro stone. Connector: 2×16 ai bar at paddingLeft 187 — in code,
  derive from the chosen stroke's actual midX (187 = 56+8+72+8+44−1 at these
  fixture widths), never hardcode.
- Micro-lesson card: bg mist radius 20 padding 20 gap 8. `MICRO-LECCIÓN · ESE
  TRAZO` micro ai; こちらへどうぞ 26/600 lh 32; "kochira e dōzo" 13 stone;
  «Por aquí, por favor.» 16/500 sumi; cue "Te está invitando a seguirle. Es un
  gesto amable, no una pregunta." 13 stone lh 18. Buttons h40 pill padding 0 18:
  "Escuchar" solid ai + white play triangle; "Más lento" white bg, ai text.
- CTA "Seguir donde estaba" + arrow icon; caption "El tutor retomará la frase
  en el mismo punto."

### 05 Proof (`05 Proof — Evidencia de aprendizaje`)

- Header: kicker `ESCENA COMPLETADA · TU EVIDENCIA`; display "Segunda vez, con
  menos ayuda." maxWidth 320.
- Attempt rows (paddingTop 32 / 24): head row = micro caps label (`INTENTO 1`
  stone / `INTENTO 2` ai) + `flex:1` hairline + 28px play button (outline
  hairline w/ stone glyph vs solid ai w/ white glyph).
  - Trazos 1 (h20 gap 10): 34×10 @0.4, 18×8 @0.3, 26×10 @0.4, 12×12 ring border
    2 @0.55 (= the rescue), 44×10 @0.4 — hesitant, broken.
  - Trazos 2 (h22 gap 8): 68×16, 96×20, 52×14 all @1 — continuous.
  - Captions: "Con la frase completa a la vista · empezaste a los 3,8 s ·
    1 rescate" (stone) / "Solo con el ritmo · empezaste a los 1,2 s ·
    0 rescates" (sumi).
- Delta: "2,6 s menos de duda." 28/800/-0.02em ai; explainer 13 stone lh 18
  naming the three dimensions (start latency, visible help, rescue count).
- Repaired beat: hairline-top label `EL TRAZO QUE REPARASTE`; 40×12 ai stroke +
  こちらへどうぞ 17/600 + romaji + "«Por aquí, por favor.» · superado en el
  intento 2".
- Bottom: `SIGUIENTE OBJETIVO` / "Pedir mesa para dos" row; CTA "Repetir sin
  ninguna ayuda" with restart icon.

## Historical five-artboard state model

`phraseSetup` → `tutorSpeaking` → (`backchannelAcknowledged` transient overlay,
NOT a mode change; no cancel/clear/truncate) → `floorYielded`
(`takeFloorDetected` → `tutorOutputCancelled` → `heardBeatFrozen(last 4 s
rendered)`) → `resumed` (back into `tutorSpeaking`, same obligation) →
`sessionSummary`. The current SwiftUI product adds onboarding, an intent-first
home, a three-rung coached ladder, explicit learner self-assessment, first
success, and the controls introduction before this sequence.

The current code also replaces the historical `tutorAudioRendered` /
`heardBeatFrozen` fixture vocabulary with provenance-tagged
`timelineBeatAdvanced` / `repairWindowFrozen`. A simulated beat can animate the
timeline but cannot become evidence that audio rendered or was heard.

## Implementation cautions

1. Ripple fires only from a `backchannelDetected` domain event — never a timer
   or button presented as live. Fixture chrome (PROTOTIPO / REPLAY · NO EN
   VIVO) stays on every fixture-backed screen and disappears only from states
   backed by the verdict-permitted real implementation.
2. Timeline strokes = rendered-audio beats from the render clock, not
   transcript tokens.
3. Keep "Últimos 4 segundos" wording until Experiment D passes.
4. Reduce Motion: every animated state has a static/text twin (HABLANDO · SIN
   PAUSA, EN PAUSA, TÚ · TIENES EL TURNO, contour size/opacity). Gate
   breathing/ripple/contraction behind `accessibilityReduceMotion`.
5. Mixed-script strings (はい inside Spanish) need explicit font runs:
   Hiragino Sans for JP, Inter for Latin.
6. Dynamic Type: scale Spanish support text; recompute the 04 connector offset
   from the chosen stroke's real frame.
7. Japanese fixture lines (お一人様ですね。ご案内します / こちらへどうぞ) need
   native-speaker review before anything public.

## SwiftUI implementation notes

- The Paper measurements remain the default-size visual target. Latin support
  copy uses native relative text styles, and Japanese uses Hiragino with a
  relative text style, so accessibility sizes intentionally expand rather than
  preserving fixed pixels.
- The current silent fixture removes the Paper play/listen controls entirely.
  Visual trace actions retain 44pt hit areas without playback iconography.
- Every screen uses an adaptive vertical overflow container. At the reference
  viewport it preserves the spacer/CTA composition; at Accessibility Extra
  Large it scrolls without truncating the learning content.
- Manual UI, previews, and tests reduce one canonical staged fixture. The はい
  wake is keyed from acknowledgement count and wall-clock presentation time;
  fixture media time remains deterministic.
- Fixture actions use explicit `SIMULACIÓN VISUAL`, `DATOS DE MUESTRA`, and
  `SIN AUDIO` copy. Synthetic timing is never presented as learner evidence.
  Live audio remains outside this target until the written verdict permits it.
