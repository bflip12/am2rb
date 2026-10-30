# CrateMate: brand brief

This is the handoff for whoever designs the v1 brand. It covers what the app is, the chosen direction, what was rejected and why, and what's needed. The reference sketch is [sketches/riso-moire-sketch.svg](sketches/riso-moire-sketch.svg).

## The app

A small, free, open-source Mac app for DJs who find music in Apple Music and play from Rekordbox. It reads your Apple Music playlists, finds each song among the audio files in your DJ folder by artist, title, version and length, and writes a playlist file that Rekordbox imports. The imported tracks link to files already in your Rekordbox collection, so your cue points and beatgrids are kept.

What matters to the people who use it:

- **It finds your copy.** Not Apple's file, the one you prepared for your sets.
- **It picks the right cut.** It tells an Extended Mix from an Original Mix or a Radio Edit by track length.
- **It shows its work.** Every song is marked matched, worth a check, or not found, and you can fix any of them before exporting.
- **It never touches your files.** It only reads your DJ folder.

The audience is working and bedroom DJs: people who care about records and their own collection, and who are wary of anything that looks like a generic productivity tool.

**How it should feel: an organisation tool for a record collection.** It sorts and files; it doesn't make music. Avoid anything that reads as a music-making or music-streaming app (waveforms, knobs, faders, equaliser bars, play buttons).

The repo is still called `am2rb` (Apple Music to Rekordbox). The rename happens once the brand is settled.

## Name

**CrateMate**, one word. A crate is where a DJ keeps a set; the mate is the friend who packs it for you.

- The wordmark is set in lowercase, `cratemate`, with "mate" picked out in a second colour. In running text and the app's menu bar, write CrateMate.
- The app bundle will be `CrateMate.app`.
- A quick search found no app with this name. There's a Melbourne DJ collective called Crate Mates. A proper trademark search is still to do.

## Chosen direction: Riso moiré in forest and yellow, with Geist

### The mark

Two sets of concentric rings, offset side by side and printed in two inks that overlap, like a two-colour risograph print. Where they cross, the inks mix and a moiré appears. One set is your Apple Music copy and the other is your DJ copy, finding each other. Read it as two things being lined up and matched, not as a record or a speaker.

Geometry in the sketch, on a 100 × 100 grid: five rings per set with radii 5, 10.5, 16, 21.5 and 27 and a stroke of 2.4. The left set is centred at (42, 50) and the right at (58, 50), and each set is clipped to a circle of radius 31. The second ink is nudged by (0.5, −0.4) to look slightly misregistered. A light paper grain sits over everything. Keep the print feel: the overlap must look like ink mixing (multiply), not like transparency.

### Palette

| Name | Hex | Use |
|---|---|---|
| Paper | `#F2ECDC` | Icon ground, light backgrounds |
| Forest | `#2F5A49` | First ink; "mate" on light backgrounds |
| Yellow | `#F5D000` | Second ink; "mate" on dark backgrounds |
| Deep forest | `#1E3A2F` | Wordmark text on light; dark backgrounds |

Yellow is never text on paper; it doesn't have the contrast. On light grounds the wordmark is deep forest with "mate" in forest; on dark grounds it's paper with "mate" in yellow.

### Typeface

**Geist** (SemiBold, 600), lowercase, tracked tight (about −0.05 em at display size). Open licence (OFL), so it can be used in the logo. It's precise and plain, which keeps the brand on the "tool" side; the icon's print texture provides the warmth. Convert the wordmark to outlines for the final files and tune the spacing between "crate" and "mate" by eye, since there's no space between them.

Use Geist only in the logo and brand assets (README header, social preview, later a website). Inside the app, keep the system font.

### Voice

Plain and warm, a little bit of record-shop talk, never cute. Sample status line: "23 of 25 in the crate. 2 still out there."

### To solve

- **Small sizes.** The moiré turns to mush at 32 and 16 points. Draw small-size versions with fewer, thicker rings (three per set at 32, two at 16 is a starting point), and check them on light and dark Finder windows.
- **In-app accent colour.** Both brand colours clash with the app's status colours: forest is close to green (matched) and yellow is close to orange (worth a check). Recommendation: don't tint the app with a brand colour at all, and let it follow the user's system accent colour, like most Mac apps. The brand then shows in the icon and the first-run screen. If an accent is wanted anyway, it needs a deliberate value that can't be mistaken for a status colour, with light-mode and dark-mode versions.

## What we've tried and rejected

Don't drift back toward these.

1. **"Matchcut", a violet record split diagonally into a flat half and a grooved half on near-black.** Too serious and "new-age techy", like a developer tool. The name didn't say what the app does either.
2. **Crate Mate as a cartoon:** a smiling red milk crate full of records on sunny yellow, in a chunky rounded font. The name worked, but the look was too childish.
3. **Other lighter names with cartoon looks:** "fetchlist", "tote" and "Porter". Same problem: too cute.
4. **Literal vinyl looks** (an obi-strip sleeve, a rubber-stamped white label, record labels and grooves). Too "music app", as if you make music with it. The obi one was also too Japanese-forward.
5. **Round, soft fonts** like Fraunces with its "soft" setting. Too bubbly.
6. **Other colourways for the moiré** (oxblood and mustard, navy and fluoro pink, teal and orange, black and red, blue and coral) and other typefaces (Gloock, Instrument Serif, Schibsted Grotesk, Archivo condensed capitals, DM Mono). Considered and passed over for forest and yellow with Geist.

The runner-up was **Spines**: a row of record spines with one spine pulled up as the match. Its "filed and sorted" feeling is the right spirit; borrow from it if the moiré needs help reading as organisation.

Overall direction: **an organisation tool with an analog, printed feel. Not childish, not techy, not a music-making app.**

## What v1 needs

| Asset | Notes |
|---|---|
| App icon | The macOS icon grid: 1024 × 1024 canvas, 824 × 824 body inset 100 on each side, continuous corners with a radius of about 185. Every size of a `.iconset` (16, 32, 128, 256 and 512, each at 1× and 2×), with hand-tuned versions at 64 and below. It has to read on light and dark Finder windows. |
| Logo mark | The two-ink rings without the rounded square, as SVG, with versions for light and dark backgrounds. |
| Wordmark and lockups | `cratemate` in Geist, converted to outlines, in SVG. Horizontal (mark plus wordmark) and stacked, each for light and dark backgrounds. |
| Palette tokens | The four brand colours above, and the in-app accent decision. |
| README header | The icon or lockup above the title on GitHub. It must work in GitHub's light and dark themes. |
| GitHub social preview | 1280 × 640 PNG: mark, wordmark and the one-line description. |
| First-run screen | The app shows its icon at about 96 pt on the "Choose your DJ folder" screen. Nothing else is needed for this; it uses the icon. |

Later, not v1: a DMG background and website, once there's a signed download.

## Constraints

- **It's a native Mac app, and it should look like one.** The UI uses system controls, the system font and SF Symbols. The brand shows in the icon, the first-run screen and the docs, not in custom chrome or custom fonts inside the app.
- **Icon toolchain:** the project builds with the Xcode Command Line Tools only, so there's no Xcode, asset catalog or Icon Composer. The icon ships as a `.icns` made with `iconutil`. Today it's drawn in code by `scripts/make-icon.swift` (Core Graphics), which `scripts/make-icon.sh` turns into `Resources/AppIcon.icns` and `docs/assets/icon.png`. That script can be rewritten for the new icon, or replaced by committed PNGs.
- **Trademarks:** don't use Apple's or rekordbox's logos, names or colours (Apple Music's red and pink) in the brand.
- **No third-party assets** that need a paid licence or attribution in the app.

## Where the files go

- `Resources/AppIcon.icns` is the app icon. The build script picks it up automatically.
- `docs/assets/icon.png` (512 px) is used by the README.
- `docs/brand/` holds the marks, wordmark, lockups and this brief.
- `docs/assets/social.png` is the GitHub social preview.

The `feature/brand` branch has a first pass at the icon in this direction, drawn by `scripts/make-icon.swift` with fewer, thicker rings at 64 px and below, and matching `mark-on-light.svg` and `mark-on-dark.svg`. The app has no brand accent; it follows the system accent colour. Refine or replace any of it; the wordmark, lockups and social preview are still to do.
