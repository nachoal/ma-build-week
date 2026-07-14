#!/usr/bin/env python3
"""Generate the deterministic acoustic sync marker used at take boundaries."""

from __future__ import annotations

import argparse
import math
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 48_000
AMPLITUDE = 0.8
TONE_SECONDS = 0.15
GAP_SECONDS = 0.1
FREQUENCIES = (880.0, 1_320.0, 1_760.0)


def append_tone(samples: list[int], frequency: float) -> None:
    count = round(TONE_SECONDS * SAMPLE_RATE)
    fade = max(1, round(0.01 * SAMPLE_RATE))
    for index in range(count):
        envelope = min(1.0, index / fade, (count - 1 - index) / fade)
        value = AMPLITUDE * envelope * math.sin(2 * math.pi * frequency * index / SAMPLE_RATE)
        samples.append(round(value * 32_767))
    samples.extend([0] * round(GAP_SECONDS * SAMPLE_RATE))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    arguments = parser.parse_args()

    samples: list[int] = [0] * round(0.1 * SAMPLE_RATE)
    for frequency in FREQUENCIES:
        append_tone(samples, frequency)
    samples.extend([0] * round(0.1 * SAMPLE_RATE))

    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(arguments.output), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(b"".join(struct.pack("<h", sample) for sample in samples))

    print(f"wrote {len(samples) / SAMPLE_RATE:.3f}s sync chirp to {arguments.output}")


if __name__ == "__main__":
    main()
