# Genetic Dash

Geometry Dash-style rhythm platformer built in **Godot 4**:
one button, reflexes and memory. Dodge blocks, grab the orbs, use the jump pads
and cross the portals — including the **ship portal**, which swaps the jump
mechanic for flight — until you reach each level's goal.

![Status](https://img.shields.io/badge/status-playable-brightgreen)
![Made with](https://img.shields.io/badge/Godot-4.7-478cbf)
![License](https://img.shields.io/badge/license-MIT-blue)

## How to play

- **Jump / fly:** left click, `Space` or `↑`
- A single well-timed tap is everything: obstacles kill on first contact and the
  level restarts.
- **3 levels** each with its own music, plus menu and end screens.

## Run it

1. Install [Godot 4.7+](https://godotengine.org/download).
2. Clone this repo and open `project.godot` from the Godot editor
   (Import → select the folder).
3. Press `F5` (Run Project).

## AI mode

From the menu, **Modo IA — Entrenar bots** opens the experiment configuration
screen. There it launches a population of bots that learns to play the level by
**reinforcement learning**: each bot carries its own neural network and the
weights are optimized with **genetic algorithms**.

- **Fitness:** how far the bot gets in the level.
- **Elite:** the best of each generation passes through untouched and runs in
  white, drawing its detection rays.
- **Keys:** `1`-`4` change the simulation speed (x1 to x8), `Esc` exits.

> **About speed:** accelerating only with `Engine.time_scale` **changes the
> physics** — each step's delta is multiplied, so at x8 the cube advances
> 56 px per step instead of 7 and passes through obstacles that would kill it at
> x1. A bot trained that way would be useless in the real game. That's why the
> acceleration also raises `physics_ticks_per_second`, keeping the delta at 1/60:
> more steps are taken per real second, each identical to the normal game's. Verified:
> at the same seed, x1 and x8 produce bit-for-bit identical CSVs.

### Sensors

Nine inputs normalized to `[0,1]`, each toggleable independently — turning off
the ones a level doesn't use speeds up convergence considerably:

| Sensor | What it measures |
| --- | --- |
| `dist_pua` | horizontal distance to the next spike |
| `dist_bloque` | horizontal distance to the next block |
| `dist_techo` | distance to the ceiling (key in ship mode) |
| `dist_abismo` | distance to the edge of the floor |
| `dist_trampolin` | horizontal distance to the next jump pad |
| `en_suelo` | whether it's standing on the ground |
| `orbe_disponible` | whether it has an unused orb within reach |
| `modo_nave` | whether it's in ship or cube mode |
| `vel_vertical` | current vertical velocity |

### Available operators

- **Selection:** Top-K, Tournament, Roulette, Rank
- **Crossover:** none, single-point, uniform, arithmetic
- **Mutation:** uniform, Gaussian, replacement
- **Thresholding:** fixed (`output > threshold`) or stochastic

### Batch mode (for the benchmark)

The benchmark requires comparing many configurations, and doing so by hand
through the menu is unfeasible. `Entrenar.tscn` accepts command-line parameters —
everything after `--` is read as `key=value` pairs:

```bash
godot --headless --path . res://Escenas/Entrenar.tscn -- nivel=1 generaciones=80 velocidad=8 bots=20 mutacion=0.15 sensores=111111111 semilla=1 incremental=0 etiqueta=mi_run
```

With `generaciones=N` the process closes itself when done, so runs can be chained
from a script. Accepted keys: `nivel`, `etiqueta`, `generaciones`, `velocidad`,
`bots`, `elitismo`, `capas`, `sensores`, `mutacion`, `magnitud`, `limite`,
`seleccion`, `cruce`, `tipo_mutacion`, `presion`, `umbral`, `tipo_umbral`,
`activacion`, `rango_h`, `rango_v`, `semilla`, `incremental`, `segundos_max`,
`semilla_gen`, `evaluar`.

`sensores` accepts both forms: `111111111` (one slot per sensor, in the order of
the table above) or `0,1,3` (enabled indices).

### Incremental training and validation

`semilla_gen=<file>` starts the population from another level's champion — it's
recommendation 1 of the PDF, training level by level in a chain:

```bash
godot --headless --path . res://Escenas/Entrenar.tscn -- nivel=2 generaciones=30 semilla_gen=mejor_nivel1.json etiqueta=n2_incremental
```

`evaluar=<file>` runs an already-trained population on a level **without training
anything**: a single generation, and it writes `eval_<etiqueta>.csv` with how many
agents complete the level. This is what produces the benchmark's *completion
percentage* and *validation success rate*:

```bash
godot --headless --path . res://Escenas/Entrenar.tscn -- nivel=3 evaluar=poblacion_n2_incremental.json etiqueta=val_n3
```

### Training outputs

Everything goes to the user data folder
(`%APPDATA%\Godot\app_userdata\Genetic Dash OG\ia\`):

- `<etiqueta>.csv` — one row per generation with best/average/worst fitness,
  completion %, how many bots completed, times and the variation of the elite's
  weights. It's the raw material of the quantitative benchmark. `segundos_sim` is
  simulated time (comparable across runs at different speeds) and `segundos_reloj`
  is real time.
- `poblacion_<etiqueta>.json` — all the networks of the last generation. Validation
  needs them all, not just the champion: the success rate is measured as what
  fraction of the trained agents completes a level they didn't train on.
- `eval_<etiqueta>.csv` — result of a validation: agents, how many completed,
  success rate and mean completion.
- `mejor_<nivel>.json` — the best network found. If the initial-population option
  *"Mejor guardado de este nivel"* is left enabled, the next training starts from
  there instead of from noise, which is the **incremental training** level by level.

## Physics layers

| Layer | Contents |
| --- | --- |
| 1 | solid world (ground and blocks) |
| 2 | player and bots |
| 3 | spikes |
| 4 | orbs |
| 5 | jump pads |
| 6 | portals |

The bots live on layer 2 and only collide with layer 1, which is why dozens can
run at once without bumping into each other.

## Structure

```
Escenas/    Menu, MenuIA, Nivel1-3, Entrenar, Fin
Objetos/    player, blocks, orbs, goal, portals (normal and ship)
Scripts/    GDScript for the player, levels, menu and end
Scripts/IA/ neural network, genetic algorithm, sensors, trainer and logging
Sprites/    game art
Sonidos/    music and SFX (CC0 — see Sonidos/CREDITS.txt)
```

## Audio credits

All music and effects are by
[Juhani Junkala (SubspaceAudio)](https://opengameart.org/content/5-chiptunes-action),
released under **CC0 (public domain)** on OpenGameArt.org. Full detail in
[Sonidos/CREDITS.txt](Sonidos/CREDITS.txt).

## License

[MIT](LICENSE)
