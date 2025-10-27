#!/usr/bin/env python3
"""Utility script to (re)build the Water Color Sort Puzzle level set."""

from __future__ import annotations

import json
import math
import random
from dataclasses import dataclass
from pathlib import Path
from typing import List

COLOR_POOL = [
    "red",
    "blue",
    "green",
    "yellow",
    "orange",
    "purple",
    "teal",
    "pink",
    "brown",
    "cyan",
    "magenta",
    "lime",
    "indigo",
    "maroon",
    "navy",
    "peach",
    "mint",
    "lavender",
    "turquoise",
    "coral",
]


@dataclass
class StageConfig:
    start: int
    end: int
    title_tokens: List[str]
    shuffle_factor: int
    hints: int

    def tube_capacity(self, level: int) -> int:
        if level <= 50:
            return 4
        if level <= 90:
            return 4
        if level <= 150:
            return 5
        if level <= 180:
            return 5
        if level <= 220:
            return 6
        if level <= 260:
            return 6
        return 6

    def color_count(self, level: int) -> int:
        if level <= 50:
            return min(3 + (level - 1) // 10, 6)
        if level <= 120:
            return min(5 + (level - 51) // 8, 9)
        if level <= 200:
            return min(7 + (level - 121) // 7, 11)
        return min(9 + (level - 201) // 7, 13)

    def extra_empties(self, level: int) -> int:
        if level <= 50:
            return 2
        if level <= 90:
            return 2
        if level <= 160:
            return 3
        if level <= 220:
            return 3
        return 3

    def title_for(self, level: int) -> str:
        offset = level - self.start
        token = self.title_tokens[offset % len(self.title_tokens)]
        wave = offset // len(self.title_tokens) + 1
        return f"{token} {wave}"


STAGES = [
    StageConfig(
        start=1,
        end=50,
        title_tokens=[
            "Easy Flow",
            "Gentle Pour",
            "Calm Cascade",
            "Soft Splash",
            "Bright Breeze",
        ],
        shuffle_factor=6,
        hints=5,
    ),
    StageConfig(
        start=51,
        end=120,
        title_tokens=[
            "Vivid Stream",
            "Tricky Twist",
            "Color Sprint",
            "Neon Ripple",
            "Tempo Pour",
        ],
        shuffle_factor=8,
        hints=4,
    ),
    StageConfig(
        start=121,
        end=200,
        title_tokens=[
            "Brain Brew",
            "Puzzle Pulse",
            "Focus Flow",
            "Mind Mixer",
            "Prism Dash",
        ],
        shuffle_factor=10,
        hints=3,
    ),
    StageConfig(
        start=201,
        end=300,
        title_tokens=[
            "Legendary Pour",
            "Mythic Mix",
            "Grand Gradient",
            "Elite Elixir",
            "Master Cascade",
        ],
        shuffle_factor=12,
        hints=2,
    ),
]


def stage_for_level(level: int) -> StageConfig:
    for stage in STAGES:
        if stage.start <= level <= stage.end:
            return stage
    raise ValueError(f"No stage config for level {level}")


def can_pour(stacks: List[List[str]], source: int, dest: int, capacity: int) -> bool:
    if source == dest:
        return False
    src = stacks[source]
    dst = stacks[dest]
    if not src or len(dst) >= capacity:
        return False
    if not dst:
        return True
    return src[-1] == dst[-1]


def pour(stacks: List[List[str]], source: int, dest: int, capacity: int) -> bool:
    if not can_pour(stacks, source, dest, capacity):
        return False
    src = stacks[source]
    dst = stacks[dest]
    color = src[-1]
    movable = 0
    for value in reversed(src):
        if value == color:
            movable += 1
        else:
            break
    space = capacity - len(dst)
    move_count = min(movable, space)
    if move_count <= 0:
        return False
    for _ in range(move_count):
        dst.append(src.pop())
    return True


def is_solved(stacks: List[List[str]], capacity: int) -> bool:
    for tube in stacks:
        if not tube:
            continue
        if len(tube) != capacity:
            return False
        if any(color != tube[0] for color in tube):
            return False
    return True


def has_enough_mixed(stacks: List[List[str]]) -> bool:
    mixed = sum(1 for tube in stacks if len(tube) > 1 and len(set(tube)) > 1)
    filled = sum(1 for tube in stacks if tube)
    return mixed >= max(2, math.ceil(filled * 0.3))


def shuffle_puzzle(stacks: List[List[str]], capacity: int, moves: int, rng: random.Random) -> None:
    attempts = 0
    applied = 0
    limit = moves * 6
    while applied < moves and attempts < limit:
        attempts += 1
        src = rng.randrange(len(stacks))
        dst = rng.randrange(len(stacks))
        if pour(stacks, src, dst, capacity):
            applied += 1


def build_level(level: int) -> dict:
    stage = stage_for_level(level)
    capacity = stage.tube_capacity(level)
    color_count = min(stage.color_count(level), len(COLOR_POOL))
    extra_empty = stage.extra_empties(level)
    shuffle_moves = color_count * capacity * stage.shuffle_factor
    rng = random.Random(level * 7919)

    colors = rng.sample(COLOR_POOL, color_count)
    stacks = [list(color for _ in range(capacity)) for color in colors]
    stacks = [list(tube) for tube in stacks]
    for tube in stacks:
        rng.shuffle(tube)
    stacks.extend([[] for _ in range(extra_empty)])

    shuffle_puzzle(stacks, capacity, shuffle_moves, rng)
    attempts = 0
    while (is_solved(stacks, capacity) or not has_enough_mixed(stacks)) and attempts < 12:
        shuffle_puzzle(stacks, capacity, shuffle_moves // 2 + capacity, rng)
        attempts += 1

    if is_solved(stacks, capacity) or not has_enough_mixed(stacks):
        # Force a gentle mix by swapping top segments across two random tubes.
        filled_indices = [i for i, tube in enumerate(stacks) if len(tube) >= 2]
        empty_indices = [i for i, tube in enumerate(stacks) if len(tube) < capacity]
        if len(filled_indices) >= 2 and len(empty_indices) >= 2:
            a, b = rng.sample(filled_indices, 2)
            x, y = rng.sample(empty_indices, 2)
            stacks[x].append(stacks[a].pop())
            stacks[y].append(stacks[b].pop())

    rng.shuffle(stacks)

    title = stage.title_for(level)
    return {
        "id": str(level).zfill(3),
        "title": title,
        "tube_capacity": capacity,
        "tubes": stacks,
        "moves_limit": None,
        "hints": stage.hints,
    }


def write_levels(root: Path) -> None:
    levels_dir = root / "assets" / "levels"
    levels_dir.mkdir(parents=True, exist_ok=True)
    for level in range(1, 301):
        data = build_level(level)
        target = levels_dir / f"level_{data['id']}.json"
        with target.open("w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
            fh.write("\n")


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    write_levels(project_root)


if __name__ == "__main__":
    main()
