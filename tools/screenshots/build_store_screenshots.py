#!/usr/bin/env python3
"""Сборка скриншотов для магазинов из реальных снимков экрана.

Зачем нужно преобразование
--------------------------
Google Play требует, чтобы соотношение сторон скриншота телефона было
в диапазоне от 16:9 до 9:16. Экран современного телефона — вытянутый
(например, 1080×2340, это 1:2,17), поэтому «сырой» снимок в магазин
не примут. Скрипт вписывает снимок целиком в холст 1080×1920 (9:16)
на фирменном фоне — интерфейс виден полностью, ничего не обрезано.

App Store, наоборот, ждёт ровно 1290×2796 для 6,7″ — это то же
соотношение 1:2,17, что и у эмулятора, поэтому для iOS снимок просто
масштабируется без полей.

Запуск:

    python tools/screenshots/build_store_screenshots.py

Исходники берутся из каталога, указанного в переменной окружения
BULAK_SHOTS (по умолчанию — `screenshots/raw` внутри репозитория),
результат складывается в `fastlane/metadata/android/<локаль>/images/phoneScreenshots/`
и в `fastlane/screenshots/<локаль>/`.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

for stream in (sys.stdout, sys.stderr):
    if hasattr(stream, "reconfigure"):
        stream.reconfigure(encoding="utf-8", errors="replace")

REPO_ROOT = Path(__file__).resolve().parents[2]

DEFAULT_RAW_DIR = REPO_ROOT / "screenshots" / "raw"

# Соответствие «имя файла-исходника → подпись под номером в магазине».
# Порядок в списке — это порядок скриншотов в листинге.
SCREENSHOTS: list[tuple[str, str, str]] = [
    (
        "01_onboarding.png",
        "Только видео, которые выбрали родители",
        "Only the videos parents picked",
    ),
    (
        "02_home.png",
        "Мультики и музыка — крупными карточками",
        "Cartoons and music as big friendly cards",
    ),
    (
        "03_collections.png",
        "Свои коллекции: «Мультики», «Музыка», «Любимое»",
        "Your own playlists: cartoons, music, favourites",
    ),
    (
        "04_collection_detail.png",
        "Внутри коллекции — только её видео",
        "Inside a playlist: only its own videos",
    ),
    (
        "05_player.png",
        "Плеер без лишнего: видео и большие кнопки",
        "A player without clutter: video and big buttons",
    ),
    (
        "06_time_limit.png",
        "Сколько смотреть в день — решают родители",
        "Parents decide how much watching per day",
    ),
    (
        "07_parent_home.png",
        "Родительский режим под PIN-кодом",
        "Parent mode behind a PIN",
    ),
    (
        "08_add_video.png",
        "Добавить видео — просто вставить ссылку",
        "Add a video by pasting a YouTube link",
    ),
]

BRAND_TOP = (42, 209, 255)
BRAND_MID = (42, 107, 255)
BRAND_BOTTOM = (108, 75, 255)


def _gradient(width: int, height: int) -> Image.Image:
    """Вертикальный градиент бренда — фон для скриншотов Android."""
    column = Image.new("RGB", (1, height))
    pixels = column.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        if t < 0.5:
            local = t / 0.5
            color = tuple(
                round(BRAND_TOP[i] + (BRAND_MID[i] - BRAND_TOP[i]) * local)
                for i in range(3)
            )
        else:
            local = (t - 0.5) / 0.5
            color = tuple(
                round(BRAND_MID[i] + (BRAND_BOTTOM[i] - BRAND_MID[i]) * local)
                for i in range(3)
            )
        pixels[0, y] = color
    return column.resize((width, height), Image.NEAREST)


def _rounded(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, image.size[0] - 1, image.size[1] - 1],
        radius=radius,
        fill=255,
    )
    result = image.convert("RGBA")
    result.putalpha(mask)
    return result


def android_frame(raw: Image.Image) -> Image.Image:
    """Вписывает снимок целиком в холст 1080×1920 (9:16)."""
    canvas_w, canvas_h = 1080, 1920
    background = _gradient(canvas_w, canvas_h).convert("RGBA")

    scale = canvas_h / raw.height
    shot_w = round(raw.width * scale)
    shot_h = canvas_h
    shot = raw.convert("RGB").resize((shot_w, shot_h), Image.LANCZOS)
    shot = _rounded(shot, radius=36)

    x = (canvas_w - shot_w) // 2

    shadow = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 90), (x, 0), shot.getchannel("A"))
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    background.alpha_composite(shadow)
    background.alpha_composite(shot, (x, 0))

    return background.convert("RGB")


def ios_resize(raw: Image.Image) -> Image.Image:
    """App Store ждёт 1290×2796 для 6,7″ — соотношение совпадает."""
    return raw.convert("RGB").resize((1290, 2796), Image.LANCZOS)


def main() -> int:
    # Для каждой локали — свой каталог исходников: интерфейс на английском
    # листинге должен быть английским, а не переведённой картинкой.
    locales = (
        ("ru-RU", "ru", DEFAULT_RAW_DIR),
        ("en-US", "en-US", REPO_ROOT / "screenshots" / "raw-en"),
    )

    created = 0
    for locale_android, locale_ios, raw_dir in locales:
        if not raw_dir.exists():
            print(f"Нет каталога с исходниками для {locale_android}: {raw_dir}")
            continue

        android_dir = (
            REPO_ROOT
            / "fastlane"
            / "metadata"
            / "android"
            / locale_android
            / "images"
            / "phoneScreenshots"
        )
        ios_dir = REPO_ROOT / "fastlane" / "screenshots" / locale_ios
        android_dir.mkdir(parents=True, exist_ok=True)
        ios_dir.mkdir(parents=True, exist_ok=True)

        for index, (filename, _ru_caption, _en_caption) in enumerate(
            SCREENSHOTS, start=1
        ):
            source = raw_dir / filename
            if not source.exists():
                print(f"  пропускаю (нет файла): {filename}")
                continue

            with Image.open(source) as raw:
                android_frame(raw).save(android_dir / f"{index:02d}.png")
                ios_resize(raw).save(ios_dir / f"{index:02d}.png")
            created += 2

        print(f"  {locale_android}: {android_dir}")
        print(f"  {locale_ios}: {ios_dir}")

    print(f"Готово, файлов: {created}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
