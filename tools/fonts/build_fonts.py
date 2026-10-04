#!/usr/bin/env python3
"""Сборка статических начертаний шрифтов для приложения «Булак».

Зачем это нужно
---------------
В репозитории Google Fonts шрифты Nunito и Comfortaa лежат только в виде
вариативных файлов (`Nunito[wght].ttf`). Flutter не умеет автоматически
выбирать начертание из вариативного файла по `fontWeight` в pubspec,
а синтетический «жирный» выглядит грязно. Поэтому мы один раз
«замораживаем» нужные веса в отдельные статические TTF и заодно
вырезаем из них всё лишнее (сабсетинг), чтобы не тащить в сборку
лишние сотни килобайт.

Что получается
--------------
    assets/fonts/Nunito-Regular.ttf     (400)
    assets/fonts/Nunito-SemiBold.ttf    (600)
    assets/fonts/Nunito-Bold.ttf        (700)
    assets/fonts/Nunito-ExtraBold.ttf   (800)
    assets/fonts/Comfortaa-Bold.ttf     (700)

Запуск (нужен интернет, ставится один раз):

    pip install fonttools brotli
    python tools/fonts/build_fonts.py

Скрипт идемпотентен: повторный запуск просто перезаписывает файлы.
"""

from __future__ import annotations

import io
import sys
import urllib.request
from pathlib import Path

# Windows-консоль по умолчанию не в UTF-8, а сообщения скрипта на русском.
for stream in (sys.stdout, sys.stderr):
    if hasattr(stream, "reconfigure"):
        stream.reconfigure(encoding="utf-8", errors="replace")

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools.subset import Subsetter, Options, parse_unicodes

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = REPO_ROOT / "assets" / "fonts"

RAW = "https://raw.githubusercontent.com/google/fonts/main"

# Диапазоны символов, которые должны остаться в шрифте.
# Латиница, кириллица, греческий, типографика, стрелки, геометрия и звёздочки —
# всё, что интерфейс может показать текстом (эмодзи приходят из системного шрифта).
UNICODES = [
    "U+0000-024F",  # basic latin, latin-1, latin extended A/B
    "U+0250-02FF",  # IPA / modifiers
    "U+0300-036F",  # combining diacritics
    "U+0370-03FF",  # greek
    "U+0400-052F",  # cyrillic + cyrillic supplement
    "U+1E00-1EFF",  # latin extended additional
    "U+2000-206F",  # general punctuation
    "U+2070-209F",  # super/subscripts
    "U+20A0-20BF",  # currency
    "U+2100-214F",  # letterlike symbols
    "U+2190-21FF",  # arrows
    "U+2200-22FF",  # math operators
    "U+2460-24FF",  # enclosed alphanumerics
    "U+25A0-25FF",  # geometric shapes
    "U+2600-27BF",  # misc symbols + dingbats
    "U+2C60-2C7F",  # latin extended C
    "U+A640-A69F",  # cyrillic extended B
    "U+FB00-FB06",  # latin ligatures
    "U+FEFF",       # BOM / zero width no-break space
    "U+FFFD",       # replacement character
]

# family: (имя файла вариативного шрифта в google/fonts, {вес: имя выходного файла})
TARGETS = {
    "Nunito": (
        "ofl/nunito/Nunito%5Bwght%5D.ttf",
        {
            400: "Nunito-Regular.ttf",
            600: "Nunito-SemiBold.ttf",
            700: "Nunito-Bold.ttf",
            800: "Nunito-ExtraBold.ttf",
        },
    ),
    "Comfortaa": (
        "ofl/comfortaa/Comfortaa%5Bwght%5D.ttf",
        {
            700: "Comfortaa-Bold.ttf",
        },
    ),
}


def download(url: str) -> bytes:
    print(f"  скачиваю {url}")
    request = urllib.request.Request(url, headers={"User-Agent": "bulak-font-builder"})
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read()


def instance_and_subset(data: bytes, weight: int) -> bytes:
    """Возвращает статический сабсет шрифта для указанного веса."""
    font = TTFont(io.BytesIO(data))

    # Замораживаем ось веса. В некоторых файлах ось называется wght.
    axes = {axis.axisTag: axis for axis in font["fvar"].axes}
    if "wght" in axes:
        axis = axes["wght"]
        if not (axis.minValue <= weight <= axis.maxValue):
            raise SystemExit(
                f"вес {weight} вне диапазона {axis.minValue}-{axis.maxValue}"
            )
        font = instancer.instantiateVariableFont(font, {"wght": weight}, inplace=False)

    options = Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.notdef_outline = True
    options.recalc_bounds = True
    options.drop_tables += ["DSIG"]
    options.glyph_names = False
    options.hinting = True

    subsetter = Subsetter(options=options)
    subsetter.populate(unicodes=parse_unicodes(",".join(UNICODES)))
    subsetter.subset(font)

    buffer = io.BytesIO()
    font.save(buffer)
    return buffer.getvalue()


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    total = 0

    for family, (path, weights) in TARGETS.items():
        print(f"{family}:")
        raw = download(f"{RAW}/{path}")
        for weight, filename in sorted(weights.items()):
            payload = instance_and_subset(raw, weight)
            target = OUT_DIR / filename
            target.write_bytes(payload)
            total += len(payload)
            print(f"  -> {filename} ({len(payload) / 1024:.1f} КиБ, вес {weight})")

    print(f"готово, суммарно {total / 1024:.1f} КиБ в {OUT_DIR}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
