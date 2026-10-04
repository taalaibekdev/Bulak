# Privacy Policy for the Bulak Application

**Effective date:** January 1, 2025
**Last updated:** October 5, 2026
**Document version:** 1.1

**Permanent location:** https://bulak.tlbk.kg/privacy

---

## 1. About This Document

This Privacy Policy explains how the **Bulak** mobile application (Russian display name «Булак», application identifier `kg.tlbk.bulak`) handles information when you install and use it on an Android or iOS device.

The application is developed and provided by **tlbk.kg** (referred to below as "we", "us", or the "Developer"), registered in the **Kyrgyz Republic**.
<!-- fill in before publication: full legal entity name (LLC / sole proprietor), registered address and registration number -->

Please read this document in full. We have deliberately written it in plain language: the application is made for families, and a parent should be able to understand what happens to data without a legal background.

---

## 2. The Short Version

**The application does not collect your personal data.** Bulak has no user accounts, no sign-up, no Developer-operated servers, no analytics, no advertising SDKs and no trackers. Everything you create in the application — the list of video links, titles, collections, viewing history, settings, the PIN hash and **downloaded video files** — is stored **only in your device's local storage** and is never transmitted anywhere.

**The only network activity** is downloading thumbnail images and video streams from YouTube servers (Google LLC), plus loading the youtube.com page inside the built-in player in fallback mode. If you have downloaded a video, it is played back from device storage without contacting YouTube. This exchange happens directly between your device and Google; the Developer does not participate in it, cannot observe it and does not retain its results.

**The application can also pass a list of links to another person** — through the system "Share" menu, at your choice and only as plain text or a `.bulak` file containing links and captions. Video files are never sent anywhere in the process. See section 5.4 for details.

---

## 3. What Data Is Processed and Where It Is Stored

Every item listed below is created by you or your child directly inside the application and is stored **locally in the application's private storage on the device**.

| Data category | What exactly is stored | Where it is stored | Who can see it |
|---|---|---|---|
| Video list | Links to YouTube videos added by the parent | Locally on the device | Device only |
| Video titles | Custom names typed by the parent | Locally on the device | Device only |
| Collections | Folder names, selected emoji and colours, assignment of videos to collections | Locally on the device | Device only |
| Favourites | "Heart" marks on video cards | Locally on the device | Device only |
| Viewing history | Which videos were opened inside the application and when | Locally on the device | Device only |
| Settings | Daily screen-time limit, interface preferences, selected language, the "Download as soon as added" setting | Locally on the device | Device only |
| Thumbnail cache | Local copies of preview images, so the video grid opens faster and does not re-download the same images | Locally on the device | Device only |
| **Downloaded video files** | **Copies of videos that the parent saved to the device with the download button or the "Download all" feature** | **The application's private directory `Application Support/media` on the device** | **Device only** |
| Parental PIN | **Not the PIN itself**, but an irreversible cryptographic hash of the four-digit PIN | Locally on the device | Device only |

> **About the thumbnail cache.** So that cards do not flicker and do not reload on every visit, the application stores preview images in a local device cache. These are ordinary, publicly available images from `i.ytimg.com`; they contain no information about you and are removed together with the application data when "Reset everything" is used or when the application is uninstalled. Preview images are not video files and do not make offline viewing possible.

> **About downloaded video files.** If the download feature is enabled in your build of the application, the parent can save a video to the device: the application writes YouTube's "muxed" video stream (video and audio in a single file) at the highest quality available — **360p**; YouTube does not serve such streams at higher quality, and that is a limitation of the service itself. The file is stored in the **application's private directory** (`Application Support/media`), which is inaccessible to other applications; it does not appear in the device's shared storage, gallery or Downloads folder, and the application requests no permission to access your files. Downloaded files are not included in Android backups, because the application sets `allowBackup="false"`. Downloaded files are never shared with anyone: not with the Developer, not with Google, not with third parties. For how to delete them, see section 9.2. The download feature can be disabled entirely at build time with the `BULAK_DISABLE_DOWNLOADS=true` flag — in that case the interface contains neither download buttons nor the "Downloads" screen.

> **About download settings.** The application stores only the on/off value of the "Download as soon as added" setting — an ordinary local value that is never transmitted. It contains no information about you and is deleted together with the rest of the application data.

> **About the PIN.** We deliberately do not store the PIN in plain text. Only a hash is kept in device memory — a value from which the original four digits cannot be recovered. The PIN is never sent to the Developer's servers, to Google, or to anyone else. If the PIN is forgotten, it cannot be recovered; the only option is to reset the application data and configure the application again.

None of this data leaves the device. We cannot read it, because we have no access to it: the application does not send it to any server.

---

## 4. What We Do NOT Collect

To leave no room for ambiguity, here is an explicit list. The application **does not collect, request, transmit or store on its servers**:

- first name, last name, date of birth, gender;
- email address or phone number;
- postal address, country or city of residence;
- location data (precise or approximate);
- contacts from the device's address book;
- photos, videos or files from the device;
- microphone or camera data;
- voice data or biometrics;
- advertising identifiers (AAID, IDFA), device identifiers or any other persistent identifiers;
- information about other applications installed on the device;
- browsing or search history outside the application;
- usage statistics, events, screen recordings or crash reports containing personal data;
- payment or banking details (the application contains no purchases or subscriptions);
- medical data or any health-related information.

The application contains no:

- account registration or sign-in;
- third-party analytics (Google Analytics, Firebase Analytics, AppsFlyer, Amplitude or similar);
- advertising networks or monetisation SDKs;
- trackers, pixels or attribution systems;
- chat, comments, forums or any user-to-user communication features;
- A/B testing or remote configuration tooling;
- push notifications from the Developer.

> **About files on the device.** The application **does not read** your gallery, your documents or other files on the device, and does not request access to them. Downloaded video files are files that the application **creates itself** inside its own private area; they are not your personal files, they never leave the application, and other applications cannot see them.

---

## 5. Network Activity and Third Parties

### 5.1. YouTube (Google LLC)

The application works with YouTube video content, and without contacting Google's servers some features cannot function. Such requests include:

1. **Thumbnail loading.** To display a card with a large preview image, the application requests the preview image from the `i.ytimg.com` server.
2. **Direct video stream loading.** During playback the application requests the video stream from YouTube servers (including `googlevideo.com`) in order to show the video inside our own player, without YouTube's interface or advertising. If the video has been **downloaded to the device**, playback uses the local file and no request is made to YouTube for the video stream; the thumbnail is still loaded from `i.ytimg.com`.
3. **Fallback mode — the embedded YouTube player.** If the direct video stream is unavailable (for example, the creator disabled embedding or changed access settings), the application opens the official embedded YouTube player by loading a page from the `youtube-nocookie.com` domain — YouTube's **privacy-enhanced mode**, in which YouTube does not set its cookies before playback begins. In this mode the video is played by Google's official player.
4. **Domain restrictions.** The embedded player is configured to allow navigation only to YouTube and Google domains (`youtube-nocookie.com`, `youtube.com`, `ytimg.com`, `googlevideo.com`). Navigating to an arbitrary third-party site from inside the player is impossible: the application provides no free browsing.

On each such request, Google receives the technical information that any program transmits when contacting a website — in particular the device IP address, operating system type and version, client type and the time of the request. **The Developer does not receive, store or process this data.** This interaction occurs directly between your device and Google LLC and is governed by Google's policies:

- Google Privacy Policy: https://policies.google.com/privacy
- YouTube Terms of Service: https://www.youtube.com/t/terms
- YouTube family safety resources: https://support.google.com/youtube/answer/9528076

> **Advertising.** We do not display our own advertising and we do not include any advertising SDKs in the application. However, the **fallback embedded YouTube player** may display advertising served by YouTube itself — that is Google's advertising, not ours, and we do not control whether it appears. When playback uses the direct link, YouTube's interface and advertising are not displayed.

> **Trademarks.** YouTube is a trademark of Google LLC. The Bulak application is not affiliated with, sponsored by, endorsed by or otherwise associated with Google LLC. We use the name YouTube solely to describe honestly where the application obtains its video content.

### 5.2. Other Third Parties

There are no other third parties. The application does not share data with payment processors, advertising networks, mailing providers, cloud storage providers or analytics vendors, because none of these components are present in the application.

The only exception arises **through your own deliberate choice**: if you use the "Share" feature (section 5.4), the application you pick — a messenger, an email client, a cloud note or any other recipient — will receive the text you decided to send. That is your own action on your own device, and the Developer takes no part in it.

### 5.3. Cross-Border Transfers

The Developer does not transfer data outside the Kyrgyz Republic, because the Developer does not receive any data from the application at all. The technical requests to YouTube servers described in section 5.1 may be processed on Google servers in various countries; that processing is governed by Google's privacy policy, not by this Policy.

### 5.4. Sharing Collections: What Exactly Is Transferred

The application includes a collection-sharing feature. A parent can send another person a list of video links, and the recipient can paste that list into their own application, after which the videos are added to their library (and, optionally, downloaded immediately if the download feature is enabled in their build).

What you need to understand about this feature:

| Question | Answer |
|---|---|
| What is transferred | **Only the list of video links and their captions** — plain text or a file with the `.bulak` extension |
| What is not transferred | **The video files themselves.** Neither downloaded nor streamed videos are ever sent, in whole or in part. Viewing history, favourites, collections, settings and the PIN hash are not transferred either |
| Where it goes | Wherever you choose: the application opens the system "Share" menu and you pick a messenger, email, notes or another method of sending |
| Is the Developer involved | **No.** The transfer goes directly from your device through the application you selected. The Developer does not receive a copy of the list, does not see whom you sent anything to, and cannot cancel or alter the transfer |
| Does the application have its own server or cloud | **No.** No servers, no accounts, no synchronisation: sharing is possible only through external applications that you choose yourself |
| Who is responsible for the list you send | You. The application merely composes the text with links; the decision about whom to send it to and why is yours |
| Can you opt out | Yes. The feature is optional: if you do not use it, nothing is ever sent |

The recipient adds the links to their own application themselves — that is their action on their device. The Developer is not a party to such an exchange and does not act as an intermediary in it.

---

## 6. Application Permissions

The application requests the smallest possible set of permissions.

| Platform | Permission | Why it is needed | What happens if you decline |
|---|---|---|---|
| Android | `INTERNET` | Downloading thumbnails and the video stream from YouTube servers; loading the embedded player page | Video and thumbnails will not load; the rest of the interface remains usable |
| Android | `WAKE_LOCK` | Preventing the screen from sleeping while a child is watching a video | The screen may sleep on the system timeout during playback |
| iOS | Network access (default) | The same as `INTERNET` on Android | Video and thumbnails will not load |
| iOS | No separate permission required | Keeping the screen awake uses the system `isIdleTimerDisabled` mechanism, which grants no access to personal data | — |

These are the only permissions the application requests on Android. `INTERNET` and `WAKE_LOCK` are declared by the video-playback libraries rather than by the application's own code; `WAKE_LOCK` grants no access to any data and only controls the screen timeout during playback.

**Downloading videos requires no additional permissions.** The application writes downloaded files to its own private directory rather than to shared device storage, so it requests no storage permissions (`READ_MEDIA_VIDEO`, `WRITE_EXTERNAL_STORAGE`, gallery access) on either Android or iOS. That is precisely why downloaded videos are invisible to other applications and never appear in your gallery.

The application **does not request** access to the camera, microphone, location, contacts, calendar, photo library, Bluetooth, notifications or the advertising identifier. On iOS the application does not display an App Tracking Transparency (ATT) prompt, because no tracking takes place.

---

## 7. Children and Privacy

### 7.1. Why the Application Is Safe for Children

The application is designed for children aged 3 to 10, which places heightened obligations on us. We chose an architecture in which privacy is guaranteed by how the application is built rather than by promises:

- the application has no ability to send a child's data anywhere, because it contains no code that does so;
- all content available to the child has been selected in advance, manually, by the parent;
- the application has no search, no recommendations, no infinite feed, no Shorts, no comments, no subscriptions and no channels — a child cannot drift into an uncontrolled stream of content;
- the application contains no Developer advertising and no advertising SDKs that could profile a child;
- the application contains no chats or any form of communication with other people;
- access to the external internet (opening the youtube.com page in the embedded player and adding links) is protected by the parental PIN;
- downloading videos and sharing collections are available only in parental mode, behind the PIN: a child can neither save a video to the device nor send a list of links to anyone;
- downloaded video files live in the application's private area, inaccessible to other applications, and are not shown in the device gallery.

### 7.2. COPPA Compliance (United States)

We do not collect personal information from children under 13 within the meaning of the United States Children's Online Privacy Protection Act (COPPA, 15 U.S.C. § 6501–6506 and the rules at 16 CFR Part 312). Because the application collects no personal information from children or from adults, parental consent for a collection that does not occur is not required. If you believe that a child's personal data has nevertheless reached us, please write to support@tlbk.kg — we will review the request and, if such data is genuinely found, delete it.

### 7.3. GDPR and GDPR-K Compliance (European Union)

Under the General Data Protection Regulation (Regulation (EU) 2016/679, GDPR), the Developer is not a controller of the personal data processed in the application, because no such processing takes place: the data never leaves the user's device and the Developer has no access to it. We do not carry out processing based on a child's consent (Article 8 GDPR), and we do not perform profiling or automated decision-making (Article 22 GDPR). Data-subject rights (access, rectification, erasure, portability, restriction of processing, objection) are exercised by the user directly and entirely locally — see section 9.

### 7.4. Compliance with the Law of the Kyrgyz Republic on Personal Data

The application and the Developer comply with the Law of the Kyrgyz Republic "On Personal Data". Because the application does not collect or process personal data on the Developer's side and does not transfer it to third parties, no data-controller obligations arise for the Developer with respect to such data. Local storage of information on the user's device, accessible only to that user, does not constitute a transfer of data to the Developer.

### 7.5. The Parent's Role

The parent (or other legal guardian) installs the application, configures the parental PIN and decides which videos are available to the child. The parent is also responsible for which video links are added to the application, for which videos are downloaded to the device, and for whom the list of links is sent to via the "Share" feature. Responsibility for video content and for the lawfulness of saving it is also set out in the Terms of Use.

---

## 8. Compliance with the Designed for Families Programme (Google Play)

The application is submitted to Google Play as a child-directed app under the **Designed for Families** programme and the **Families / Child-Directed Apps** policy. Below is a direct mapping to the programme's requirements.

| Google Play requirement | How Bulak satisfies it |
|---|---|
| Collect the minimum data needed to operate | No personal data is collected at all; the application is fully local |
| Do not share children's personal data with third parties | No sharing occurs; the only network requests are thumbnail and video-stream downloads from YouTube, without user identifiers |
| Do not use advertising SDKs directed at children | Advertising SDKs are entirely absent; no first-party advertising is shown |
| Do not use third-party analytics to profile children | Analytics SDKs are entirely absent |
| Provide an accurate Data safety declaration | Completed as "no data collected" and "no data shared" — see `docs/store/google-play/data-safety.md` |
| Provide an accurate age rating | The IARC questionnaire is completed; the application contains no content that would raise the rating |
| Restrict external links and purchases behind parental control | Every action leading to the external internet, to settings, to downloading a video or to sharing a collection is protected by the parent's four-digit PIN |
| Ensure all content matches the declared age group | Content is not supplied by the application: the parent selects it manually |
| Publish a current privacy policy | The policy is published at https://bulak.tlbk.kg/privacy and includes a section on children |
| Do not use content that infringes copyright | The application distributes no copies of videos: playback uses official YouTube mechanisms, and downloaded files remain in the private area of the user's device and are never shared |

The application also complies with Google Play's policy on YouTube content: videos are played through official YouTube mechanisms, no copies are shared or distributed, and responsibility for selecting links and for downloaded files rests with the parent. If the download feature is enabled in a build of the application, this Policy describes it openly and does not conceal it from the user — see sections 3, 5.4 and 9.2.

---

## 9. How to Delete All Data

Data deletion is an entirely local operation that you perform yourself. We cannot delete your data for you, because we do not have it.

### 9.1. Resetting All Data Inside the Application

1. Open the Bulak application.
2. Enter the parental mode by typing your four-digit PIN.
3. Open the parental settings section.
4. Tap the **"Reset everything"** ("Сбросить всё") button.
5. Confirm the action.

The following will then be permanently deleted: the list of video links, custom titles, collections, favourites, viewing history, daily-limit settings, the "Download as soon as added" setting, **all downloaded video files** and the PIN hash. The application returns to the state it was in immediately after installation.

### 9.2. Deleting Downloaded Videos

Downloaded video files are the only application data that takes up noticeable space on the device, so they can be deleted selectively without affecting anything else.

| What you need | How to do it |
|---|---|
| Delete one downloaded video | Parental mode → **"My videos"** → the delete button on the video you want (removes the downloaded file and/or its entry). The video stays in the library but will be streamed from the network |
| Delete all downloaded videos at once | Parental mode → the **"Downloads"** screen → the **"Delete all downloads"** button |
| Delete everything, including downloads | Parental mode → settings → **"Reset everything"** (see section 9.1) |
| Delete everything along with the application | Uninstall the application from the device (see section 9.3): the application's private directory with the downloaded files is removed with it |

The files are deleted from the application's private directory on the device and cannot be restored: we hold no copies of them, because they never left your device. A deleted video can only be recovered by downloading it again, if it is still available on YouTube.

### 9.3. Deleting the Application

Removing the application from the device also removes all local data associated with it:

- **Android:** Settings → Apps → Bulak → Uninstall, or long-press the icon → Uninstall.
- **iOS:** long-press the icon → Remove App → Delete App, or Settings → General → iPhone Storage → Bulak → Delete App.

### 9.4. Data That Cannot Be Deleted Because It Does Not Exist

The Developer holds no backups, no archives, no user database, no accounts and no "cloud profile". There is nothing on our side to delete. **Downloaded video files are likewise absent from any Developer backup**: we do not hold them in any form.

### 9.5. Deletion Requests by Email

If you would like written confirmation that the Developer holds no data about you, or if you have a question about deletion, write to support@tlbk.kg with the subject "Data deletion". We will respond within 30 calendar days. Please note that we cannot "delete" data we have no access to, but we will confirm this in writing.

---

## 10. Data Retention Periods

| Data | Retention period | Who deletes it |
|---|---|---|
| Link list, titles, collections, favourites | Until the user deletes them manually, performs "Reset everything", or uninstalls the application | The user |
| Viewing history | Same as above | The user |
| Settings, daily limit, the "Download as soon as added" setting | Same as above | The user |
| **Downloaded video files** | **Until the user deletes them (the delete button on a video, "Delete all downloads", "Reset everything") or until the application is uninstalled; they are not included in Android backups** | **The user** |
| A list of links composed for sending via "Share" | Exists only at the moment of transfer and is not stored by the application as a separate record; the recipient controls the text they receive | The user and the recipient |
| PIN hash | Same as above | The user |
| Data held by the Developer | **Not retained** | — |
| Data held by Google (technical request logs for YouTube) | Determined by Google LLC's privacy policy | Google LLC |

We do not set our own retention periods, because we do not retain anything. Data exists for exactly as long as you choose to keep it.

---

## 11. Security

Because all data remains on the device, its security depends primarily on how well the device itself is protected. Nevertheless, we apply the following measures:

- **PIN hashing.** The PIN is never stored in plain text; only an irreversible hash is saved.
- **Storage isolation.** Data is written to the application's private storage area and, under normal operating-system behaviour, is inaccessible to other applications. This also applies to downloaded video files: they sit in the `Application Support/media` directory inside the application's area, never appear in shared storage or the device gallery, and are excluded from Android backups because the application sets `allowBackup="false"`.
- **No external attack surface.** The application has no server component, no accounts, no externally loaded scripts and no third-party SDKs through which data commonly leaks.
- **Transport encryption.** All requests to YouTube servers use HTTPS; the application does not disable App Transport Security on iOS and does not permit cleartext traffic on Android.
- **Limited functionality on the open internet.** External links and settings are protected by the parental PIN, which prevents a child from accidentally leaving the curated content. Downloading videos and sharing collections are likewise behind the PIN and available only to an adult.
- **Control over sharing the link list.** The "Share" feature transfers text with links only and has no access to downloaded files — sending a video file through the application is technically impossible.

We recommend that parents secure the device lock screen (PIN, pattern or biometrics) and do not share the application's parental PIN with the child.

---

## 12. Parental Rights

As a parent or legal guardian you have the right to:

1. **Know what data is processed.** The answer is in section 3: only local data that you created; no personal data is collected.
2. **Inspect the contents of the application.** All data is visible to you inside the application in parental mode.
3. **Correct or delete any data.** You can rename or delete any video, clear the viewing history, change collections and settings, and delete any downloaded video or all downloaded files at once — see section 9.2.
4. **Decide what is shared and with whom.** The "Share" feature works only on your direct action and transfers the list of links and nothing else; you can stop using it at any time.
5. **Delete all data completely** — see section 9.
6. **Stop using the application** at any time, simply by uninstalling it.
7. **Obtain an explanation** on any privacy-related matter by writing to support@tlbk.kg.
8. **Not provide data we do not request.** We do not ask you for an email address, a phone number or any information about your child.

---

## 13. Tracking and Profiling

The application does not track users and does not perform profiling.

- **App Tracking Transparency (iOS):** not used. The application does not request tracking permission, because it does not track the user and does not access the IDFA advertising identifier.
- **Android Advertising ID (AAID):** not requested and not used.
- **Cross-app and cross-site tracking:** none.
- **Behavioural profiling:** none. Viewing history is used solely to display that history to you inside the application and never leaves the device.
- **Disclosure to data brokers:** none.

---

## 14. Changes to This Policy

We may update this Policy — for example, if we add a new feature or if legal requirements change. When we make changes we will:

1. update the "last updated" date at the top of the document;
2. increment the document version number;
3. publish the new edition at https://bulak.tlbk.kg/privacy;
4. if a change materially affects data processing, additionally describe it in the application's release notes in Google Play and the App Store.

By continuing to use the application after a new edition is published, you confirm that you have reviewed it. Previous editions are available on request at support@tlbk.kg.

---

## 15. Contact

For any questions regarding this Privacy Policy, data processing, use of the application by children, or the exercise of your rights:

| Channel | Details |
|---|---|
| Support email | support@tlbk.kg |
| Application website | https://bulak.tlbk.kg |
| Policy page | https://bulak.tlbk.kg/privacy |
| Developer | tlbk.kg, Kyrgyz Republic |
| Legal name and address | <!-- fill in before publication: full entity or sole-proprietor name, registered address, registration number --> |

Our response time to any request is no more than 30 calendar days from receipt.

---

## 16. Consent

By installing and using the Bulak application you confirm that you:

- have read and understood this Privacy Policy;
- are the parent or legal guardian of the child who will use the application, or are using the application for your own purposes;
- understand that no personal data is collected in the application and that all data you create is stored locally on your device;
- understand that downloaded video files (if the download feature is enabled in your build) are stored in the application's private area on your device, are never shared with anyone and are deleted by you;
- understand that the "Share" feature sends another person only a list of links and captions, only at your choice, and that video files are not transferred in the process;
- understand that video playback is impossible without requests to YouTube servers (Google LLC) and is additionally governed by Google's policies.

*The Bulak application is not affiliated with, sponsored by or endorsed by Google LLC. YouTube is a trademark of Google LLC.*
