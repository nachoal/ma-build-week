#!/usr/bin/env python3
"""Generate the frozen, balanced Gate 0 first-attempt trial schedule."""

from __future__ import annotations

import argparse
import csv
import random
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Trial:
    cue: str
    expected: str
    passage: str
    cue_position: str


POSITIONS = ("early", "middle", "late")
CONTROL_PASSAGES = (
    "echo_exact_hai",
    "echo_exact_sumimasen",
    "echo_close_pronunciation",
    "unrelated_japanese_speech",
    "moderate_room_noise",
)


def position_sequence(rng: random.Random) -> list[str]:
    positions = ["early"] * 7 + ["middle"] * 7 + ["late"] * 6
    rng.shuffle(positions)
    return positions


def session_trials(rng: random.Random) -> list[Trial]:
    hai_positions = position_sequence(rng)
    repair_positions = position_sequence(rng)
    controls = [CONTROL_PASSAGES[index % len(CONTROL_PASSAGES)] for index in range(20)]
    rng.shuffle(controls)

    trials = [
        Trial("はい", "backchannel", "measurement_or_waiter", position)
        for position in hai_positions
    ]
    trials += [
        Trial("すみません", "take_floor_repair", "measurement_or_waiter", position)
        for position in repair_positions
    ]
    trials += [
        Trial("control", "echo_or_noise", passage, "continuous")
        for passage in controls
    ]

    # Keep randomization useful without allowing long same-class runs that
    # unnecessarily fatigue the learner or weaken the acoustic controls.
    for _ in range(10_000):
        rng.shuffle(trials)
        if all(
            len({trial.expected for trial in trials[index : index + 4]}) > 1
            for index in range(len(trials) - 3)
        ):
            return trials
    raise RuntimeError("Unable to create a schedule without four-class streaks")


def balanced_hero_indices(rows: list[dict[str, object]], cue: str, rng: random.Random) -> set[int]:
    chosen: list[int] = []
    quotas = {"early": 4, "middle": 3, "late": 3}
    for position, count in quotas.items():
        candidates = [
            index
            for index, row in enumerate(rows)
            if row["cue"] == cue and row["cue_position"] == position
        ]
        chosen.extend(rng.sample(candidates, count))
    return set(chosen)


def build_rows(seed: int) -> list[dict[str, object]]:
    rng = random.Random(seed)
    rows: list[dict[str, object]] = []
    absolute_trial = 0
    for session in (1, 2):
        for sequence, trial in enumerate(session_trials(rng), start=1):
            absolute_trial += 1
            rows.append(
                {
                    "trial": absolute_trial,
                    "session": session,
                    "sequence_in_session": sequence,
                    "cue": trial.cue,
                    "expected": trial.expected,
                    "passage": trial.passage,
                    "cue_position": trial.cue_position,
                    "hero_subset": False,
                    "first_attempt": True,
                    "schedule_seed": seed,
                }
            )

    hero = balanced_hero_indices(rows, "はい", rng)
    hero |= balanced_hero_indices(rows, "すみません", rng)
    for index in hero:
        rows[index]["hero_subset"] = True
    return rows


def validate(rows: list[dict[str, object]]) -> None:
    counts = {cue: sum(row["cue"] == cue for row in rows) for cue in ("はい", "すみません", "control")}
    assert counts == {"はい": 40, "すみません": 40, "control": 40}, counts
    for session in (1, 2):
        session_rows = [row for row in rows if row["session"] == session]
        assert len(session_rows) == 60
        for cue in ("はい", "すみません", "control"):
            assert sum(row["cue"] == cue for row in session_rows) == 20
    for cue in ("はい", "すみません"):
        hero_rows = [row for row in rows if row["cue"] == cue and row["hero_subset"]]
        assert len(hero_rows) == 10
        assert {position: sum(row["cue_position"] == position for row in hero_rows) for position in POSITIONS} == {
            "early": 4,
            "middle": 3,
            "late": 3,
        }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", required=True, type=int)
    parser.add_argument("--output", required=True, type=Path)
    arguments = parser.parse_args()

    rows = build_rows(arguments.seed)
    validate(rows)
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    with arguments.output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    print(f"wrote {len(rows)} frozen first-attempt trials to {arguments.output}")


if __name__ == "__main__":
    main()
