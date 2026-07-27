"""Genera los 7 niveles de validacion de Genetic Dash.

El proyecto pide validar al agente en niveles que no uso para entrenar, y que
compartan mecanicas y dificultad con los de entrenamiento uno a uno:

    2 faciles      <-> Nivel 1  (bloques + puas)
    2 medios       <-> Nivel 2  (bloques + puas + trampolines)
    2 medio-altos  <-> Nivel 3  (todo: + orbes + nave + pozos)
    1 avanzado                  (todo, en un trazado distinto y mas largo)

Los niveles se describen como datos y de ahi salen los .tscn, para que la
misma descripcion sirva si el juego cambia de motor. Antes de escribir nada
se verifica que cada nivel sea fisicamente completable (ver `verificar`).

Uso:
    python Herramientas/gen_niveles_validacion.py
"""
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
DESTINO = RAIZ / "Escenas"

# --- Fisica del juego (debe coincidir con Scripts/jugador.gd) ---------------
VELOCIDAD = 420.0      # px/s horizontal, constante
SALTO = 640.0          # impulso del salto normal
TRAMPOLIN = 1050.0     # impulso del trampolin
GRAVEDAD = 1500.0

TILE = 64
SUELO_Y = 600          # borde superior del suelo
JUGADOR_Y = 568        # centro del jugador apoyado en el suelo
PUA_Y = 554
PORTAL_Y = 320


def altura_salto(impulso):
    return impulso ** 2 / (2 * GRAVEDAD)


def alcance_salto(impulso):
    return 2.0 * impulso / GRAVEDAD * VELOCIDAD


ALTURA_SALTO = altura_salto(SALTO)          # ~136 px
ALCANCE_SALTO = alcance_salto(SALTO)        # ~358 px
ALCANCE_TRAMPOLIN = alcance_salto(TRAMPOLIN)  # ~588 px

# Margenes de seguridad: un nivel de validacion tiene que ser claramente
# completable, no apurado al pixel.
HUECO_MAX = 256                 # pozo cruzable de un salto normal
HUECO_MAX_TRAMPOLIN = 512       # pozo cruzable saliendo de un trampolin
MURO_MAX_TILES = 2              # altura de bloques superable saltando
SEPARACION_MIN = 384            # distancia minima entre grupos de obstaculos


# ---------------------------------------------------------------------------
# Descripcion de los niveles
# ---------------------------------------------------------------------------
# bloques   : (x, alto_en_tiles)
# puas      : (x, tiles_de_base) -- 0 = apoyada en el suelo
# techos    : (x_ini, x_fin, y)  -- fila de bloques, para los tramos de nave
# nave      : (x_portal_nave, x_portal_normal)
# orbes     : (x, y)
# suelo     : [(x_ini, x_fin), ...]  -- los saltos entre tramos son pozos

NIVELES = [
    {
        "archivo": "ValFacil1",
        "titulo": "Validacion Facil A",
        "musica": "musica_nivel1.ogg",
        "gradiente": ((0.06, 0.14, 0.30), (0.16, 0.32, 0.52)),
        "pareja": "Nivel 1",
        "suelo": [(-128, 5200)],
        "puas": [(760, 0), (1210, 0), (1274, 0), (2130, 0),
                 (3020, 0), (3084, 0), (3980, 0), (4044, 0), (4108, 0)],
        "bloques": [(1660, 1), (2560, 1), (3480, 1), (4520, 1)],
        "trampolines": [],
        "orbes": [],
        "techos": [],
        "nave": [],
        "meta": 4950,
        "textos": [(320, 400, "Validacion facil A - puas y bloques")],
    },
    {
        "archivo": "ValFacil2",
        "titulo": "Validacion Facil B",
        "musica": "musica_nivel1.ogg",
        "gradiente": ((0.08, 0.18, 0.26), (0.20, 0.38, 0.44)),
        "pareja": "Nivel 1",
        "suelo": [(-128, 5400)],
        "puas": [(1180, 0), (2140, 0), (2204, 0), (3200, 0),
                 (3700, 0), (3764, 0), (4750, 0)],
        "bloques": [(700, 1), (1660, 1), (2700, 2), (4250, 1)],
        "trampolines": [],
        "orbes": [],
        "techos": [],
        "nave": [],
        "meta": 5100,
        "textos": [(320, 400, "Validacion facil B - mas bloques")],
    },
    {
        "archivo": "ValMedio1",
        "titulo": "Validacion Media A",
        "musica": "musica_nivel2.ogg",
        "gradiente": ((0.10, 0.08, 0.32), (0.34, 0.18, 0.48)),
        "pareja": "Nivel 2",
        "suelo": [(-128, 3900), (4200, 6800)],
        "puas": [(820, 0), (1300, 0), (1364, 0), (3040, 0), (3104, 0),
                 (4700, 0), (5200, 0), (5264, 0)],
        "bloques": [(1850, 1), (2560, 3), (5850, 2)],
        "trampolines": [2300, 3700, 5600],
        "orbes": [],
        "techos": [],
        "nave": [],
        "meta": 6350,
        "textos": [(320, 400, "Validacion media A - trampolines"),
                   (3300, 380, "El trampolin cruza el pozo")],
    },
    {
        "archivo": "ValMedio2",
        "titulo": "Validacion Media B",
        "musica": "musica_nivel2.ogg",
        "gradiente": ((0.16, 0.10, 0.24), (0.42, 0.22, 0.34)),
        "pareja": "Nivel 2",
        "suelo": [(-128, 2900), (3250, 6900)],
        "puas": [(900, 0), (1900, 0), (1964, 0), (2450, 0),
                 (4500, 0), (4564, 0), (5550, 0)],
        "bloques": [(1400, 1), (4000, 3), (5050, 2), (6050, 1)],
        "trampolines": [2700, 3750],
        "orbes": [],
        "techos": [],
        "nave": [],
        "meta": 6500,
        "textos": [(320, 400, "Validacion media B - trampolines y muros")],
    },
    {
        "archivo": "ValMedioAlto1",
        "titulo": "Validacion Media-Alta A",
        "musica": "musica_nivel3.ogg",
        "gradiente": ((0.22, 0.06, 0.30), (0.50, 0.16, 0.28)),
        "pareja": "Nivel 3",
        "suelo": [(-128, 2600), (2900, 5200), (5600, 8400)],
        "puas": [(760, 0), (1240, 0), (1304, 0), (2300, 0),
                 (3400, 0), (4400, 0),
                 (6800, 0), (7300, 0), (7364, 0)],
        "bloques": [(1800, 1), (3900, 2), (5300, 1), (5800, 1), (7900, 2)],
        "trampolines": [2400, 4550],
        "orbes": [(2750, 470), (4700, 455), (7000, 460)],
        "techos": [(5000, 6200, 216)],
        "nave": [(4900, 6300)],
        "meta": 8300,
        "textos": [(320, 400, "Validacion media-alta A - todas las mecanicas"),
                   (4400, 380, "Portal de nave: manten presionado")],
    },
    {
        "archivo": "ValMedioAlto2",
        "titulo": "Validacion Media-Alta B",
        "musica": "musica_nivel3.ogg",
        "gradiente": ((0.05, 0.20, 0.28), (0.18, 0.44, 0.40)),
        "pareja": "Nivel 3",
        "suelo": [(-128, 2200), (2500, 4600), (5000, 8400)],
        "puas": [(880, 0), (1400, 0), (1464, 0),
                 (3000, 0), (3500, 0), (3564, 0),
                 (6700, 0), (7200, 0), (7264, 0)],
        "bloques": [(1900, 2), (4100, 1), (5400, 1), (5900, 1), (7800, 2)],
        "trampolines": [2100, 4400],
        "orbes": [(2350, 460), (4750, 450), (6900, 460)],
        "techos": [(5100, 6100, 216)],
        "nave": [(5000, 6200)],
        "meta": 8250,
        "textos": [(320, 400, "Validacion media-alta B - todas las mecanicas")],
    },
    {
        "archivo": "ValAvanzado",
        "titulo": "Validacion Avanzada",
        "musica": "musica_nivel3.ogg",
        "gradiente": ((0.28, 0.04, 0.20), (0.60, 0.20, 0.16)),
        "pareja": "Integra todo",
        "suelo": [(-128, 2400), (2700, 4600), (5000, 7000), (7350, 11000)],
        "puas": [(700, 0), (1180, 0), (1244, 0),
                 (3150, 0), (3650, 0), (3714, 0),
                 (5500, 0), (5980, 0), (6044, 0),
                 (8800, 0), (9300, 0), (9364, 0), (10400, 0)],
        "bloques": [(1750, 1), (4250, 2), (6550, 1),
                    (7700, 1), (8100, 1), (9900, 2)],
        "trampolines": [2200, 4400, 6800],
        "orbes": [(2550, 470), (4800, 455), (7170, 460)],
        "techos": [(7500, 8300, 216)],
        "nave": [(7400, 8400)],
        "meta": 10800,
        "textos": [(320, 400, "Validacion avanzada - todo combinado"),
                   (7000, 380, "Tramo de nave")],
    },
]


# ---------------------------------------------------------------------------
# Verificacion de que el nivel se puede completar
# ---------------------------------------------------------------------------
def _tramos_nave(nivel):
    return nivel["nave"]


def _en_nave(nivel, x):
    return any(ini <= x <= fin for ini, fin in _tramos_nave(nivel))


def verificar(nivel):
    """Devuelve la lista de problemas fisicos del nivel. Vacia = jugable."""
    problemas = []
    nombre = nivel["archivo"]

    # 1. Pozos entre tramos de suelo
    suelo = sorted(nivel["suelo"])
    for (_, fin), (ini, _) in zip(suelo, suelo[1:]):
        ancho = ini - fin
        if _en_nave(nivel, fin) and _en_nave(nivel, ini):
            continue
        tramp_cerca = any(0 < fin - t < 260 for t in nivel["trampolines"])
        limite = HUECO_MAX_TRAMPOLIN if tramp_cerca else HUECO_MAX
        if ancho > limite:
            problemas.append(
                f"{nombre}: pozo de {ancho} px en x={fin} supera el maximo "
                f"de {limite} px ({'con' if tramp_cerca else 'sin'} trampolin)")

    # 2. Muros demasiado altos para el salto
    for x, alto in nivel["bloques"]:
        if _en_nave(nivel, x):
            continue
        tramp_cerca = any(0 < x - t < 300 for t in nivel["trampolines"])
        limite = 4 if tramp_cerca else MURO_MAX_TILES
        if alto > limite:
            problemas.append(
                f"{nombre}: muro de {alto} tiles en x={x} supera el maximo "
                f"de {limite} ({'con' if tramp_cerca else 'sin'} trampolin)")

    # 3. Separacion entre grupos de obstaculos
    obstaculos = sorted([x for x, _ in nivel["puas"]] + [x for x, _ in nivel["bloques"]])
    grupos = []
    for x in obstaculos:
        if grupos and x - grupos[-1][-1] <= TILE + 8:
            grupos[-1].append(x)
        else:
            grupos.append([x])
    for a, b in zip(grupos, grupos[1:]):
        hueco = b[0] - a[-1]
        if _en_nave(nivel, a[-1]):
            continue
        if hueco < SEPARACION_MIN:
            problemas.append(
                f"{nombre}: solo {hueco} px entre los obstaculos de x={a[-1]} "
                f"y x={b[0]} (minimo {SEPARACION_MIN})")

    # 4. Los trampolines no pueden solaparse con bloques ni puas: el trampolin
    #    mide 116 px de ancho y el bloque 64, asi que a menos de 96 px del
    #    centro se pisan y el rebote se dispara dentro del obstaculo.
    for t in nivel["trampolines"]:
        for x, _ in nivel["bloques"]:
            if abs(t - x) < 96:
                problemas.append(
                    f"{nombre}: el trampolin de x={t} se solapa con el bloque de x={x}")
        for x, base in nivel["puas"]:
            if base == 0 and abs(t - x) < 96:
                problemas.append(
                    f"{nombre}: el trampolin de x={t} se solapa con la pua de x={x}")

    # 5. La meta tiene que quedar sobre suelo y despues de todo
    fin_suelo = max(f for _, f in nivel["suelo"])
    if nivel["meta"] > fin_suelo:
        problemas.append(f"{nombre}: la meta en x={nivel['meta']} cae fuera del suelo")
    ultimo = max(obstaculos) if obstaculos else 0
    if nivel["meta"] < ultimo + 200:
        problemas.append(f"{nombre}: la meta esta demasiado pegada al ultimo obstaculo")

    # 5. Los tramos de nave necesitan techo y altura de vuelo
    for ini, fin in _tramos_nave(nivel):
        techo = [t for t in nivel["techos"] if t[0] < fin and t[1] > ini]
        if not techo:
            problemas.append(f"{nombre}: el tramo de nave {ini}-{fin} no tiene techo")
            continue
        for _, _, y in techo:
            if SUELO_Y - y < 192:
                problemas.append(
                    f"{nombre}: el techo del tramo de nave deja solo "
                    f"{SUELO_Y - y} px de vuelo (minimo 192)")
    return problemas


# ---------------------------------------------------------------------------
# Emision del .tscn
# ---------------------------------------------------------------------------
CABECERA = '''[gd_scene format=3]

[ext_resource type="Script" path="res://Scripts/nivel.gd" id="1_niv"]
[ext_resource type="PackedScene" uid="uid://sc2vxim42f80" path="res://Objetos/jugador.tscn" id="2_jug"]
[ext_resource type="PackedScene" uid="uid://d01in7s6uxak6" path="res://Objetos/Obj_bloque.tscn" id="3_blo"]
[ext_resource type="PackedScene" uid="uid://cjfgqsgauh4qo" path="res://Objetos/Obj_pua.tscn" id="4_pua"]
[ext_resource type="PackedScene" uid="uid://diu3c3c7y64wd" path="res://Objetos/Obj_trampolin.tscn" id="5_tra"]
[ext_resource type="PackedScene" path="res://Objetos/Obj_orbe.tscn" id="6_orb"]
[ext_resource type="PackedScene" path="res://Objetos/Obj_portal_nave.tscn" id="7_pna"]
[ext_resource type="PackedScene" path="res://Objetos/Obj_portal_normal.tscn" id="8_pno"]
[ext_resource type="PackedScene" path="res://Objetos/Obj_meta.tscn" id="9_met"]
[ext_resource type="Texture2D" path="res://Sprites/suelo.svg" id="10_sue"]
[ext_resource type="AudioStream" path="res://Sonidos/{musica}" id="11_mus"]

[sub_resource type="Gradient" id="Gradient_fondo"]
colors = PackedColorArray({c0}, 1, {c1}, 1)

[sub_resource type="GradientTexture2D" id="GradTex_fondo"]
gradient = SubResource("Gradient_fondo")
fill_from = Vector2(0, 0)
fill_to = Vector2(0, 1)
width = 1280
height = 780
'''

ENCABEZADO_NODOS = '''
[node name="{nombre}" type="Node2D"]
script = ExtResource("1_niv")

[node name="Fondo" type="CanvasLayer" parent="."]
layer = -10

[node name="FondoTex" type="TextureRect" parent="Fondo"]
offset_left = -20.0
offset_top = -20.0
offset_right = 1260.0
offset_bottom = 760.0
texture = SubResource("GradTex_fondo")

[node name="Musica" type="AudioStreamPlayer" parent="."]
stream = ExtResource("11_mus")
volume_db = -10.0

[node name="HUD" type="CanvasLayer" parent="."]

[node name="Titulo" type="Label" parent="HUD"]
offset_left = 16.0
offset_top = 10.0
offset_right = 560.0
offset_bottom = 40.0
theme_override_font_sizes/font_size = 22
text = "{titulo}"

[node name="Ayuda" type="Label" parent="HUD"]
offset_left = 16.0
offset_top = 40.0
offset_right = 700.0
offset_bottom = 64.0
theme_override_font_sizes/font_size = 14
modulate = Color(1, 1, 1, 0.7)
text = "Nivel de validacion (pareja de {pareja})   |   R: reiniciar   |   Esc: menu"

[node name="Jugador" parent="." instance=ExtResource("2_jug")]
position = Vector2(224, 568)

[node name="Camera2D" type="Camera2D" parent="Jugador"]
offset = Vector2(320, -40)
limit_left = 0
limit_top = -500
limit_right = {limite_derecho}
limit_bottom = 760
position_smoothing_enabled = true
position_smoothing_speed = 6.0
drag_vertical_enabled = true
drag_top_margin = 0.35
drag_bottom_margin = 0.35
'''


def color(c):
    return ", ".join(f"{v:g}" for v in c)


def generar(nivel):
    m = nivel["musica"]
    partes = [CABECERA.format(musica=m,
                              c0=color(nivel["gradiente"][0]),
                              c1=color(nivel["gradiente"][1]))]

    # Formas del suelo, una por tramo
    for i, (ini, fin) in enumerate(nivel["suelo"]):
        partes.append(f'\n[sub_resource type="RectangleShape2D" id="Shape_suelo_{i}"]\n'
                      f'size = Vector2({fin - ini}, 256)\n')

    partes.append(ENCABEZADO_NODOS.format(
        nombre=nivel["archivo"], titulo=nivel["titulo"], pareja=nivel["pareja"],
        limite_derecho=int(nivel["meta"] + 900)))

    partes.append('\n[node name="Suelo" type="StaticBody2D" parent="."]\n')
    for i, (ini, fin) in enumerate(nivel["suelo"]):
        centro = (ini + fin) // 2
        ancho = fin - ini
        partes.append(
            f'\n[node name="SueloCol{i}" type="CollisionShape2D" parent="Suelo"]\n'
            f'position = Vector2({centro}, 728)\n'
            f'shape = SubResource("Shape_suelo_{i}")\n'
            f'\n[node name="SueloVis{i}" type="Sprite2D" parent="Suelo"]\n'
            f'position = Vector2({centro}, 728)\n'
            f'texture = ExtResource("10_sue")\n'
            f'texture_repeat = 2\n'
            f'region_enabled = true\n'
            f'region_rect = Rect2(0, 0, {ancho}, 256)\n')

    n = 0
    for x, alto in nivel["bloques"]:
        for k in range(alto):
            partes.append(f'\n[node name="Bloque{n}" parent="." instance=ExtResource("3_blo")]\n'
                          f'position = Vector2({x}, {JUGADOR_Y - k * TILE})\n')
            n += 1
    for ini, fin, y in nivel["techos"]:
        for x in range(ini, fin + 1, TILE):
            partes.append(f'\n[node name="Bloque{n}" parent="." instance=ExtResource("3_blo")]\n'
                          f'position = Vector2({x}, {y})\n')
            n += 1

    for i, (x, base) in enumerate(nivel["puas"]):
        partes.append(f'\n[node name="Pua{i}" parent="." instance=ExtResource("4_pua")]\n'
                      f'position = Vector2({x}, {PUA_Y - base * TILE})\n')

    for i, x in enumerate(nivel["trampolines"]):
        partes.append(f'\n[node name="Trampolin{i}" parent="." instance=ExtResource("5_tra")]\n'
                      f'position = Vector2({x}, {JUGADOR_Y})\n')

    for i, (x, y) in enumerate(nivel["orbes"]):
        partes.append(f'\n[node name="Orbe{i}" parent="." instance=ExtResource("6_orb")]\n'
                      f'position = Vector2({x}, {y})\n')

    for i, (x_nave, x_normal) in enumerate(nivel["nave"]):
        partes.append(f'\n[node name="PortalNave{i}" parent="." instance=ExtResource("7_pna")]\n'
                      f'position = Vector2({x_nave}, {PORTAL_Y})\n')
        partes.append(f'\n[node name="PortalNormal{i}" parent="." instance=ExtResource("8_pno")]\n'
                      f'position = Vector2({x_normal}, {PORTAL_Y})\n')

    partes.append(f'\n[node name="PortalMeta" parent="." instance=ExtResource("9_met")]\n'
                  f'position = Vector2({nivel["meta"]}, {PORTAL_Y})\n'
                  f'siguiente_escena = "res://Escenas/Menu.tscn"\n')

    for i, (x, y, texto) in enumerate(nivel["textos"]):
        partes.append(f'\n[node name="Texto{i}" type="Label" parent="."]\n'
                      f'offset_left = {x}.0\n'
                      f'offset_top = {y}.0\n'
                      f'offset_right = {x + 520}.0\n'
                      f'offset_bottom = {y + 28}.0\n'
                      f'theme_override_font_sizes/font_size = 18\n'
                      f'modulate = Color(1, 1, 1, 0.85)\n'
                      f'text = "{texto}"\n')

    return "".join(partes)


def main():
    problemas = []
    for nivel in NIVELES:
        problemas += verificar(nivel)

    if problemas:
        print("NIVELES NO JUGABLES, no se escribio nada:")
        for p in problemas:
            print("  - " + p)
        raise SystemExit(1)

    for nivel in NIVELES:
        destino = DESTINO / f"{nivel['archivo']}.tscn"
        destino.write_text(generar(nivel), encoding="utf-8")
        largo = nivel["meta"]
        print(f"  {nivel['archivo']:<16} largo {largo:>6} px   "
              f"puas {len(nivel['puas']):>2}   bloques {len(nivel['bloques']):>2}   "
              f"tramp {len(nivel['trampolines'])}   orbes {len(nivel['orbes'])}   "
              f"nave {len(nivel['nave'])}")
    print(f"\n{len(NIVELES)} niveles de validacion escritos en {DESTINO}")
    print(f"Salto: alcance {ALCANCE_SALTO:.0f} px, altura {ALTURA_SALTO:.0f} px | "
          f"Trampolin: alcance {ALCANCE_TRAMPOLIN:.0f} px")


if __name__ == "__main__":
    main()
