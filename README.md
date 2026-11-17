# Tightrope Walker

A single-player balance game that trains attention, built in Godot 4.7 (GDScript). You are a stuntman crossing a tightrope between rooftop towers while short attention tasks interrupt the walk. Reach the last tower without falling.

The project was prototyped in Roblox Studio and ported to Godot so the team could use git, branches and pull requests. The balance and stage rules live in one pure-logic script (`scripts/tightrope_rules.gd`) with headless tests; `scripts/game.gd` builds the world, camera and input at runtime, and `scripts/game_hud.gd` draws the HUD. The walker is Grab3D's stylized elderly man; rooftop props are from the Kenney Holiday Kit. The original Roblox world export (OBJ and PNG) is kept in `assets/world` as source material and is not loaded by the game.

## Play

Open `project.godot` in Godot 4.7 and run the project (Play button, F5 on Windows/Linux, Cmd+B on macOS).

The game opens with a camera pan over the city. Press **Space** to skip it, or any step key after two seconds.

### Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Step with the left / right foot | **W** / **O** | **A** (alternates feet automatically) |
| Lean left / right | **Q** / **P** | Left stick |
| Release wire tension | **Space** or **E** | **X** |
| Respawn immediately during a fall | **Space** | |
| Pause / resume | **Esc** | **Start** |
| Restart the whole run | **R** | |

Feet do not have to alternate on the keyboard. Balance and interruptions only begin once you take your first step onto the rope, so you are safe while standing on a roof.

### The course

Four towers, three crossings of thirteen steps each. Reaching a tower sets a checkpoint and shows a `TOWER <n>: <STAGE>` title. The top banner shows the tower, step count, stage name, run timer and a cue line that tells you what to watch for. A Space prompt appears only when Space does something (release tension, or respawn after a fall). Each interruption ends with a `PASS` or `MISS` toast (`FAIL` when the wire snaps).

Balance is an inverted pendulum: the further you tilt, the faster you tip. Small, early corrections with **Q/P** keep the pole level. If the tilt reaches the limit you fall to the street; press **Space** (or wait) to respawn at the last tower you reached. Falls are counted.

Each crossing adds an interruption and keeps the earlier ones:

1. **Gust Warning** (every crossing). A flag appears for a moment on the side the gust will come from, then a one-second response window opens. Your first lean decides: lean **away from the flag** to pass. Leaning toward it, or not leaning in time, triggers a strong gust that knocks you off. Gusts come every few seconds and take turns with the birds so cues never overlap.
2. **Flanker Birds** (crossings 2 and 3). Three birds fly in from one side. When they arrive you have one second to lean **the way the centre bird points**. The two outer birds sometimes point the other way; ignore them. Your first lean counts. A gust accompanies every bird pass; the correct lean rides it out, a wrong or missing lean drops you.
3. **Wire Tension** (crossing 3). The corner gauge rises steadily and jumps with each step, and the wire jitters more as it climbs. Press **Space** to release the tension (half-second cooldown). When the needle reaches the red range at 80% a countdown bar appears under the gauge; if it runs out the wire snaps and you fall. On this crossing the gusts, the birds and the gauge all run together.

The sky runs from blue daylight through sunset to night across the three crossings: the sun sets during the second crossing and the moon rises during the third.

Stepping off the last rope opens the finish card with your time, falls and best time this session. **Play again** restarts; **Stargaze** plays the ending camera move.

## Tests

Run the import once on a fresh checkout, then run the tests (replace `godot` with the path to your Godot 4.7 binary, for example `/Applications/Godot.app/Contents/MacOS/Godot` on macOS):

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_rules.gd
godot --headless --path . --script res://tests/test_scene.gd
```

`test_rules.gd` covers path layout, cooldowns, tower transitions, checkpoints, gust warnings, birds, tension, the stacked final stage, deterministic seeds and two full successful runs. `test_scene.gd` checks skyscraper construction, the three sky stages and celestial motion, HUD creation, the title screen, gust flag placement and step wiring.

## Current limits

No audio yet, no difficulty settings, no title or tutorial screen, and the finish card does not yet break results down per interruption. Single player only.
