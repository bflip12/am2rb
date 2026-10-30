# Changelog

All notable changes to am2rb are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

The first public release will be 0.1.0.

### Added

- A native SwiftUI app that reads Apple Music playlists, including cloud-only ones, through `iTunesLibrary`.
- Metadata matching against a local DJ folder, scored on title, artist, version and track length.
- A review list with a "Needs attention" filter, alternative candidates, DJ folder search and skip.
- Duplicate detection for the same recording stored more than once in the DJ folder.
- `.m3u8` export with absolute paths, ready for Rekordbox's Import Playlist.
- A fallback for Apple Music's Unicode Text playlist export (⌘O).
- A tag cache, so only new or changed files are read after the first scan.
- An app icon and logo mark, drawn by `scripts/make-icon.sh`.

[Unreleased]: https://github.com/bflip12/am2rb/commits/main
