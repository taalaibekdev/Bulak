# App icon — Google Play (en-US)

Place **one** file here: `icon.png`

| Parameter | Value |
|---|---|
| Size | **512 × 512 px** (exact) |
| Format | 32-bit **PNG** |
| Alpha channel | **Not allowed** — the icon must be fully opaque |
| File size | up to 1 MB |
| Safe zone | 24 px on every side; keep nothing important inside that margin |
| File name | `icon.png` (fastlane supply uploads it automatically) |

## What to draw

The "spring" concept (`concept_b_spring`) — recommended in `docs/store/google-play/store-assets.md`:
a rounded stone or bowl with a drop rising out of it and a play triangle inside.
Sketches and alternatives: `assets/icon/concepts/`.

## What to avoid

- a red rounded rectangle with a white triangle (the YouTube logo);
- the word "YouTube" or any third-party trademark;
- fine detail that disappears at 48 px;
- photorealistic images of children;
- text on the icon — Play shows it too small to read.

> This is a **separate** 512 × 512 file without an alpha channel. It is not the same file as
> `assets/icon/app_icon.png`, which ships inside the app.

Source: `docs/store/google-play/store-assets.md`, section 3.
