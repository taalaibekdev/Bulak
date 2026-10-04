# App Store screenshots — locale `en-US`

Put the finished screenshots for the English (en-US) App Store localisation in this folder.
You can upload them by hand via **App Store Connect → Screenshots**, or automatically with
`fastlane deliver` (it reads `fastlane/screenshots/<locale>/`).

## Required sizes

Apple changes the list of mandatory sizes, so **always check App Store Connect → Screenshots
before uploading**.

| Device | Size | Requirement |
|---|---|---|
| iPhone 6.9" (iPhone 16 Pro Max and similar) | **1320 × 2868** | Required |
| iPhone 6.7" (iPhone 15 Pro Max and similar) | **1290 × 2796** | Often required |
| iPhone 6.5" (iPhone 11 Pro Max and similar) | 1242 × 2688 or 1284 × 2778 | Optional if 6.9" is covered |
| iPhone 5.5" (iPhone 8 Plus) | 1242 × 2208 | Optional |
| iPad 13" | **2064 × 2752** | Required if the app supports iPad |
| iPad 12.9" (generations 3–6) | 2048 × 2732 | Often required |
| iPad 11" | 1668 × 2388 | Optional |

**Practical takeaway:** prepare one iPhone set at **1320 × 2868** (6.9") and one at
**1290 × 2796** (6.7"). For iPad use **2064 × 2752**.

## General file requirements

| Parameter | Value |
|---|---|
| Format | PNG (preferred) or JPEG |
| Colour space | sRGB |
| Orientation | Portrait for iPhone; portrait and landscape are allowed for iPad |
| File size | up to 8 MB per screenshot |
| Count | 1 to 10 per screen size |
| Device frames | Do not add |

## Captions (EN)

| # | Screen | Headline |
|---|---|---|
| 1 | Home grid | `Only the videos you chose` |
| 2 | Collections | `Cartoons, learning, music — in folders` |
| 3 | Kid-friendly player | `Big buttons for little fingers` |
| 4 | "That's all for today" | `A daily screen-time limit` |
| 5 | PIN entry | `Parent mode, protected by a PIN` |
| 6 | Adding a video | `Add a video by link in 10 seconds` |
| 7 | Favourites | `Favourites, always at hand` |
| 8 | Viewing history | `See what your child watched` |

Headlines use **Nunito ExtraBold** (Comfortaa Bold is allowed for the name "Bulak"), at least
72 px on a 1080 px wide canvas. The YouTube/Google logos, real faces of children, personal data
and "working" buttons drawn on top of a frame are all forbidden.

Source: `docs/store/screenshots-plan.md`, sections 2.2, 2.3, 3, 4, 5.
