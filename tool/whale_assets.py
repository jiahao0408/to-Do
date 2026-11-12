"""Procesa los assets del pez (鲸鱼娘 DeepSeek) para la app.

Uso:
    python tool/whale_assets.py tool/whale_originals assets/whale

- Lista de archivos y grupos: tool/whale_files.txt («grupo archivo» por línea).
- Imágenes fijas: recorte cuadrado centrado, como máximo 512 px, WebP calidad 82.
- GIF: cada fotograma a 256 px, conservando duraciones y bucle, WebP animado.
- Escribe assets/whale/manifest.json y muestra el tamaño de cada archivo.

Origen: https://github.com/EDMOK/blue-fish-archive (CC BY-NC-SA 4.0).
Original 上善无形 · segundo diseño ZipZipPipe.
"""

import json
import os
import sys

from PIL import Image, ImageSequence

FOLDER = {  # grupo → subcarpeta
    "normal": "normal",
    "celebrate": "celebrate",
    "worried": "worried",
    "sleep": "sleep",
    "pet": "reactions",
    "poked": "reactions",
    "eat": "reactions",
    "easter": "reactions",
}
ORDER = ["normal", "celebrate", "worried", "sleep", "pet", "poked", "eat", "easter"]


def square(img, size):
    w, h = img.size
    side = min(w, h)
    left, top = (w - side) // 2, (h - side) // 2
    img = img.crop((left, top, left + side, top + side))
    if side > size:
        img = img.resize((size, size), Image.LANCZOS)
    return img


def process_static(src, dst):
    img = Image.open(src)
    img = img.convert("RGBA") if img.mode in ("RGBA", "LA", "P") else img.convert("RGB")
    square(img, 512).save(dst, "WEBP", quality=82, method=6)


def process_animated(src, dst):
    img = Image.open(src)
    frames, durations = [], []
    for frame in ImageSequence.Iterator(img):
        frames.append(square(frame.convert("RGBA"), 256))
        durations.append(frame.info.get("duration", img.info.get("duration", 80)) or 80)
    frames[0].save(
        dst,
        "WEBP",
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=img.info.get("loop", 0),
        quality=70,
        method=4,
    )


def main(src_dir, out_dir, list_file="tool/whale_files.txt"):
    manifest = {g: [] for g in ORDER}
    total = 0
    with open(list_file, encoding="utf-8") as f:
        entries = [line.split() for line in f if line.strip()]
    for group, name in entries:
        folder = FOLDER[group]
        os.makedirs(os.path.join(out_dir, folder), exist_ok=True)
        rel = f"{folder}/{os.path.splitext(name)[0]}.webp"
        dst = os.path.join(out_dir, rel)
        src = os.path.join(src_dir, name)
        if name.lower().endswith(".gif"):
            process_animated(src, dst)
        else:
            process_static(src, dst)
        size = os.path.getsize(dst)
        total += size
        manifest[group].append(rel)
        flag = "  <-- más de 1,2 MB" if size > 1.2 * 1024 * 1024 else ""
        print(f"{group:9} {rel:60} {size / 1024:8.0f} KB{flag}")
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print(f"TOTAL {total / 1024 / 1024:.2f} MB en {sum(len(v) for v in manifest.values())} archivos")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
