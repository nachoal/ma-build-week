# Claim-to-evidence matrix

This is the public-claim allow-list. “Pending physical” cannot be upgraded by
code inspection, service verification, or simulator output.

| Proposed claim | Current supporting evidence | Public status |
|---|---|---|
| MA's guided product defaults to English and switches completely to Spanish without resetting lesson progress | Bilingual copy/state tests and guided UI automation | Allowed as implemented behavior |
| MA explains the Japanese phrase, romaji, meaning, and task before audio | Guided state/UI tests | Allowed as implemented behavior |
| One bundled model tap unlocks recording without auto-starting it | Shipping audio owner, real simulator audio integration, and one-tap physical completion transitions in English/Spanish | Allowed for the control transition; human physical audibility pending |
| Learner turns are explicit and bounded; the app writes no recording file | Audio contracts, privacy manifest, capture tests, and a physical real-capture start/stop pass | Allowed for the audited physical capture path; route breadth, human audibility, and semantic review remain pending |
| Learner audio goes directly to OpenAI Realtime; the Worker receives no audio/transcript | Client/Worker architecture and exact request contracts | Allowed for the audited private build |
| MA labels transcription approximate and provides qualitative feedback without a score | UI copy, enum review model, canonical feedback tests | Allowed as implemented behavior |
| Realtime review uses a schema-guided, app-validated enum function call grounded by the approximate transcript | Worker policy, Swift exact validation, adversarial regressions, and physical English/Spanish provider paths with deterministic bundled learner input | Allowed with the deterministic-input qualification; real-microphone semantic review pending |
| The waiter turn is briefed, captioned, and followed by a second reviewed learner turn | Guided UI/provider/state tests and physical English/Spanish provider paths | Allowed for the visible/control sequence; human physical audio/provider quality pending |
| GPT-5.6 chooses an optional bounded next action from aggregate lesson facts | Live private `/learning/guided-next`, strict structured-output tests | Allowed when described as optional planning—not audio review |
| The standard OpenAI key never enters the app or repository | Worker boundary, Keychain design, tracked/history secret scan | Allowed for the audited build |
| Delete all my data verifies that the local Keychain credential is absent before resetting the profile | Transaction ordering tests, isolated real-Keychain round trip, and English/Spanish failure plus success UI tests | Allowed as implemented local behavior; it does not delete provider abuse-monitoring logs |
| Historical deterministic replay has no audio, microphone, network, learner, or planner side effect | Replay isolation + UI tests | Allowed only when labeled **REPLAY · NOT LIVE / NO EN VIVO** and described as historical |
| MA's bounded provider/playback/review/planner path completed on the paired iPhone with deterministic bundled learner input | Retained physical English and Spanish result bundles/logs | Allowed only with the deterministic-input qualification; this is not real-microphone, human-audibility, or learner evidence |
| MA supports open-ended or full-duplex live conversation | Product deliberately uses explicit non-overlap | Prohibited |
| Learner can talk over tutor playback without echo | No physical overlap/AEC evidence | Prohibited |
| Repair replays the exact last audio heard | Experiment D did not run | Prohibited |
| Audible stop latency meets a numeric threshold | No physical acoustic take | Prohibited |
| Realtime returns strict Structured Outputs | Realtime function arguments are schema-guided, then app-validated | Prohibited wording |
| Transcript, pronunciation, fluency, confidence, or mastery is exact/scored | Product exposes none of these claims | Prohibited |
| GPT-5.6 reviews learner audio | GPT-5.6 receives aggregate lesson facts only | Prohibited |
| No learner audio leaves the phone | Explicit audio goes directly to OpenAI Realtime | Prohibited |
| A zero beginner learned or improved | Human outcome study pending | Prohibited until recorded evidence exists |
| Japanese content is natural and pragmatic | Qualified-speaker review pending | Prohibited until signed review exists |
| App is robust across routes, networks, interruptions, or thermal load | Physical matrix pending | Prohibited until the relevant rows pass |

## Judging rubric evidence

| Area | Evidence to show | Remaining gate |
|---|---|---|
| Implementation | Guided state machine, one audio owner, private broker, enum review, bilingual UI, aggregate planner, tests | Refreshed final archive; broader route/interruption/human evidence remains separate |
| Design | Meaning before Japanese, explicit controls, visible support, actionable review, captions, no score | Physical accessibility sweep and cold-viewer comprehension |
| Impact | Learner understands what MA heard and what to do next in one useful restaurant exchange | Real learner observation; no learning claim before it |
| Idea/novelty | Realtime as a didactic loop—model, attempt, grounded feedback, retry, transfer—not an open chat | Cold-viewer comprehension and final demo |

Final audit rule: every spoken line, subtitle, README statement, and Devpost
field must map to an Allowed row or be removed.
