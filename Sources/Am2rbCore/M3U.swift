// Writing the playlist Rekordbox imports: absolute paths to the library files.

import Foundation

/// The extended M3U text for `tracks`: a `#EXTINF` line, then the absolute path, per track.
public func m3uText(_ tracks: [LibraryTrack]) -> String {
    var lines = ["#EXTM3U"]
    for t in tracks {
        lines.append("#EXTINF:\(t.duration.map { String(Int($0)) } ?? "-1"),\(t.label)")
        lines.append(t.file)
    }
    return lines.joined(separator: "\n") + "\n"
}

/// Writes "<playlist name>.m3u8" into `dir` and returns its URL.
///
/// `/` and `:` in the name become `-`. An existing file with the same name is replaced.
public func writeM3U(name: String, tracks: [LibraryTrack], to dir: URL) throws -> URL {
    let safe = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        .trimmingCharacters(in: .whitespaces)
    let url = dir.appendingPathComponent((safe.isEmpty ? "playlist" : safe) + ".m3u8")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    try m3uText(tracks).write(to: url, atomically: true, encoding: .utf8)
    return url
}
