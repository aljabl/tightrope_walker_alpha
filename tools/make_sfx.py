#!/usr/bin/env python3
"""Generate the game's placeholder sound effects as 16-bit mono WAV files.

Standard library only (wave, math, random, struct), so the sounds are our own
work with no licence questions. Run from the repo root:

    python3 tools/make_sfx.py

Writes into assets/audio/. Every sound is short, quiet and normalised with
headroom so nothing clips when several play at once.
"""

import math
import os
import random
import struct
import wave

RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")
PEAK = 0.7  # normalisation target, leaves headroom for mixing


def seconds(n):
    return int(RATE * n)


def envelope(i, total, attack, release):
    """Linear attack, flat hold, linear release. attack/release in samples."""
    if i < attack:
        return i / max(1, attack)
    if i > total - release:
        return max(0.0, (total - i) / max(1, release))
    return 1.0


def one_pole_lowpass(samples, cutoff_hz):
    out = []
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / RATE)
    y = 0.0
    for x in samples:
        y += alpha * (x - y)
        out.append(y)
    return out


def one_pole_highpass(samples, cutoff_hz):
    low = one_pole_lowpass(samples, cutoff_hz)
    return [x - l for x, l in zip(samples, low)]


def normalise(samples, peak=PEAK):
    top = max(1e-9, max(abs(s) for s in samples))
    scale = peak / top
    return [s * scale for s in samples]


def write(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        frames = bytearray()
        for s in samples:
            frames += struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767))
        handle.writeframes(bytes(frames))
    print("wrote", os.path.relpath(path))


def wind_loop(length=4.0):
    """Seamless filtered-noise loop with a slow swell that completes whole cycles."""
    rng = random.Random(7)
    total = seconds(length)
    noise = [rng.uniform(-1.0, 1.0) for _ in range(total)]
    body = one_pole_lowpass(noise, 420.0)
    body = one_pole_highpass(body, 80.0)
    out = []
    for i, x in enumerate(body):
        t = i / RATE
        swell = 0.7 + 0.3 * math.sin(2.0 * math.pi * t / length * 2.0)  # two full cycles
        out.append(x * swell)
    # Crossfade the tail into the head so the loop point is inaudible.
    fade = seconds(0.35)
    for i in range(fade):
        w = i / fade
        out[total - fade + i] = out[total - fade + i] * (1.0 - w) + out[i] * w
    return normalise(out, 0.5)


def footstep(seed, pitch):
    rng = random.Random(seed)
    total = seconds(0.14)
    out = []
    for i in range(total):
        t = i / RATE
        click = rng.uniform(-1.0, 1.0) * math.exp(-t * 90.0)
        thump = math.sin(2.0 * math.pi * pitch * t) * math.exp(-t * 28.0)
        out.append(0.5 * click + 0.9 * thump)
    out = one_pole_lowpass(out, 1800.0)
    return normalise(out, 0.45)


def fall():
    rng = random.Random(3)
    total = seconds(1.25)
    noise = [rng.uniform(-1.0, 1.0) for _ in range(total)]
    whoosh = one_pole_lowpass(noise, 900.0)
    whoosh = one_pole_highpass(whoosh, 150.0)
    out = []
    phase = 0.0
    for i in range(total):
        t = i / RATE
        rise = min(1.0, t / 0.35)
        fade = max(0.0, 1.0 - max(0.0, t - 0.6) / 0.45)
        freq = 420.0 * math.exp(-t * 1.6) + 70.0
        phase += 2.0 * math.pi * freq / RATE
        glide = 0.18 * math.sin(phase) * rise * fade
        thud = 0.0
        if t > 1.02:
            thud = math.sin(2.0 * math.pi * 58.0 * (t - 1.02)) * math.exp(-(t - 1.02) * 16.0) * 0.9
        out.append(whoosh[i] * rise * fade * 0.8 + glide + thud)
    return normalise(out, 0.6)


def gust_cue():
    total = seconds(0.28)
    out = []
    phase = 0.0
    for i in range(total):
        t = i / RATE
        freq = 440.0 + (880.0 - 440.0) * (t / 0.28)
        phase += 2.0 * math.pi * freq / RATE
        out.append(math.sin(phase) * envelope(i, total, seconds(0.02), seconds(0.08)))
    return normalise(out, 0.4)


def bird_flap():
    rng = random.Random(11)
    total = seconds(0.42)
    out = [0.0] * total
    for flap in range(3):
        start = seconds(0.02 + flap * 0.13)
        length = seconds(0.07)
        burst = [rng.uniform(-1.0, 1.0) for _ in range(length)]
        burst = one_pole_lowpass(burst, 1400.0)
        burst = one_pole_highpass(burst, 300.0)
        for i, x in enumerate(burst):
            out[start + i] += x * math.sin(math.pi * i / length)
    return normalise(out, 0.4)


def tension_tick():
    total = seconds(0.05)
    out = []
    for i in range(total):
        t = i / RATE
        out.append(math.sin(2.0 * math.pi * 1250.0 * t) * math.exp(-t * 110.0))
    return normalise(out, 0.35)


def release():
    total = seconds(0.32)
    out = []
    phase = 0.0
    for i in range(total):
        t = i / RATE
        freq = 190.0 * math.exp(-t * 1.2)
        phase += 2.0 * math.pi * freq / RATE
        tone = math.sin(phase) + 0.45 * math.sin(2.0 * phase) + 0.2 * math.sin(3.0 * phase)
        out.append(tone * math.exp(-t * 9.0))
    return normalise(out, 0.45)


def chime(notes, lengths, peak=0.45):
    out = []
    for freq, length in zip(notes, lengths):
        total = seconds(length)
        for i in range(total):
            t = i / RATE
            tone = math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * freq * 2.0 * t)
            out.append(tone * envelope(i, total, seconds(0.01), seconds(0.08)) * math.exp(-t * 3.0))
    return normalise(out, peak)


def miss():
    total = seconds(0.32)
    out = []
    for i in range(total):
        t = i / RATE
        tone = 0.0
        for harmonic in (1, 3, 5):
            tone += math.sin(2.0 * math.pi * 110.0 * harmonic * t) / harmonic
        out.append(tone * math.exp(-t * 7.0))
    return normalise(out, 0.4)


def main():
    write("wind_loop.wav", wind_loop())
    write("step_a.wav", footstep(1, 92.0))
    write("step_b.wav", footstep(2, 84.0))
    write("fall.wav", fall())
    write("gust_cue.wav", gust_cue())
    write("bird_flap.wav", bird_flap())
    write("tension_tick.wav", tension_tick())
    write("release.wav", release())
    write("pass.wav", chime([660.0, 990.0], [0.12, 0.22]))
    write("miss.wav", miss())
    write("win.wav", chime([523.25, 659.25, 783.99, 1046.5], [0.14, 0.14, 0.14, 0.4], 0.5))


if __name__ == "__main__":
    main()
