import math
import random
from collections import Counter


FIVE_SUBJECTS_MULTIPLIER = 0.22
FIVE_SUBJECTS_MIN = 10
FIVE_SUBJECTS_MAX = 28
COMBO_BONUS_PER_STACK = 8

SUBJECTS = {
    "sticky_note": "jp",
    "eraser": None,
    "ruler": "math",
    "word_book": "eng",
    "cheat_sheet": "soc",
    "compass": "math",
    "energy_drink": None,
    "red_sheet": "eng",
    "mechanical_pencil": "jp",
    "thick_book": "sci",
}

DEFAULT_LOADOUT = {
    1: "sticky_note",
    2: "eraser",
    3: "ruler",
    4: "word_book",
    5: "cheat_sheet",
    6: "compass",
    7: "energy_drink",
    8: "red_sheet",
    9: "mechanical_pencil",
    10: "thick_book",
}


def build_deck(loadout):
    deck = []
    for number, item in loadout.items():
        deck.extend([(item, number)] * number)
    random.shuffle(deck)
    return deck


def five_subject_bonus(subtotal):
    return max(FIVE_SUBJECTS_MIN, min(FIVE_SUBJECTS_MAX, round(subtotal * FIVE_SUBJECTS_MULTIPLIER)))


def score_run(threshold):
    deck = build_deck(DEFAULT_LOADOUT)
    active_numbers = set()
    drawn = []
    while deck:
        burst_prob = sum(1 for _, n in deck if n in active_numbers) / len(deck)
        if burst_prob > threshold:
            break
        item, number = deck.pop()
        if number in active_numbers:
            return 0, len(drawn) + 1, True
        drawn.append((item, number))
        active_numbers.add(number)

    total = 0
    last_subject = None
    combo = 0
    subjects = set()
    pending_multiplier = 1
    for item, number in drawn:
        subject = SUBJECTS[item]
        if subject:
            subjects.add(subject)
            combo = combo + 1 if subject == last_subject else 1
            last_subject = subject
        else:
            combo = 0
            last_subject = None
        combo_bonus = max(0, combo - 1) * COMBO_BONUS_PER_STACK
        gained = number + combo_bonus
        gained *= pending_multiplier
        pending_multiplier = 2 if item == "red_sheet" else 1
        total += gained

    if len(subjects) == 5:
        total += five_subject_bonus(total)
    return total, len(drawn), False


def simulate(threshold, trials=10000):
    scores = []
    bursts = 0
    draws = []
    for _ in range(trials):
        score, draw_count, burst = score_run(threshold)
        scores.append(score)
        draws.append(draw_count)
        bursts += int(burst)
    scores.sort()
    return {
        "threshold": threshold,
        "avg_score": round(sum(scores) / len(scores), 2),
        "median_score": scores[len(scores) // 2],
        "p90_score": scores[int(len(scores) * 0.9)],
        "burst_rate": round(bursts / trials, 4),
        "avg_draws": round(sum(draws) / len(draws), 2),
    }


def main():
    for threshold in [0.10, 0.14, 0.18, 0.22, 0.26]:
        print(simulate(threshold))


if __name__ == "__main__":
    random.seed(7)
    main()
