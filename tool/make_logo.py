"""Logo de to Do: ladrillos en forma de check, pixel art 16 × 16 (variante B).

Genera en assets/logo/:
  icon_full.png        1024 × 1024, fondo azul a sangre (iOS y Android antiguo)
  icon_foreground.png  1024 × 1024, solo ladrillos sobre transparente (Android adaptativo)
  icon_round.png       512 × 512 con esquinas redondeadas pixeladas (README)

Uso: python tool/make_logo.py
La misma cuadrícula está en lib/presentation/common/pixel_logo.dart.
"""
from pathlib import Path

from PIL import Image

BG = (0x5B, 0x7C, 0xFA, 255)
EDGE = (0x3E, 0x5B, 0xD9, 255)
BRICK = (0xFF, 0xFF, 0xFF, 255)
BRICK_SHADOW = (0xC9, 0xD3, 0xFF, 255)
LAST = (0xFF, 0xC8, 0x3D, 255)
LAST_HI = (0xFF, 0xE0, 0x8A, 255)
LAST_SHADOW = (0xE0, 0xA9, 0x1E, 255)

BRICKS = [(2, 8), (4, 10), (6, 12), (8, 10), (10, 8), (12, 6)]
LAST_BRICK = (12, 2)


def bricks():
    """{(x, y): color} de los ladrillos en la cuadrícula 16 × 16."""
    px = {}
    for bx, by in BRICKS:
        for i in range(3):
            px[(bx + i, by)] = BRICK
            px[(bx + i, by + 1)] = BRICK_SHADOW
    bx, by = LAST_BRICK
    for i in range(3):
        px[(bx + i, by)] = LAST_HI if i == 0 else LAST
        px[(bx + i, by + 1)] = LAST_SHADOW
    return px


def cut(x, y):
    """Esquinas recortadas del cuadrado redondeado."""
    def c(a, b):
        return a + b < 2
    return (c(x, y) or c(15 - x, y) or c(x, 15 - y) or c(15 - x, 15 - y))


def border(x, y):
    return x in (0, 15) or y in (0, 15) or (x in (1, 14) and y in (1, 14))


def rounded():
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    for y in range(16):
        for x in range(16):
            if not cut(x, y):
                img.putpixel((x, y), EDGE if border(x, y) else BG)
    for (x, y), c in bricks().items():
        img.putpixel((x, y), c)
    return img


def full():
    img = Image.new('RGBA', (16, 16), BG)
    for (x, y), c in bricks().items():
        img.putpixel((x, y), c)
    return img


def foreground(size=1024):
    """Ladrillos centrados, ~58 % del lienzo (zona segura del icono adaptativo)."""
    px = bricks()
    xs = [x for x, _ in px]
    ys = [y for _, y in px]
    w, h = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
    cell = int(size * 0.58 / max(w, h))
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ox = (size - w * cell) // 2 - min(xs) * cell
    oy = (size - h * cell) // 2 - min(ys) * cell
    for (x, y), c in px.items():
        img.paste(c, (ox + x * cell, oy + y * cell, ox + (x + 1) * cell, oy + (y + 1) * cell))
    return img


def main():
    out = Path(__file__).resolve().parent.parent / 'assets' / 'logo'
    out.mkdir(parents=True, exist_ok=True)
    full().resize((1024, 1024), Image.NEAREST).convert('RGB').save(out / 'icon_full.png')
    foreground().save(out / 'icon_foreground.png')
    rounded().resize((512, 512), Image.NEAREST).save(out / 'icon_round.png')
    print('ok', out)


if __name__ == '__main__':
    main()
