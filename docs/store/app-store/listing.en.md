# App Store — Listing for Bulak (EN)

Ready-to-paste App Store Connect fields. Localisation: **English (en-US)**. Use alongside `listing.ru.md` (primary localisation).

Apple's limits are strict: name 30 characters, subtitle 30, promotional text 170, description 4000, keywords 100 characters (comma-separated, **no spaces**).

---

## 1. App name

**Limit: 30 characters.** Primary option:

```
Bulak — videos for kids
```

**Length: 23 characters.**

| Option | Text | Length |
|---|---|---|
| A (primary) | `Bulak — videos for kids` | 23 |
| B | `Bulak — safe kids video` | 23 |
| C | `Bulak: Kids Video Player` | 24 |

> The name contains no reference to YouTube: it is a trademark of Google LLC and must not form part of the app's own brand.

---

## 2. Subtitle

**Limit: 30 characters.** Primary option:

```
Calm video, no endless feed
```

**Length: 27 characters.**

| Option | Text | Length |
|---|---|---|
| A (primary) | `Calm video, no endless feed` | 27 |
| B | `Parents choose every video` | 26 |
| C | `Only the videos you picked` | 26 |

---

## 3. Promotional text

**Limit: 170 characters.** Promotional text is not indexed by search but appears at the top of the product page, and it can be updated without review.

```
A parent adds video links. A child watches only those: large cards, a kid-friendly player, a daily time limit. No search, no feed, no Shorts, no comments.
```

**Length: 154 characters.**

Alternative for a future update:

```
Version 1.0: emoji collections, favourites, viewing history and a kind "That's all for today" screen. Everything you add stays on your device.
```

**Length: 142 characters.**

---

## 4. Description

**Limit: 4000 characters.** Paste in full, including the blank lines.

```
Bulak is a player where you, the parent, choose the videos.

No algorithms and no recommendations: only the cartoons, songs and lessons you have added yourself. Your child opens the app and sees large, friendly cards — exactly your videos.

HOW IT WORKS
1. You find a suitable video on YouTube and copy the link.
2. You enter the parental PIN and save the link in the app.
3. Your child opens Bulak and watches only what you selected.

WHAT YOUR CHILD SEES
• Large thumbnails and clear cards
• A full-screen player with big, child-friendly buttons
• Collections with emoji and colour: Cartoons, Learning, Music
• Favourites — a heart on a favourite video
• Viewing history
• A kind "That's all for today" screen when the daily limit runs out
• A parental lock: leaving the player requires the PIN

PARENT-ONLY FEATURES (BEHIND THE PIN)
• Add a video by link
• Rename a video
• Delete a video
• Sort videos into collections
• Set a daily screen-time limit
• Change the PIN
• Reset all data

WHAT THE APP DOES NOT HAVE
• Search
• Recommendations or an infinite feed
• Shorts
• Comments
• Subscriptions and channels
• Chats or any contact with other people
• Our own advertising
• Sign-up or accounts

YOUR DATA STAYS WITH YOU
The app does not collect personal data. The link list, titles, collections, favourites, viewing history and settings are stored only on your device. There are no accounts, no developer servers, no analytics, no trackers and no advertising SDKs. The PIN is stored as an irreversible hash. At any time you can tap "Reset everything" and delete all data.

INTERNET IS REQUIRED
Videos and thumbnails are loaded from YouTube servers, so watching is not possible without a network connection.

FOR PARENTS
Responsibility for which videos are added to the app rests with the parent. The app does not check, assess or filter video content — it shows exactly what you selected. Please review videos before making them available to your child.

WHO IT IS FOR
For children roughly 3 to 10 years old, and for parents who want calm viewing without accidental content.

IMPORTANT INFORMATION ABOUT YOUTUBE
YouTube is a trademark of Google LLC. The Bulak app is not affiliated with Google, is not sponsored by Google and is not endorsed by Google. In this build the app does not download videos and does not store copies of them: playback uses official YouTube mechanisms. We do not show our own advertising and we do not include advertising SDKs in the app; however, the fallback embedded YouTube player may display advertising served by YouTube itself.

Free. No in-app purchases and no subscriptions.

Support: support@tlbk.kg
Website: https://bulak.tlbk.kg
Privacy policy: https://bulak.tlbk.kg/privacy
```

**Actual length: 2 701 characters** — within the 4000-character limit.

---

## 5. Keywords

**Limit: 100 characters.** Comma-separated, **no spaces**. Do not repeat words that already appear in the name or subtitle: Apple indexes those separately, and duplicates waste space.

Primary set:

```
kids,video,player,safe,parental,control,screen,time,limit,cartoon,toddler,child,family
```

| Option | Text | Length |
|---|---|---|
| A (primary) | `kids,video,player,safe,parental,control,screen,time,limit,cartoon,toddler,child,family` | 86 |
| B | `kids,video,player,safe,parental,control,screen,time,limit,cartoons,toddler,child,nursery` | 88 |
| C | `kid,video,safe,parental,control,screen,time,limit,cartoon,toddler,child,family,nursery,pick` | 91 |

Meaning of the primary set: `kids`, `video`, `player` are the core queries; `safe`, `parental`, `control` cover parental-control intent; `screen`, `time`, `limit` cover screen-time intent; `cartoon`, `toddler`, `child`, `family` are qualifying terms.

> Never put third-party trademarks in the keywords field: `youtube`, `youtube kids`, `google` — this is a direct breach of Apple's rules and will almost certainly cause rejection.

---

## 6. URLs

| Field | Value | Required |
|---|---|---|
| Support URL | `https://bulak.tlbk.kg` | **Yes** |
| Marketing URL | `https://bulak.tlbk.kg` | No |
| Privacy Policy URL | `https://bulak.tlbk.kg/privacy` | **Yes** |
| Licence agreement | Apple's standard EULA, or `https://bulak.tlbk.kg/terms` if using a custom one | No |

**Page requirements.** The support URL must open a real page where a parent can find contacts: `support@tlbk.kg` and brief answers to common problems. The privacy policy link must point at the policy page itself, not at the site home page — Apple checks this manually.

| Page | Address | Content |
|---|---|---|
| Home | `https://bulak.tlbk.kg` | App description, screenshots, store links |
| Support | `https://bulak.tlbk.kg/support` | FAQ, support email |
| Privacy policy | `https://bulak.tlbk.kg/privacy` | The ready file `docs/legal/privacy-policy.html` |
| Terms of use | `https://bulak.tlbk.kg/terms` | `docs/legal/terms-of-use.en.md` published as a page |

---

## 7. Categories

| Field | Value |
|---|---|
| Primary Category | **Education** |
| Secondary Category | **Entertainment** |
| Kids Category | **Yes**, age bands **6–8** and **9–11** |

**Why Education:** the app is used to watch developmental, musical and educational material selected by a parent.

**Why 6–8 and 9–11:** the interface targets children who confidently hold a device and can pick cards. The "5 and under" band is not claimed, because pre-schoolers are generally recommended to watch with an adult while this app assumes independent browsing. The app genuinely suits younger children when a parent is involved, and the description says so.

---

## 8. Age rating

Complete in **App Store Connect → Age Rating**.

| Questionnaire section | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Guns or Other Weapons | None |
| Contests | None |
| Unrestricted Web Access | **No** |
| Gambling with Real Currency | No |
| User-Generated Content | No |
| In-App Purchases | No |
| Advertising | No |

**Expected rating: 4+.**

Pay particular attention to **Unrestricted Web Access** — the answer must be **No**. Although the app opens the youtube.com page in the embedded fallback player, access to the open internet is **not unrestricted**: it sits behind the parental PIN, and the page loads only for the specific video a parent selected. Be ready to explain this to the reviewer; see `docs/store/app-store/review-notes.md`.

---

## 9. Advertising, purchases and third-party content

These answers must match the App Privacy section (see `privacy-labels.md`).

| Question | Answer |
|---|---|
| Does the app contain advertising? | **No** first-party advertising. The app contains no advertising SDKs. The fallback embedded YouTube player may display advertising served by YouTube itself |
| In-app purchases? | **No** |
| Subscriptions? | **No** |
| Third-party content? | **Yes** — video is played from YouTube servers (Google LLC). The app stores no copies of videos and is not a distributor of them |
| User-generated content? | **No** — the app is not a publishing platform |
| User-to-user data sharing? | **No** |
| Unrestricted web access? | **No** — external navigation sits behind the parental PIN |
| App Tracking Transparency? | **Not used** — no tracking takes place |
| Kids Category requirements met? | **Yes** — see `privacy-labels.md` and `review-notes.md` |

---

## 10. Other App Store Connect fields

| Field | Value |
|---|---|
| Bundle ID | `kg.tlbk.bulak` |
| Version | 1.0.0 (build 1) |
| Price | Free |
| Availability | Kyrgyzstan, Russia, Kazakhstan and other CIS countries; worldwide once support is ready |
| Listing languages | `en-US` (this file), `ru` (see `listing.ru.md`) |
| Seller Name | `tlbk.kg` <!-- fill in before publication: the seller name shown in the App Store --> |
| Legal entity | <!-- fill in before publication: full entity or sole-proprietor name, registered address --> |
| Country | Kyrgyz Republic |
| Export Compliance | Standard HTTPS encryption only — qualifies for the exemption; see `docs/store/app-store/privacy-labels.md` |
| Content Rights | The app contains no third-party content whose rights are unaddressed: video plays from YouTube servers and no copies are created |
| TestFlight | Review build uses demonstration PIN `0000` — see `review-notes.md` |

---

## 11. Pre-publication checklist

- [ ] Name is 30 characters or fewer and contains no third-party trademarks.
- [ ] Subtitle is 30 characters or fewer.
- [ ] Promotional text is 170 characters or fewer.
- [ ] Description is 4000 characters or fewer, with no "TODO", and includes the YouTube disclaimer.
- [ ] Keywords are 100 characters or fewer, comma-separated with no spaces, and contain no `youtube` or `google`.
- [ ] Support URL opens and shows a support contact.
- [ ] Privacy Policy URL points at the policy page.
- [ ] Categories Education + Entertainment selected.
- [ ] Kids Category selected with age bands 6–8 and 9–11.
- [ ] Age rating questionnaire completed; Unrestricted Web Access answered No.
- [ ] Screenshots prepared for every required size (see `docs/store/screenshots-plan.md`).
- [ ] Every `<!-- fill in before publication -->` placeholder has been replaced.
