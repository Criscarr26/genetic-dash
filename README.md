# Genetic Dash

Juego de plataformas de ritmo estilo **Geometry Dash** hecho en **Godot 4**:
un botón, reflejos y memoria. Esquiva bloques, tómate los orbes, usa los
trampolines y cruza los portales — incluido el **portal de nave**, que cambia
la mecánica de salto por vuelo — hasta llegar a la meta de cada nivel.

![Estado](https://img.shields.io/badge/estado-jugable-brightgreen)
![Hecho con](https://img.shields.io/badge/Godot-4.7-478cbf)
![Licencia](https://img.shields.io/badge/licencia-MIT-blue)

## Cómo se juega

- **Saltar / volar:** clic izquierdo, `Espacio` o `↑`
- Un solo toque en el momento justo lo es todo: los obstáculos matan al
  primer contacto y el nivel reinicia.
- **3 niveles** con música propia, más pantalla de menú y de final.

## Correrlo

1. Instala [Godot 4.7+](https://godotengine.org/download).
2. Clona este repo y abre `project.godot` desde el editor de Godot
   (Import → seleccionar la carpeta).
3. Presiona `F5` (Run Project).

## Modo IA

Desde el menú, **Modo IA — Entrenar bots** abre la pantalla de configuración
del experimento. Ahí se lanza una población de bots que aprende a jugar el
nivel por **aprendizaje reforzado**: cada bot lleva una red neuronal propia y
los pesos se optimizan con **algoritmos genéticos**.

- **Fitness:** qué tan lejos llega el bot en el nivel.
- **Élite:** el mejor de cada generación pasa intacto y corre de blanco,
  dibujando sus rayos de detección.
- **Teclas:** `1`-`4` cambian la velocidad de simulación (x1 a x8), `Esc` sale.

> **Sobre la velocidad:** acelerar solo con `Engine.time_scale` **cambia la
> física** — el delta de cada paso se multiplica, así que a x8 el cubo avanza
> 56 px por paso en vez de 7 y atraviesa obstáculos que a x1 lo matarían. Un
> bot entrenado así no serviría en el juego real. Por eso la aceleración sube
> también `physics_ticks_per_second`, dejando el delta en 1/60: se dan más
> pasos por segundo real, cada uno idéntico al del juego normal. Verificado:
> a igual semilla, x1 y x8 producen CSVs bit a bit iguales.

### Sensores

Nueve entradas normalizadas a `[0,1]`, cada una activable por separado —
apagar las que el nivel no usa acelera bastante la convergencia:

| Sensor | Qué mide |
| --- | --- |
| `dist_pua` | distancia horizontal a la próxima púa |
| `dist_bloque` | distancia horizontal al próximo bloque |
| `dist_techo` | distancia al techo (clave en modo nave) |
| `dist_abismo` | distancia al borde del suelo |
| `dist_trampolin` | distancia horizontal al próximo trampolín |
| `en_suelo` | si está pisando el suelo |
| `orbe_disponible` | si tiene una orbe sin gastar al alcance |
| `modo_nave` | si va en nave o en cubo |
| `vel_vertical` | velocidad vertical actual |

### Operadores disponibles

- **Selección:** Top-K, Torneo, Ruleta, Rango
- **Cruce:** ninguno, un punto, uniforme, aritmético
- **Mutación:** uniforme, gaussiana, reemplazo
- **Thresholding:** fijo (`salida > umbral`) o estocástico

### Modo por lotes (para el benchmark)

El benchmark pide comparar muchas configuraciones, y hacerlo a mano por el
menú es inviable. `Entrenar.tscn` acepta parámetros por línea de comandos —
todo lo que va después de `--` se lee como pares `clave=valor`:

```bash
godot --headless --path . res://Escenas/Entrenar.tscn -- nivel=1 generaciones=80 velocidad=8 bots=20 mutacion=0.15 sensores=111111111 semilla=1 incremental=0 etiqueta=mi_run
```

Con `generaciones=N` el proceso se cierra solo al terminar, así que se pueden
encadenar corridas desde un script. Claves admitidas: `nivel`, `etiqueta`,
`generaciones`, `velocidad`, `bots`, `elitismo`, `capas`, `sensores`,
`mutacion`, `magnitud`, `limite`, `seleccion`, `cruce`, `tipo_mutacion`,
`presion`, `umbral`, `tipo_umbral`, `activacion`, `rango_h`, `rango_v`,
`semilla`, `incremental`, `segundos_max`, `semilla_gen`, `evaluar`.

`sensores` acepta las dos formas: `111111111` (una casilla por sensor, en el
orden de la tabla de arriba) o `0,1,3` (índices encendidos).

### Entrenamiento incremental y validación

`semilla_gen=<archivo>` arranca la población desde el campeón de otro nivel —
es la recomendación 1 del PDF, entrenar nivel a nivel encadenando:

```bash
godot --headless --path . res://Escenas/Entrenar.tscn -- nivel=2 generaciones=30 semilla_gen=mejor_nivel1.json etiqueta=n2_incremental
```

`evaluar=<archivo>` corre una población ya entrenada sobre un nivel **sin
entrenar nada**: una sola generación, y escribe `eval_<etiqueta>.csv` con
cuántos agentes completan el nivel. Es lo que produce el *porcentaje de
completitud* y la *tasa de éxito en validación* del benchmark:

```bash
godot --headless --path . res://Escenas/Entrenar.tscn -- nivel=3 evaluar=poblacion_n2_incremental.json etiqueta=val_n3
```

### Salidas del entrenamiento

Todo va a la carpeta de datos de usuario
(`%APPDATA%\Godot\app_userdata\Genetic Dash OG\ia\`):

- `<etiqueta>.csv` — una fila por generación con mejor/promedio/peor fitness,
  % de completitud, cuántos bots completaron, tiempos y variación de los pesos
  del élite. Es la materia prima del benchmark cuantitativo. `segundos_sim` es
  tiempo simulado (comparable entre corridas a distinta velocidad) y
  `segundos_reloj` es tiempo real.
- `poblacion_<etiqueta>.json` — todas las redes de la última generación. La
  validación las necesita completas, no solo al campeón: la tasa de éxito se
  mide como qué fracción de los agentes entrenados completa un nivel que no
  entrenaron.
- `eval_<etiqueta>.csv` — resultado de una validación: agentes, cuántos
  completaron, tasa de éxito y completitud media.
- `mejor_<nivel>.json` — la mejor red encontrada. Si se deja activa la opción
  de población inicial *"Mejor guardado de este nivel"*, el siguiente
  entrenamiento arranca de ahí en vez de arrancar de ruido, que es el
  **entrenamiento incremental** nivel a nivel.

## Capas de física

| Capa | Contenido |
| --- | --- |
| 1 | mundo sólido (suelo y bloques) |
| 2 | jugador y bots |
| 3 | púas |
| 4 | orbes |
| 5 | trampolines |
| 6 | portales |

Los bots viven en la capa 2 y solo colisionan contra la 1, por eso pueden
correr decenas a la vez sin chocar entre ellos.

## Estructura

```
Escenas/    Menu, MenuIA, Nivel1-3, Entrenar, Fin
Objetos/    jugador, bloques, orbes, meta, portales (normal y nave)
Scripts/    GDScript del jugador, niveles, menú y final
Scripts/IA/ red neuronal, algoritmo genético, sensores, entrenador y registro
Sprites/    arte del juego
Sonidos/    música y SFX (CC0 — ver Sonidos/CREDITS.txt)
```

## Créditos de audio

Toda la música y los efectos son de
[Juhani Junkala (SubspaceAudio)](https://opengameart.org/content/5-chiptunes-action),
publicados bajo **CC0 (dominio público)** en OpenGameArt.org. Detalle
completo en [Sonidos/CREDITS.txt](Sonidos/CREDITS.txt).

## Licencia

[MIT](LICENSE)
