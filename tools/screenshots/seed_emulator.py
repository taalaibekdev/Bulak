#!/usr/bin/env python3
"""Наполнение эмулятора демонстрационной библиотекой для скриншотов.

Скрипт нужен только для съёмки скриншотов в магазины: он кладёт в
`shared_preferences` уже запущенного на эмуляторе приложения готовые
коллекции с русскими названиями (ввести кириллицу через `adb shell input
text` невозможно — эта команда понимает только ASCII).

Видео при этом добавляются обычным путём, через интерфейс: так названия
и превью приходят из самого YouTube, а не придумываются.

Требуется эмулятор с правами root (`adb root`) и установленное приложение.

Запуск:

    python tools/screenshots/seed_emulator.py
"""

from __future__ import annotations

import base64
import hashlib
import json
import re
import secrets
import subprocess
import sys
from pathlib import Path
from xml.sax.saxutils import escape

for stream in (sys.stdout, sys.stderr):
    if hasattr(stream, "reconfigure"):
        stream.reconfigure(encoding="utf-8", errors="replace")

PACKAGE = "kg.tlbk.bulak"
PREFS = f"/data/data/{PACKAGE}/shared_prefs/FlutterSharedPreferences.xml"

# PIN-код, который скрипт задаёт на чистой установке. Такой же, как в
# документации по съёмке скриншотов.
PIN = "4821"
ADB = str(
    Path.home()
    / "AppData"
    / "Local"
    / "Android"
    / "Sdk"
    / "platform-tools"
    / "adb.exe"
)

# Если подключено несколько устройств, нужно указать нужное: --serial emulator-5554
SERIAL_ARGS: list[str] = []
if "--serial" in sys.argv:
    index = sys.argv.index("--serial")
    if index + 1 < len(sys.argv):
        SERIAL_ARGS.extend(["-s", sys.argv[index + 1]])

# Коллекции, которые должны появиться в приложении.
def collections_for(locale: str) -> list[dict]:
    titles = (
        [
            ("demo-toons", "Мультфильмдер", "🧸", 0),
            ("demo-music", "Музыка", "🎵", 1),
            ("demo-favourite", "Сүйүктүүлөр", "⭐", 4),
        ]
        if locale == "ky"
        else (
            [
                ("demo-toons", "Мультики", "🧸", 0),
                ("demo-music", "Музыка", "🎵", 1),
                ("demo-favourite", "Любимое", "⭐", 4),
            ]
            if locale == "ru"
            else [
                ("demo-toons", "Cartoons", "🧸", 0),
                ("demo-music", "Music", "🎵", 1),
                ("demo-favourite", "Favourites", "⭐", 4),
            ]
        )
    )
    return [
        {
            "id": item_id,
            "title": title,
            "emoji": emoji,
            "colorIndex": color,
            "sortOrder": order,
            "createdAt": f"2026-09-2{order}T10:00:00.000",
        }
        for order, (item_id, title, emoji, color) in enumerate(titles)
    ]


# Демонстрационная библиотека для скриншотов.
#
# Идентификаторы — настоящие видео YouTube, чтобы на кадрах были живые
# превью, а не серые заглушки. Прогресс просмотра задан так, чтобы на
# главной появился блок «Продолжить», а одно видео было досмотрено до конца.
DEMO_VIDEOS = [
    # (id, название, автор, длительность, коллекция, просмотрено, избранное)
    ("hT_nvWreIhg", "OneRepublic - Counting Stars", "OneRepublicVEVO", 283, 1, 96, True),
    ("jNQXAC9IVRw", "Me at the zoo", "jawed", 19, 0, 19, False),
    ("9bZkp7q19f0", "PSY - GANGNAM STYLE", "officialpsy", 253, 1, 40, True),
    ("RgKAFK5djSk", "Wiz Khalifa - See You Again", "Wiz Khalifa", 229, 1, 0, False),
    ("OPf0YbXqDm0", "Mark Ronson - Uptown Funk", "Mark Ronson", 270, 1, 0, False),
    ("fJ9rUzIMcZQ", "Queen - Bohemian Rhapsody", "Queen Official", 355, 2, 0, True),
    ("JGwWNGJdvx8", "Ed Sheeran - Shape of You", "Ed Sheeran", 263, 2, 0, False),
    ("60ItHLz5WEA", "Alan Walker - Faded", "Alan Walker", 212, 0, 0, False),
    ("kJQP7kiw5Fk", "Luis Fonsi - Despacito", "Luis Fonsi", 282, 0, 0, False),
]


def videos_for(collections: list[dict]) -> list[dict]:
    """Собирает JSON библиотеки из [DEMO_VIDEOS]."""
    ids = [item["id"] for item in collections]
    videos = []
    for order, (video_id, title, author, seconds, group, watched, favorite) in enumerate(
        DEMO_VIDEOS
    ):
        videos.append(
            {
                "id": video_id,
                "title": title,
                "author": author,
                "durationSeconds": seconds,
                "collectionId": ids[group % len(ids)],
                "favorite": favorite,
                "addedAt": f"2026-09-2{order % 9}T12:00:00.000",
                "watchedSeconds": watched,
                **(
                    {"lastWatchedAt": f"2026-10-0{order % 9 + 1}T18:00:00.000"}
                    if watched
                    else {}
                ),
            }
        )
    return videos


# Настройки: дневной лимит, чтобы на главной был виден баннер с остатком.
SETTINGS_EXTRA = {
    "dailyLimitMinutes": 30,
    "watchedSecondsToday": 420,
}


def adb(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [ADB, *SERIAL_ARGS, *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if check and result.returncode != 0:
        print(f"adb {' '.join(args)} -> {result.returncode}")
        print(result.stdout)
        print(result.stderr)
    return result


def main() -> int:
    # С флагом --reset-onboarding приложение запустится как в первый раз:
    # это нужно, чтобы снять экран приветствия.
    reset_onboarding = "--reset-onboarding" in sys.argv

    # --locale ky|ru|en переключает интерфейс приложения: каждому листингу
    # нужны снимки на своём языке, а кыргызский — основной язык продукта.
    locale = None
    if "--locale" in sys.argv:
        index = sys.argv.index("--locale")
        if index + 1 < len(sys.argv) and sys.argv[index + 1] in ("ky", "ru", "en"):
            locale = sys.argv[index + 1]

    adb("root")
    adb("shell", "am", "force-stop", PACKAGE)

    raw = adb("shell", "cat", PREFS, check=False).stdout
    fresh_install = "<map>" not in raw
    if fresh_install:
        # Приложение ещё ни разу не запускалось (например, после pm clear).
        # Это не повод останавливаться: создаём файл настроек сами, вместе
        # с PIN-кодом, чтобы родительский раздел сразу открывался.
        print("Настроек нет — создаю файл с нуля.")

    def unescape(value: str) -> str:
        return (
            value.replace("&quot;", '"')
            .replace("&apos;", "'")
            .replace("&lt;", "<")
            .replace("&gt;", ">")
            .replace("&amp;", "&")
        )

    # Читаем все сохранённые значения: список видео и прочие ключи трогать
    # нельзя, иначе библиотека, собранная вручную, будет потеряна.
    stored: dict[str, str] = {}
    for match in re.finditer(
        r'<string name="flutter\.([^"]+)">(.*?)</string>', raw, re.DOTALL
    ):
        stored[match.group(1)] = unescape(match.group(2))

    # Достаём текущие настройки, чтобы не потерять PIN-код родителя.
    settings = json.loads(stored.get("bulak.settings.v1", "{}"))
    settings.update(SETTINGS_EXTRA)
    settings["onboardingCompleted"] = not reset_onboarding
    if locale is not None:
        settings["localeCode"] = locale

    # На чистой установке PIN-кода нет — задаём его, иначе родительский
    # раздел нечем открыть. Хэш считаем так же, как приложение.
    if fresh_install and "pinHash" not in settings:
        salt = base64.urlsafe_b64encode(secrets.token_bytes(16)).decode()
        digest = hashlib.sha256(f"{salt}|{PIN}|bulak".encode()).hexdigest()
        settings["pinSalt"] = salt
        settings["pinHash"] = digest

    stored["bulak.settings.v1"] = json.dumps(settings, ensure_ascii=False)

    collections = collections_for(locale or settings.get("localeCode") or "ky")
    stored["bulak.collections.v1"] = json.dumps(collections, ensure_ascii=False)

    # Библиотеку заполняем, только если она пустая или её просили обновить:
    # иначе можно случайно затереть список, собранный руками.
    if "bulak.videos.v1" not in stored or "--videos" in sys.argv:
        stored["bulak.videos.v1"] = json.dumps(
            videos_for(collections), ensure_ascii=False
        )

    xml = "\n".join(
        [
            "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>",
            "<map>",
            *[
                f'    <string name="flutter.{name}">{escape(value)}</string>'
                for name, value in stored.items()
            ],
            "</map>",
            "",
        ]
    )

    local = Path(__file__).parent / "_prefs_demo.xml"
    local.write_text(xml, encoding="utf-8")

    adb("push", str(local), "/data/local/tmp/bulak_prefs.xml")
    owner = adb(
        "shell",
        "stat",
        "-c",
        "%u:%g",
        f"/data/data/{PACKAGE}",
    ).stdout.strip()

    # На чистой установке каталога может ещё не быть.
    prefs_dir = f"/data/data/{PACKAGE}/shared_prefs"
    adb("shell", "mkdir", "-p", prefs_dir)
    adb("shell", "chown", owner, prefs_dir)
    adb("shell", "chmod", "771", prefs_dir)

    adb("shell", "cp", "/data/local/tmp/bulak_prefs.xml", PREFS)
    adb("shell", "chown", owner, PREFS)
    adb("shell", "chmod", "660", PREFS)
    adb("shell", "restorecon", PREFS)
    adb("shell", "restorecon", "-R", prefs_dir)
    adb("shell", "rm", "-f", f"{PREFS}.bak")
    adb("shell", "rm", "-f", "/data/local/tmp/bulak_prefs.xml")
    local.unlink(missing_ok=True)

    adb("shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")

    print("Готово: коллекции и лимит времени записаны, приложение перезапущено.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
