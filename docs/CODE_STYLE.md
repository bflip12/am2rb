# Code style

These are the conventions for am2rb's Swift code. Most of the formatting is automatic. The rest is about keeping the code small, readable and safe for the user's files.

## Formatting

- The code is formatted with **swift-format** using [`.swift-format`](../.swift-format): 4-space indentation and 120-column lines.
- Run `scripts/format.sh` before committing. CI runs `scripts/format.sh --check`, which is `swift format lint --strict`, and fails on any warning.
- Don't hand-align code; the formatter decides line breaks. If its output reads badly, restructure the code (pull out a local, split the expression) rather than fighting it.
- Imports are sorted.

## Structure

- **Logic goes in `Am2rbCore`.** It must not import SwiftUI or AppKit. If something can be unit tested, it belongs here.
- **The app target stays thin.** `AppModel` coordinates, and views display. A view shouldn't make a decision that a test would want to cover.
- **Each file starts with a `//` comment** of one or two lines saying what the file is for and anything non-obvious about it, e.g. "Read-only: files are never moved, renamed or retagged".
- Use `// MARK: - Section` to divide longer files.
- Keep each type in the file named for its job (`Matcher.swift`, `Library.swift`), not one type per file. Small helpers live next to their only caller.

## Naming

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Public API in `Am2rbCore` uses full, descriptive names: `matchThreshold`, `scanLibrary(_:rescan:progress:)`.
- Short names are fine for locals in a tight scope (`p` for a playlist in a closure, `t` for a track, `s` for a score). If the reader would have to scroll to find what a short name means, spell it out.
- Domain terms are used consistently:

  | Term | Meaning |
  |---|---|
  | *source track* | a song as Apple Music knows it (`SourceTrack`) |
  | *library track* | an audio file in the DJ folder (`LibraryTrack`) |
  | *DJ folder* | in UI copy; it's `library` in code |
  | *version tokens* | the remix or edit words from a title (`vtokens`) |
  | *same recording* | two files that are duplicate copies of one track |

## Documentation

- **Every `public` declaration in `Am2rbCore` has a `///` doc comment.** swift-format enforces this (`AllPublicDeclarationsHaveDocumentation`).
- Start with a one-line summary. Add a blank `///` line and more detail only when there's something a caller needs to know: units (seconds, 0–1 scores), what `nil` or an empty string means, and side effects.
- Use DocC symbol links in double backticks, e.g. ``` ``LibraryIndex`` ```.
- Plain comments explain *why*, not what. For example: `// Duration is what tells an Extended Mix from an Original Mix`. If a comment just restates the code, delete it.
- Behaviour changes update [ARCHITECTURE.md](ARCHITECTURE.md) in the same PR.

## Safety rules

These protect the user's DJ library and are checked in review:

- **Never write to the DJ folder.** Open audio files read-only (`.readPermission`, `AVURLAsset`). Don't move, rename or retag anything, and don't put temporary files there.
- **Never make network requests.**
- **Don't add dependencies.** Use Apple frameworks only. If you think a dependency is needed, open an issue first.
- Writes go to only two places: the export folder the user chose, and `~/Library/Application Support/am2rb/`.

## Swift

- **Prefer value types.** Data passed between layers is a `struct` that's `Sendable` and usually `Hashable`. `LibraryIndex` is a `final class` because it's large and immutable after `init`. It's marked `@unchecked Sendable`, and it must stay immutable for that to hold.
- **Concurrency:** UI state is `@MainActor`. Slow work (Apple Music reading, scanning, matching) runs off the main actor in `Task.detached` or an `async` core function, and its result is assigned back on the main actor. Before assigning a result, check it's still current, e.g. `guard self.index === index`.
- **Force unwraps and `try!`** are only for invariants the programmer controls, like compiling a constant regex. Never use them on data that comes from files, tags or Apple Music.
- **Errors:**
  - Core functions throw `LocalizedError`s whose `errorDescription` is ready to show to the user.
  - The app shows the message as is. It doesn't wrap it in "Error:" or add an error code.
  - Failures that aren't the user's concern (an unreadable tag, a corrupt cache) fall back quietly to a sensible default.

## SwiftUI

- **Don't use `@State`.** In the macOS 27 SDK, `@State` is a macro whose compiler plugin ships only with full Xcode, so the build fails with just the Command Line Tools. Put UI state on the `@Observable` models instead (e.g. `RowReview.searching`, `AppModel.playlistFilter`). `@Observable`, `@Bindable` and `@Environment` are all fine.
- Views read the model from the environment: `@Environment(AppModel.self)`. Use `@Bindable var model = model` inside `body` when you need bindings.
- Use system components and SF Symbols, and follow the macOS conventions: toolbar actions, `ContentUnavailableView` for empty states, `.help(…)` tooltips on icon-only buttons.

## UI copy

- Write in plain, friendly sentences.
- Buttons and menu items use title case, as the macOS Human Interface Guidelines do: "Show in Finder", "Choose Folder…". Headings, labels and messages use sentence case: "Needs attention", "Choose your DJ folder".
- Use an ellipsis (…) on a command that opens a dialog. Write menu paths with `›`, e.g. "File › Import › Import Playlist".
- Error messages say what happened, then what to do. For example: "Couldn't read your Apple Music library. Allow am2rb in System Settings › Privacy & Security › Media & Apple Music, or open a playlist exported as Unicode Text."
- Say "DJ folder", not "library", when talking to the user.

## Tests

- Tests use [Swift Testing](https://developer.apple.com/documentation/testing) (`@Test`, `#expect`), not XCTest.
- Name each test after the behaviour it checks: `durationPicksTheRightCut`, `remixVersusPlain`.
- Build fixtures in memory (`LibraryTrack(file: "/lib/…")`) wherever you can. The end-to-end test, with real files from `scripts/make-test-library.sh`, covers tag reading and the whole pipeline.
- Every matcher fix comes with a test using the real-world title that exposed it.
- Run the tests with `scripts/test.sh`, not plain `swift test`; [CONTRIBUTING.md](../CONTRIBUTING.md#running-the-tests) explains why.

## Shell scripts

- Start with `#!/usr/bin/env bash` and `set -euo pipefail`, then `cd "$(dirname "$0")/.."`, so the script works from any directory.
- A header comment says what the script does and how to call it (`# Usage: …`).
- Use 2-space indentation.
