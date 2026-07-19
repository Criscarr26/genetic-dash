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

## Estructura

```
Escenas/    Menu, Nivel1-3, Fin
Objetos/    jugador, bloques, orbes, meta, portales (normal y nave)
Scripts/    GDScript del jugador, niveles, menú y final
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
