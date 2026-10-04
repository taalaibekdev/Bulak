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

# Коллекции, которые должны появиться в приложении.
COLLECTIONS = [
    {
        "id": "demo-toons",
        "title": "Мультики",
        "emoji": "🧸",
        "colorIndex": 0,
        "sortOrder": 0,
        "createdAt": "2026-09-20T10:00:00.000",
    },
    {
        "id": "demo-music",
        "title": "Музыка",
        "emoji": "🎵",
        "colorIndex": 1,
        "sortOrder": 1,
        "createdAt": "2026-09-21T10:00:00.000",
    },
    {
        "id": "demo-favourite",
        "title": "Любимое",
        "emoji": "⭐",
        "colorIndex": 4,
        "sortOrder": 2,
        "createdAt": "2026-09-22T10:00:00.000",
    },
]

# Настройки: дневной лимит, чтобы на главной был виден баннер с остатком.
SETTINGS_EXTRA = {
    "dailyLimitMinutes": 30,
    "watchedSecondsToday": 420,
}


def adb(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        [ADB, *args],
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

    adb("root")
    adb("shell", "am", "force-stop", PACKAGE)

    raw = adb("shell", "cat", PREFS, check=False).stdout
    if "<map>" not in raw:
        print("Не удалось прочитать настройки приложения. Запустите его один раз.")
        return 1

    # Достаём текущие настройки, чтобы не потерять PIN-код родителя.
    start = raw.find(">", raw.find("bulak.settings.v1")) + 1
    end = raw.find("</string>", start)
    settings = json.loads(
        raw[start:end]
        .replace("&quot;", '"')
        .replace("&amp;", "&")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&apos;", "'")
    )
    settings.update(SETTINGS_EXTRA)
    settings["onboardingCompleted"] = not reset_onboarding

    def entry(name: str, value: str) -> str:
        return f'    <string name="flutter.{name}">{escape(value)}</string>'

    xml = "\n".join(
        [
            "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>",
            "<map>",
            entry("bulak.settings.v1", json.dumps(settings, ensure_ascii=False)),
            entry(
                "bulak.collections.v1",
                json.dumps(COLLECTIONS, ensure_ascii=False),
            ),
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
