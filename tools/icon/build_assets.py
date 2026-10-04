#!/usr/bin/env python3
"""Сборка всех графических ассетов приложения «Булак».

Скрипт рисует кодом (Pillow + numpy) единый знак — каплю-родник с кнопкой
воспроизведения — и собирает из него полный комплект:

    assets/icon/app_icon.png                 1024×1024, иконка приложения
    assets/icon/app_icon_background.png      1024×1024, подложка adaptive icon
    assets/icon/app_icon_foreground.png      1024×1024, знак для adaptive icon
    assets/icon/app_icon_monochrome.png      1024×1024, themed icon (Android 13+)
    assets/icon/splash_logo.png              1024×1024, логотип для splash
    assets/icon/splash_logo_android12.png     960×960,   splash Android 12+

    fastlane/metadata/android/<локаль>/images/icon/icon.png      512×512
    fastlane/metadata/android/<локаль>/images/featureGraphic/... 1024×500

Почему рисунок, а не готовая картинка: геометрия знака описана формулами,
поэтому иконку можно перерисовать в любом размере без потери качества
и без графического редактора в цепочке сборки.

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

# --- Палитра (совпадает с lib/core/theme/app_colors.dart) ------------------

SKY = (42, 209, 255)
BLUE = (42, 107, 255)
VIOLET = (108, 75, 255)
MIDNIGHT = (14, 27, 58)
DEEP_BLUE = (27, 58, 168)

# --- Геометрия знака (в долях от стороны квадрата) -------------------------

# Капля строится параметрической кривой
#     x(t) = cos t,  y(t) = sin t · sin(t/2)^m
# и поворачивается остриём вверх. Чем больше m, тем тоньше хвостик.
# Так получается настоящая капля с плавным круглым низом, а не «круг
# с колпаком»: у фигуры нет изломов на стыках.
TEARDROP_M = 1.9
TEARDROP_WIDTH = 0.62
TEARDROP_HEIGHT = 0.95
TEARDROP_CENTER = (0.5, 0.5)

TRIANGLE_CENTER = (0.53, 0.70)  # оптический сдвиг вправо
TRIANGLE_SIZE = (0.30, 0.33)  # ширина и высота кнопки «играть»
TRIANGLE_CORNER = 0.05  # скругление углов треугольника


def _blend(c1: Sequence[int], c2: Sequence[int], t: float) -> tuple[float, ...]:
    return tuple(a + (b - a) * t for a, b in zip(c1, c2))


def _gradient(
    width: int,
    height: int | None = None,
    stops: Sequence[tuple[float, tuple[int, int, int]]] = ((0.0, SKY), (1.0, VIOLET)),
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


def _teardrop_mask(size: int, inset: float = 0.0) -> Image.Image:
    """Маска капли: параметрическая кривая, повёрнутая остриём вверх."""
    canvas = size * SS
    mask = Image.new("L", (canvas, canvas), 0)
    draw = ImageDraw.Draw(mask)

    scale = 1.0 - inset * 2
    cx = (inset + scale * TEARDROP_CENTER[0]) * canvas
    cy = (inset + scale * TEARDROP_CENTER[1]) * canvas

    steps = 720
    points: list[tuple[float, float]] = []
    offsets: list[float] = []
    for index in range(steps):
        t = 2.0 * math.pi * index / steps
        offsets.append(math.sin(t) * (math.sin(t / 2.0) ** TEARDROP_M))

    # Нормируем так, чтобы капля заняла заданную ширину и высоту.
    half_width = scale * TEARDROP_WIDTH / 2 * canvas
    half_height = scale * TEARDROP_HEIGHT / 2 * canvas
    y_scale = half_width / max(offsets)

    for index in range(steps):
        t = 2.0 * math.pi * index / steps
        x = math.cos(t)
        points.append(
            (
                cx + offsets[index] * y_scale,
                cy - x * half_height,
            )
        )

    draw.polygon(points, fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def _rounded_triangle_mask(size: int, inset: float = 0.0) -> Image.Image:
    """Маска кнопки «играть» со скруглёнными углами."""
    canvas = size * SS
    mask = Image.new("L", (canvas, canvas), 0)
    draw = ImageDraw.Draw(mask)

    scale = 1.0 - inset * 2
    offset = inset

    cx = (offset + scale * TRIANGLE_CENTER[0]) * canvas
    cy = (offset + scale * TRIANGLE_CENTER[1]) * canvas
    half_w = scale * TRIANGLE_SIZE[0] / 2 * canvas
    half_h = scale * TRIANGLE_SIZE[1] / 2 * canvas
    radius = scale * TRIANGLE_CORNER * canvas

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
        len_previous = (to_previous[0] ** 2 + to_previous[1] ** 2) ** 0.5
        len_following = (to_following[0] ** 2 + to_following[1] ** 2) ** 0.5
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

        # Квадратичная кривая через вершину — так угол получается круглым.
        steps = 12
        path.append(start)
        for step in range(1, steps + 1):
            t = step / steps
            x = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * current[0] + t**2 * end[0]
            y = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * current[1] + t**2 * end[1]
            path.append((x, y))

    draw.polygon(path, fill=255)
    return mask.resize((size, size), Image.LANCZOS)


def render_mark(
    size: int,
    *,
    droplet: tuple[int, int, int] = (255, 255, 255),
    triangle: tuple[int, int, int] = DEEP_BLUE,
    hole_triangle: bool = False,
    shading: bool = True,
    shadow: bool = True,
    inset: float = 0.0,
) -> Image.Image:
    """Рисует знак «капля + кнопка играть» на прозрачном фоне."""
    drop_mask = _teardrop_mask(size, inset)
    tri_mask = _rounded_triangle_mask(size, inset)

    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    if shadow:
        blur = ImageFilter.GaussianBlur(radius=size * 0.035)
        shadow_mask = drop_mask.filter(blur).point(lambda value: int(value * 0.30))
        shadow_layer = Image.new("RGBA", (size, size), (5, 20, 60, 255))
        shadow_layer.putalpha(shadow_mask)
        layer.alpha_composite(shadow_layer, (0, int(size * 0.035)))

    drop_layer = Image.new("RGBA", (size, size), (*droplet, 255))
    drop_layer.putalpha(drop_mask)
    layer.alpha_composite(drop_layer)

    if shading and not hole_triangle:
        # Мягкий объём: справа-внизу капля чуть темнее, у неё появляется форма.
        shade = _gradient(size, stops=((0.25, (255, 255, 255)), (1.0, (196, 216, 255))))
        shade_layer = shade.convert("RGBA")
        alpha = drop_mask.point(lambda value: int(value * 0.55))
        shade_layer.putalpha(alpha)
        layer.alpha_composite(shade_layer)

        gloss_mask = Image.new("L", (size, size), 0)
        gloss_draw = ImageDraw.Draw(gloss_mask)
        gloss_draw.ellipse(
            [
                size * (0.30 + inset),
                size * (0.44 + inset),
                size * (0.47 + inset),
                size * (0.58 + inset),
            ],
            fill=110,
        )
        gloss_mask = gloss_mask.filter(ImageFilter.GaussianBlur(radius=size * 0.03))
        gloss_mask = Image.composite(gloss_mask, Image.new("L", (size, size), 0), drop_mask)
        gloss_layer = Image.new("RGBA", (size, size), (255, 255, 255, 255))
        gloss_layer.putalpha(gloss_mask)
        layer.alpha_composite(gloss_layer)

    if hole_triangle:
        # В монохромной иконке кнопка вырезается: система сама её подкрасит.
        punch = Image.new("L", (size, size), 0)
        punch.paste(tri_mask, (0, 0))
        layer.putalpha(Image.composite(Image.new("L", (size, size), 0), layer.getchannel("A"), punch))
    else:
        tri_layer = Image.new("RGBA", (size, size), (*triangle, 255))
        tri_layer.putalpha(tri_mask)
        layer.alpha_composite(tri_layer)

    return layer


def compose_icon(
    size: int,
    *,
    background: Image.Image | None,
    mark: Image.Image | None,
    mark_scale: float = 0.62,
    rounded: bool = False,
) -> Image.Image:
    """Собирает готовую иконку из фона и знака."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    if background is not None:
        canvas.alpha_composite(background.convert("RGBA").resize((size, size), Image.LANCZOS))

    if mark is not None:
        mark_size = int(size * mark_scale)
        mark_resized = mark.resize((mark_size, mark_size), Image.LANCZOS)
        offset = ((size - mark_size) // 2, (size - mark_size) // 2)
        canvas.alpha_composite(mark_resized, offset)

    if rounded:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, size - 1, size - 1],
            radius=int(size * 0.22),
            fill=255,
        )
        canvas.putalpha(mask)

    return canvas


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
        stops=((0.0, SKY), (0.55, BLUE), (1.0, VIOLET)),
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

    mark_box = 400
    mark = render_mark(mark_box, droplet=(255, 255, 255), triangle=DEEP_BLUE, shadow=True)
    base.alpha_composite(mark, (48, (height - mark_box) // 2))

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
        fill=(255, 255, 255, 235),
        anchor="ls",
    )

    return base.convert("RGB")


def main() -> int:
    ICON_DIR.mkdir(parents=True, exist_ok=True)

    background = _gradient(1024, stops=((0.0, SKY), (0.55, BLUE), (1.0, VIOLET))).convert("RGB")
    mark = render_mark(1024)
    mark_foreground = render_mark(1024, shadow=False)
    mark_monochrome = render_mark(
        1024,
        droplet=(255, 255, 255),
        hole_triangle=True,
        shading=False,
        shadow=False,
    )
    splash_mark = render_mark(1024, triangle=MIDNIGHT, shadow=False, shading=False)

    # --- Основная иконка приложения (iOS + legacy Android) ------------------
    compose_icon(1024, background=background, mark=mark, mark_scale=0.66).convert("RGB").save(
        ICON_DIR / "app_icon.png"
    )

    # --- Adaptive icon (Android 8+) ----------------------------------------
    background.save(ICON_DIR / "app_icon_background.png")

    # Знак для adaptive icon держим внутри «безопасной» зоны: система может
    # обрезать иконку по кругу, поэтому центр занимает примерно 62 % полотна.
    inner = 640
    foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    foreground.alpha_composite(
        mark_foreground.resize((inner, inner), Image.LANCZOS),
        ((1024 - inner) // 2, (1024 - inner) // 2),
    )
    foreground.save(ICON_DIR / "app_icon_foreground.png")
    mark_monochrome.save(ICON_DIR / "app_icon_monochrome.png")

    # --- Splash -------------------------------------------------------------
    splash = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    splash.alpha_composite(splash_mark.resize((700, 700), Image.LANCZOS), (162, 162))
    splash.save(ICON_DIR / "splash_logo.png")

    splash12 = Image.new("RGBA", (960, 960), (0, 0, 0, 0))
    splash12.alpha_composite(splash_mark.resize((560, 560), Image.LANCZOS), (200, 200))
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

        compose_icon(512, background=background, mark=mark, mark_scale=0.66).convert("RGB").save(
            icon_dir / "icon.png"
        )
        build_feature_graphic(title, tagline).save(graphic_dir / "featureGraphic.png")

    print("Готово. Собраны:")
    for path in sorted(ICON_DIR.glob("*.png")):
        print(f"  assets/icon/{path.name}")
    for locale in store_variants:
        print(f"  fastlane/metadata/android/{locale}/images/icon/icon.png")
        print(f"  fastlane/metadata/android/{locale}/images/featureGraphic/featureGraphic.png")
    return 0


if __name__ == "__main__":
    sys.exit(main())
