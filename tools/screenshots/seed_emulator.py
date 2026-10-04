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

import json
import re
import subprocess
import sys
from pathlib import Path
from xml.sax.saxutils import escape

for stream in (sys.stdout, sys.stderr):
    if hasattr(stream, "reconfigure"):
        stream.reconfigure(encoding="utf-8", errors="replace")

PACKAGE = "kg.tlbk.bulak"
PREFS = f"/data/data/{PACKAGE}/shared_prefs/FlutterSharedPreferences.xml"
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

    # --locale en переключает интерфейс на английский — для английского
    # листинга нужны снимки именно на том языке, который увидит пользователь.
    locale = "en" if "--locale" in sys.argv and "en" in sys.argv else None

    adb("root")
    adb("shell", "am", "force-stop", PACKAGE)

    raw = adb("shell", "cat", PREFS, check=False).stdout
    if "<map>" not in raw:
        print("Не удалось прочитать настройки приложения. Запустите его один раз.")
        return 1

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

    stored["bulak.settings.v1"] = json.dumps(settings, ensure_ascii=False)
    stored["bulak.collections.v1"] = json.dumps(
        collections_for(locale or settings.get("localeCode") or "ru"),
        ensure_ascii=False,
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
    adb("shell", "cp", "/data/local/tmp/bulak_prefs.xml", PREFS)
    owner = adb(
        "shell",
        "stat",
        "-c",
        "%u:%g",
        f"/data/data/{PACKAGE}",
    ).stdout.strip()
    adb("shell", "chown", owner, PREFS)
    adb("shell", "chmod", "660", PREFS)
    adb("shell", "restorecon", PREFS)
    adb("shell", "rm", "-f", f"{PREFS}.bak")
    adb("shell", "rm", "-f", "/data/local/tmp/bulak_prefs.xml")
    local.unlink(missing_ok=True)

    adb("shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")

    print("Готово: коллекции и лимит времени записаны, приложение перезапущено.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
