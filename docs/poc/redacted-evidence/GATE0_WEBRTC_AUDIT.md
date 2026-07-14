# Gate 0 native-WebRTC evidence-hook audit

This is a source and shipped-binary API audit performed by the root
implementation task during the prescribed Gate 0 hours 1–1.5 window. It does
not substitute for physical-device evidence of the selected topology.

## Window and immutable inputs

- Prescribed window: 2026-07-14 02:18:10–02:48:10 CST (-0600).
- Root evidence capture began: 2026-07-14 02:18:22 CST (-0600).
- Root evidence capture ended: 2026-07-14 02:48:10 CST (-0600).
- Exact root evidence-capture duration: 29 minutes 48 seconds. The root began
  source capture 12 seconds after the prescribed start, kept the audit open
  through the exact fixed boundary, and does not round this up to 30 minutes.
- Clean repository snapshot at entry: `c9731d5`.
- Readily available binary audited: deprecated CocoaPods
  `GoogleWebRTC 1.1.32000`, whose podspec points to
  `GoogleWebRTC-1.1.31999.tar.gz`.
- Binary archive SHA-256:
  `3110ce96d70eb3df7260ccdfff2861c96220cba3d5a25f7670d43c1c0998e923`.
- Binary metadata: framework build `1.0.31999`, Xcode 11.3 / iPhoneOS 13.2;
  its own README says it is no longer updated and Objective-C only.
- Modern-upstream comparator: WebRTC main commit
  `07e2e3bfa9f65d9ad0401dd372253807427b0069`, re-resolved from the official
  Gitiles remote at audit entry.

No WebRTC package or framework was present in MA before the audit. Nothing was
integrated because the first required hook was absent from the readily
available binary and the plan forbids building a custom WebRTC audio device.

## Required-hook result

| Required hook on one stock owner | Binary result | Modern upstream result | Decision |
|---|---|---|---|
| Empirically post-AEC input PCM | No PCM callback in the shipped Objective-C headers | Stock `AudioDeviceIOS` receives VoiceProcessingIO output internally; the public callback belongs to an app-supplied `RTCAudioDevice` | no immediately usable hook |
| Device-boundary output frames/render position | No playout-frame or render-position API in the shipped headers | Stock `OnGetPlayoutData` and its frame counter are internal. Async aggregate stats expose a global cumulative count, not item-addressable output frames or a synchronous render cursor | no immediately usable hook |
| Immediate local playout stop | `RTCMediaStreamTrack.isEnabled` is only a track switch; `RTCAudioSession.isAudioEnabled = false` explicitly stops both incoming and outgoing audio | Remote-track disable is applied asynchronously as volume zero. `StopPlayout` is internal or delegated to a custom `RTCAudioDevice` | no qualifying local stop |

All three hooks were required. None is exposed together by the audited stock
distribution, so native WebRTC is rejected for Gate 0 without consuming the
optional custom-adaptation hour.

## Evidence behind the decision

### Shipped GoogleWebRTC binary

The immutable archive's public-header manifest contains `RTCAudioTrack.h`,
`RTCAudioSource.h`, `RTCAudioSession.h`, and
`RTCPeerConnectionFactory.h`, but not `RTCAudioDevice.h`.

- `RTCAudioTrack` exposes only its source.
- `RTCAudioSource` exposes only remote volume.
- `RTCMediaStreamTrack` exposes identity, state, and `isEnabled`.
- `RTCPeerConnectionFactory` has no audio-device injection initializer.
- `RTCAudioSession` documents that disabling its manual audio switch stops
  incoming and outgoing audio together.

The binary therefore cannot provide the required evidence hooks without a
different build or private/native API adaptation.

### Modern upstream comparator

Modern upstream exports `RTCAudioDevice`, but its contract makes the app
responsible for the full device implementation and `AVAudioSession`. Its
delegate supplies recorded-PCM delivery and playout-pull blocks only to that
app-supplied implementation. `RTCPeerConnectionFactory` constructs this custom
ADM only when an `RTCAudioDevice` is injected; otherwise it constructs the
stock iOS ADM.

The custom-device lifecycle does contain `startPlayout` and `stopPlayout`, but
those are methods the app must implement for the injected device. They are not
commands exposed by a stock remote audio track, and they provide no
provider-item render cursor.

The stock ADM does run a full-duplex VoiceProcessing I/O unit with AEC. Its
post-VoiceProcessingIO input callback and device playout callback are internal
to `AudioDeviceIOS`. The public Objective-C audio track/source headers do not
surface either callback. Modern aggregate audio-playout stats count frames at
the device callback, but they do not expose those rendered frames, associate
them with provider items, or synchronously flush at a cursor.

Two apparent alternatives were checked and rejected:

- AEC dump opens a caller-provided path with `fopen(..., "wb")` and asks the
  native factory to write a bounded diagnostic file. It is not a live PCM
  callback.
- The stock ADM increments one cumulative `total_playout_samples_count_` after
  its internal `FineAudioBuffer::GetPlayoutData` call. The public stat is an
  asynchronous aggregate, not an item-addressable render position.

Remote-track disable is also not a qualifying stop. The Objective-C setter
only forwards `set_enabled`. The native receiver then posts a task to its
worker thread and reconfigures the receive channel with output volume zero.
There is no synchronous completion, device stop, buffer flush, or returned
render boundary.

The upstream change that introduced `RTCAudioDevice` describes it as a
user-injectable implementation that delegates all system audio APIs to SDK-user
code. Implementing that path is exactly the custom audio-device work prohibited
for this Build Week gate.

### Public-surface and sample-path cross-check

The current framework build manifest exports `RTCAudioDevice.h`,
`RTCAudioSession.h`, `RTCAudioSource.h`, and `RTCAudioTrack.h`. A complete scan
of the peer-connection public headers found no other PCM, audio-buffer,
render-position, playout, flush, or audio-sink declaration. Private session
notifications report coarse start/stop and glitch state only.

Current AppRTCMobile constructs `RTCPeerConnectionFactory` with only video
encoder and decoder factories. That convenience initializer forwards
`audioDevice:nil`; factory source then creates the stock audio-device module.
The supported sample therefore does not expose or demonstrate the required
custom hooks.

## Frozen topology decision

At the end of the fixed audit window, Gate 0 freezes the preflighted direct
`gpt-realtime-2.1` WebSocket transport with one app-owned
`AVAudioEngine`/VoiceProcessingIO graph in `MAAudioProbe`:

- `AudioGraphController` is the sole audio-session, capture, and playout owner;
- the input-node tap is accepted only with voice processing asserted enabled,
  not bypassed, and not muted;
- tutor PCM is scheduled through one player/mixer path;
- the mixer/render timeline and player render time derive the local cursor;
- local stop snapshots that cursor before stopping the player, then sends one
  provider cancel and one render-derived truncate;
- no third-party WebRTC media dependency is added.

This decision proves only that the native-WebRTC candidate lacks the required
stock evidence surface. The selected WebSocket/VoiceProcessingIO graph still
must demonstrate both audio ends and local stop on the physical iPhone by the
unchanged hour-3 deadline, or Gate 0 becomes PARTIAL immediately.

## Primary sources

- WebRTC iOS build documentation:
  https://webrtc.googlesource.com/src/+/main/docs/native-code/ios/README.md
- Current `RTCAudioDevice` contract:
  https://webrtc.googlesource.com/src/+/main/sdk/objc/components/audio/RTCAudioDevice.h
- Current Objective-C ADM bridge:
  https://webrtc.googlesource.com/src/+/main/sdk/objc/native/api/objc_audio_device_module.mm
- Current stock iOS audio device:
  https://webrtc.googlesource.com/src/+/main/sdk/objc/native/src/audio/audio_device_ios.mm
- Current remote-audio receiver disable path:
  https://webrtc.googlesource.com/src/+/main/pc/audio_rtp_receiver.cc
- Current stats object declarations:
  https://webrtc.googlesource.com/src/+/main/api/stats/rtcstats_objects.h
- Current AppRTCMobile factory construction:
  https://webrtc.googlesource.com/src/+/main/examples/objc/AppRTCMobile/ARDAppClient.m
- Current Objective-C framework build manifest:
  https://webrtc.googlesource.com/src/+/main/sdk/BUILD.gn
- Current `RTCAudioSession` contract:
  https://webrtc.googlesource.com/src/+/main/sdk/objc/components/audio/RTCAudioSession.h
- GoogleWebRTC package record:
  https://cocoapods.org/pods/GoogleWebRTC
