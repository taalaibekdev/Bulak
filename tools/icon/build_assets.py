#!/usr/bin/env python3
"""Сборка всех графических ассетов приложения «Булак».

Знак — как у YouTube (скруглённый квадрат с белым треугольником
воспроизведения), но в фирменном зелёном цвете. Скрипт рисует его кодом
(Pillow + numpy) и собирает полный комплект:

    assets/icon/app_icon.png                 1024×1024, иконка приложения
    assets/icon/app_icon_background.png      1024×1024, подложка adaptive icon
    assets/icon/app_icon_foreground.png      1024×1024, треугольник для adaptive icon
    assets/icon/app_icon_monochrome.png      1024×1024, themed icon (Android 13+)
    assets/icon/splash_logo.png              1024×1024, логотип для splash
    assets/icon/splash_logo_android12.png     960×960,   splash Android 12+
    assets/icon/logo_mark.png                 512×512,   логотип для сайта и писем

    fastlane/metadata/android/<локаль>/images/icon/icon.png      512×512
    fastlane/metadata/android/<локаль>/images/featureGraphic/... 1024×500

Почему рисунок, а не готовая картинка: геометрия описана формулами, поэтому
иконку можно перерисовать в любом размере без потери качества и без
графического редактора в цепочке сборки.

Запуск (нужен Pillow и numpy):

    python tools/icon/build_assets.py

Затем:

    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
"""

from __future__ import annotations

import math
import sys
from pathlib import Path
from typing import Sequence

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# Сглаживание: рисуем в 4 раза крупнее и уменьшаем — края получаются гладкими.
SS = 4

REPO_ROOT = Path(__file__).resolve().parents[2]
ICON_DIR = REPO_ROOT / "assets" / "icon"
FONT_DIR = REPO_ROOT / "assets" / "fonts"
FASTLANE_DIR = REPO_ROOT / "fastlane" / "metadata" / "android"

# --- Палитра ---------------------------------------------------------------

# Фирменный зелёный: яркий и приятный, но не «кислотный».
GREEN_LIGHT = (74, 222, 128)  # #4ADE80
GREEN_MID = (34, 197, 94)  # #22C55E
GREEN_DARK = (22, 163, 74)  # #16A34A
WHITE = (255, 255, 255)

# --- Геометрия знака -------------------------------------------------------

# Скругление квадрата: у иконки YouTube это примерно четверть стороны.
CORNER_RATIO = 0.235

# Треугольник воспроизведения. Пропорции сняты с иконки YouTube:
# высота чуть больше ширины, углы скруглённые.
TRIANGLE_WIDTH = 0.30
TRIANGLE_HEIGHT = 0.34
TRIANGLE_CORNER = 0.055
# Оптический сдвиг вправо: геометрически центрированный треугольник
# кажется смещённым влево.
TRIANGLE_OFFSET_X = 0.022

# Для adaptive icon видна только центральная часть холста (примерно 66 %),
# поэтому треугольник там крупнее относительно холста.
ADAPTIVE_TRIANGLE_SCALE = 1.34


def _gradient(
    width: int,
    height: int | None = None,
    stops: Sequence[tuple[float, tuple[int, int, int]]] = (
        (0.0, GREEN_LIGHT),
        (1.0, GREEN_DARK),
    ),
) -> Image.Image:
    """Диагональный градиент по списку (позиция, цвет)."""
    height = height or width
    ys, xs = np.mgrid[0:height, 0:width]
    t = (xs / max(width - 1, 1) + ys / max(height - 1, 1)) / 2.0

    positions = [stop[0] for stop in stops]
    colors = np.array([stop[1] for stop in stops], dtype=float)

    out = np.zeros((height, width, 3), dtype=float)
    for channel in range(3):
        out[:, :, channel] = np.interp(t, positions, colors[:, channel])

    return Image.fromarray(out.round().clip(0, 255).astype(np.uint8), "RGB")


def _rounded_square_mask(size: int, inset: float = 0.0) -> Image.Image:
    """Маска скруглённого квадрата — форма иконки YouTube."""
    canvas = size * SS
    mask = Image.new("L", (canvas, canvas), 0)
    draw = ImageDraw.Draw(mask)

    margin = inset * canvas
    radius = CORNER_RATIO * (canvas - margin * 2)
    draw.rounded_rectangle(
        [margin, margin, canvas - margin, canvas - margin],
        radius=radius,
        fill=255,
    )
    return mask.resize((size, size), Image.LANCZOS)


def _rounded_triangle_mask(
    size: int,
    *,
    width_ratio: float = TRIANGLE_WIDTH,
    height_ratio: float = TRIANGLE_HEIGHT,
    corner_ratio: float = TRIANGLE_CORNER,
) -> Image.Image:
    """Маска треугольника воспроизведения со скруглёнными углами."""
    canvas = size * SS
    mask = Image.new("L", (canvas, canvas), 0)
    draw = ImageDraw.Draw(mask)

    cx = (0.5 + TRIANGLE_OFFSET_X) * canvas
    cy = 0.5 * canvas
    half_w = width_ratio / 2 * canvas
    half_h = height_ratio / 2 * canvas
    radius = corner_ratio * canvas

    points = [
        (cx - half_w, cy - half_h),
        (cx + half_w, cy),
        (cx - half_w, cy + half_h),
    ]

    path: list[tuple[float, float]] = []
    count = len(points)
    for index in range(count):
        previous = points[(index - 1) % count]
        current = points[index]
        following = points[(index + 1) % count]

        to_previous = (previous[0] - current[0], previous[1] - current[1])
        to_following = (following[0] - current[0], following[1] - current[1])
        len_previous = math.hypot(*to_previous)
        len_following = math.hypot(*to_following)
        if len_previous == 0 or len_following == 0:
            continue

        corner = min(radius, len_previous / 2, len_following / 2)
        start = (
            current[0] + to_previous[0] / len_previous * corner,
            current[1] + to_previous[1] / len_previous * corner,
        )
        end = (
            current[0] + to_following[0] / len_following * corner,
            current[1] + to_following[1] / len_following * corner,
        )

        # Квадратичная кривая через вершину — угол получается круглым.
        steps = 14
        path.append(start)
        for step in range(1, steps + 1):
            t = step / steps
            x = (
                (1 - t) ** 2 * start[0]
                + 2 * (1 - t) * t * current[0]
                + t**2 * end[0]
            )
            y = (
                (1 - t) ** 2 * start[1]
                + 2 * (1 - t) * t * current[1]
                + t**2 * end[1]
            )
            path.append((x, y))

    draw.polygon(path, fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def render_triangle(
    size: int,
    *,
    color: tuple[int, int, int] = WHITE,
    width_ratio: float = TRIANGLE_WIDTH,
    height_ratio: float = TRIANGLE_HEIGHT,
    corner_ratio: float = TRIANGLE_CORNER,
    shadow: bool = False,
) -> Image.Image:
    """Белый треугольник воспроизведения на прозрачном фоне."""
    mask = _rounded_triangle_mask(
        size,
        width_ratio=width_ratio,
        height_ratio=height_ratio,
        corner_ratio=corner_ratio,
    )

    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    if shadow:
        blur = ImageFilter.GaussianBlur(radius=size * 0.012)
        shadow_mask = mask.filter(blur).point(lambda value: int(value * 0.22))
        shadow_layer = Image.new("RGBA", (size, size), (6, 40, 24, 255))
        shadow_layer.putalpha(shadow_mask)
        layer.alpha_composite(shadow_layer, (0, int(size * 0.012)))

    triangle = Image.new("RGBA", (size, size), (*color, 255))
    triangle.putalpha(mask)
    layer.alpha_composite(triangle)
    return layer


def render_mark(
    size: int,
    *,
    rounded: bool = True,
    inset: float = 0.0,
    shadow: bool = False,
) -> Image.Image:
    """Знак целиком: зелёный скруглённый квадрат с белым треугольником."""
    base = _gradient(size).convert("RGBA")

    if rounded:
        base.putalpha(_rounded_square_mask(size, inset))

    if shadow:
        blur = ImageFilter.GaussianBlur(radius=size * 0.03)
        shadow_mask = base.getchannel("A").filter(blur).point(
            lambda value: int(value * 0.35)
        )
        shadow_layer = Image.new("RGBA", (size, size), (6, 40, 24, 255))
        shadow_layer.putalpha(shadow_mask)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        canvas.alpha_composite(shadow_layer, (0, int(size * 0.018)))
        canvas.alpha_composite(base)
        base = canvas

    base.alpha_composite(render_triangle(size))
    return base


def _font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


def _fit_font(
    name: str,
    size: int,
    text: str,
    max_width: int,
    min_size: int = 14,
) -> ImageFont.FreeTypeFont:
    """Подбирает размер шрифта так, чтобы строка поместилась по ширине."""
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    while size > min_size:
        font = _font(name, size)
        if probe.textlength(text, font=font) <= max_width:
            return font
        size -= 2
    return _font(name, min_size)


def build_feature_graphic(title: str, tagline: str) -> Image.Image:
    """Feature graphic 1024×500 для Google Play."""
    width, height = 1024, 500
    base = _gradient(
        width,
        height,
        stops=((0.0, GREEN_LIGHT), (0.55, GREEN_MID), (1.0, GREEN_DARK)),
    ).convert("RGBA")

    # Мягкое световое пятно, чтобы фон не выглядел плоским.
    glow = Image.new("L", (width, height), 0)
    ImageDraw.Draw(glow).ellipse([-160, -220, 520, 340], fill=95)
    glow = glow.filter(ImageFilter.GaussianBlur(radius=95))
    base.alpha_composite(
        Image.composite(
            Image.new("RGBA", (width, height), (255, 255, 255, 255)),
            Image.new("RGBA", (width, height), (255, 255, 255, 0)),
            glow,
        )
    )

    mark_box = 300
    mark = render_mark(mark_box, shadow=True)
    base.alpha_composite(mark, (78, (height - mark_box) // 2))

    text_x = 470
    max_text_width = width - text_x - 40

    title_font = _fit_font("Comfortaa-Bold.ttf", 112, title, max_text_width)
    tagline_font = _fit_font("Nunito-SemiBold.ttf", 32, tagline, max_text_width)

    draw = ImageDraw.Draw(base)
    draw.text(
        (text_x, 236),
        title,
        font=title_font,
        fill=(255, 255, 255, 255),
        anchor="ls",
    )
    draw.text(
        (text_x + 4, 296),
        tagline,
        font=tagline_font,
        fill=(255, 255, 255, 240),
        anchor="ls",
    )

    return base.convert("RGB")


def main() -> int:
    ICON_DIR.mkdir(parents=True, exist_ok=True)

    # --- Иконка приложения (iOS + legacy Android) --------------------------
    # iOS сам скругляет квадрат, поэтому фон заливаем целиком, без полей.
    app_icon = _gradient(1024).convert("RGBA")
    app_icon.alpha_composite(render_triangle(1024, shadow=True))
    app_icon.convert("RGB").save(ICON_DIR / "app_icon.png")

    # --- Adaptive icon (Android 8+) ---------------------------------------
    # Подложка — зелёный градиент, поверх — только треугольник: систему
    # остаётся придать иконке нужную форму (круг, squircle, квадрат).
    _gradient(1024).save(ICON_DIR / "app_icon_background.png")

    adaptive_triangle = render_triangle(
        1024,
        width_ratio=TRIANGLE_WIDTH * ADAPTIVE_TRIANGLE_SCALE,
        height_ratio=TRIANGLE_HEIGHT * ADAPTIVE_TRIANGLE_SCALE,
        corner_ratio=TRIANGLE_CORNER * ADAPTIVE_TRIANGLE_SCALE,
        shadow=True,
    )
    foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    foreground.alpha_composite(adaptive_triangle)
    foreground.save(ICON_DIR / "app_icon_foreground.png")

    # Монохромная иконка (Android 13+): только треугольник, красит система.
    monochrome = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    monochrome.alpha_composite(
        render_triangle(
            1024,
            width_ratio=TRIANGLE_WIDTH * ADAPTIVE_TRIANGLE_SCALE,
            height_ratio=TRIANGLE_HEIGHT * ADAPTIVE_TRIANGLE_SCALE,
            corner_ratio=TRIANGLE_CORNER * ADAPTIVE_TRIANGLE_SCALE,
        )
    )
    monochrome.save(ICON_DIR / "app_icon_monochrome.png")

    # --- Логотип для интерфейса, сайта и писем ----------------------------
    render_mark(512, shadow=True).save(ICON_DIR / "logo_mark.png")

    # --- Splash -------------------------------------------------------------
    splash = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    splash.alpha_composite(
        render_mark(560).resize((560, 560), Image.LANCZOS),
        (232, 232),
    )
    splash.save(ICON_DIR / "splash_logo.png")

    splash12 = Image.new("RGBA", (960, 960), (0, 0, 0, 0))
    splash12.alpha_composite(
        render_mark(500).resize((500, 500), Image.LANCZOS),
        (230, 230),
    )
    splash12.save(ICON_DIR / "splash_logo_android12.png")

    # --- Материалы для Google Play -----------------------------------------
    store_variants = {
        "ru-RU": ("Булак", "Только видео, которые выбрали родители"),
        "en-US": ("Bulak", "Only videos picked by parents"),
    }

    for locale, (title, tagline) in store_variants.items():
        icon_dir = FASTLANE_DIR / locale / "images" / "icon"
        graphic_dir = FASTLANE_DIR / locale / "images" / "featureGraphic"
        icon_dir.mkdir(parents=True, exist_ok=True)
        graphic_dir.mkdir(parents=True, exist_ok=True)

        store_icon = _gradient(512).convert("RGBA")
        store_icon.alpha_composite(render_triangle(512, shadow=True))
        store_icon.convert("RGB").save(icon_dir / "icon.png")

        build_feature_graphic(title, tagline).save(
            graphic_dir / "featureGraphic.png"
        )

    print("Готово. Собраны:")
    for path in sorted(ICON_DIR.glob("*.png")):
        print(f"  assets/icon/{path.name}")
    for locale in store_variants:
        print(f"  fastlane/metadata/android/{locale}/images/icon/icon.png")
        print(
            f"  fastlane/metadata/android/{locale}/images/featureGraphic/featureGraphic.png"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
