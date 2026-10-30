// Apple Music "Unicode Text" playlist export (File > Library > Export Playlist…).
// UTF-16LE with BOM, tab-separated, CR line endings. Used as a fallback when the
// Apple Music library can't be read, and by the tests.

import Foundation

/// An export file that can't be read, with a message that's shown to the user as is.
public struct ExportError: LocalizedError {
    /// What went wrong and what to do about it.
    public var errorDescription: String?
}

func decodeText(_ data: Data) -> String {
    let b = [UInt8](data.prefix(4))
    if b.starts(with: [0xFF, 0xFE]) { return String(data: data.dropFirst(2), encoding: .utf16LittleEndian) ?? "" }
    if b.starts(with: [0xFE, 0xFF]) { return String(data: data.dropFirst(2), encoding: .utf16BigEndian) ?? "" }
    if b.starts(with: [0xEF, 0xBB, 0xBF]) { return String(data: data.dropFirst(3), encoding: .utf8) ?? "" }
    // No BOM: guess UTF-16LE if every other byte is zero early on
    if b.count == 4 && b[1] == 0 && b[3] == 0 { return String(data: data, encoding: .utf16LittleEndian) ?? "" }
    return String(decoding: data, as: UTF8.self)
}

func parseTime(_ v: String) -> Double? {
    let v = v.trimmingCharacters(in: .whitespaces)
    if v.isEmpty { return nil }
    if let n = Double(v) { return n }
    var acc = 0.0
    for part in v.split(separator: ":") {
        guard let n = Double(part) else { return nil }
        acc = acc * 60 + n
    }
    return acc
}

/// Reads a playlist exported from Apple Music with Format: Unicode Text.
///
/// The playlist is named after the file. Columns are found by header name (Name/Title,
/// Artist, Album, Time/Duration), so column order and the export language's extra columns
/// don't matter.
///
/// - Throws: ``ExportError`` if the file is empty or is an M3U rather than a text export.
public func parseExport(_ url: URL) throws -> Playlist {
    let text = decodeText(try Data(contentsOf: url))
    let lines = text.components(separatedBy: CharacterSet(charactersIn: "\r\n"))
        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    let name = url.deletingPathExtension().lastPathComponent
    guard let first = lines.first else { throw ExportError(errorDescription: "\(url.lastPathComponent) is empty.") }
    if first.hasPrefix("#EXTM3U") {
        throw ExportError(
            errorDescription:
                "\(url.lastPathComponent) is an M3U file. Re-export the playlist with Format: Unicode Text.")
    }
    let header = first.components(separatedBy: "\t").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
    func col(_ names: String...) -> Int? { names.lazy.compactMap { header.firstIndex(of: $0) }.first }
    var iName = col("name", "title")
    var iArtist = col("artist")
    var iAlbum = col("album")
    let iTime = col("time", "duration")
    if iName == nil {
        iName = 0
        iArtist = 1
        iAlbum = 3
    }

    let tracks = lines.dropFirst().compactMap { line -> SourceTrack? in
        let c = line.components(separatedBy: "\t")
        func at(_ i: Int?) -> String {
            i.flatMap { $0 < c.count ? c[$0] : nil }?.trimmingCharacters(in: .whitespaces) ?? ""
        }
        let title = at(iName)
        guard !title.isEmpty else { return nil }
        return SourceTrack(title: title, artist: at(iArtist), album: at(iAlbum), duration: parseTime(at(iTime)))
    }
    return Playlist(id: "file:" + url.path, name: name, tracks: tracks)
}
