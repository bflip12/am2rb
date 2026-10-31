// Scanning the DJ folder. Read-only: files are never moved, renamed or retagged,
// because Rekordbox tracks them by path.

import AVFoundation
import AudioToolbox
import Foundation

let audioExtensions: Set<String> = ["mp3", "wav", "aif", "aiff", "flac", "m4a", "aac", "alac", "ogg", "opus", "wma"]

/// `~/Library/Application Support/CrateMate`, where the tag cache lives.
public let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("CrateMate", isDirectory: true)
let cacheFile = appSupportDir.appendingPathComponent("library-cache.json")

struct CachedTags: Codable {
    var key: String
    var title: String
    var artist: String
    var album: String
    var duration: Double?
}

/// The outcome of ``scanLibrary(_:rescan:progress:)``.
public struct ScanResult: Sendable {
    /// Every audio file found, ready for matching.
    public var index: LibraryIndex
    /// How many files had their tags read this time rather than coming from the cache.
    public var newlyRead: Int
}

/// Every audio file under `dir`, skipping hidden files and folders.
func audioFiles(in dir: URL) -> [(path: String, key: String)] {
    let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
    guard
        let e = FileManager.default.enumerator(
            at: dir, includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants])
    else { return [] }
    var out: [(String, String)] = []
    for case let url as URL in e where audioExtensions.contains(url.pathExtension.lowercased()) {
        guard let v = try? url.resourceValues(forKeys: Set(keys)), v.isRegularFile == true else { continue }
        let mtime = Int((v.contentModificationDate?.timeIntervalSince1970 ?? 0) * 1000)
        out.append((url.path, "\(v.fileSize ?? 0):\(mtime)"))
    }
    return out
}

/// Title, artist, album and duration.
///
/// Core Audio first (fast, covers mp3/aiff/wav/flac/m4a), then AVFoundation for anything it
/// leaves blank.
func readTags(_ path: String) async -> (title: String, artist: String, album: String, duration: Double?) {
    let url = URL(fileURLWithPath: path)
    var title = ""
    var artist = ""
    var album = ""
    var duration: Double?

    var fileID: AudioFileID?
    if AudioFileOpenURL(url as CFURL, .readPermission, 0, &fileID) == noErr, let f = fileID {
        var info: Unmanaged<CFDictionary>?
        var size = UInt32(MemoryLayout<Unmanaged<CFDictionary>?>.size)
        if AudioFileGetProperty(f, kAudioFilePropertyInfoDictionary, &size, &info) == noErr,
            let d = info?.takeRetainedValue() as? [String: Any]
        {
            title = (d["title"] as? String) ?? ""
            artist = (d["artist"] as? String) ?? ""
            album = (d["album"] as? String) ?? ""
        }
        var secs: Float64 = 0
        size = UInt32(MemoryLayout<Float64>.size)
        if AudioFileGetProperty(f, kAudioFilePropertyEstimatedDuration, &size, &secs) == noErr, secs > 0 {
            duration = secs.rounded()
        }
        AudioFileClose(f)
    }

    if title.isEmpty || artist.isEmpty || duration == nil {
        let asset = AVURLAsset(url: url)
        if let (meta, dur) = try? await asset.load(.commonMetadata, .duration) {
            func value(_ id: AVMetadataIdentifier) async -> String {
                guard let item = AVMetadataItem.metadataItems(from: meta, filteredByIdentifier: id).first else {
                    return ""
                }
                return (try? await item.load(.stringValue)) ?? ""
            }
            if title.isEmpty { title = await value(.commonIdentifierTitle) }
            if artist.isEmpty { artist = await value(.commonIdentifierArtist) }
            if album.isEmpty { album = await value(.commonIdentifierAlbumName) }
            if duration == nil, dur.isNumeric, dur.seconds > 0 { duration = dur.seconds.rounded() }
        }
    }
    return (
        title.trimmingCharacters(in: .whitespaces), artist.trimmingCharacters(in: .whitespaces),
        album.trimmingCharacters(in: .whitespaces), duration
    )
}

/// Scans `dir`, reading tags only for files that are new or changed since the last scan.
///
/// Files are only ever read. Untagged files get their artist and title from the filename.
///
/// - Parameters:
///   - dir: The DJ folder.
///   - rescan: Ignore the cache and read every file again.
///   - progress: Called with (files done, total files) as the scan goes. Not on the main actor.
public func scanLibrary(
    _ dir: URL, rescan: Bool = false,
    progress: @escaping @Sendable (Int, Int) -> Void = { _, _ in }
) async -> ScanResult {
    let files = audioFiles(in: dir)
    var cache: [String: CachedTags] = [:]
    if !rescan, let data = try? Data(contentsOf: cacheFile) {
        cache = (try? JSONDecoder().decode([String: CachedTags].self, from: data)) ?? [:]
    }

    let todo = files.filter { cache[$0.path]?.key != $0.key }
    let fromCache = files.count - todo.count
    progress(fromCache, files.count)

    await withTaskGroup(of: (String, CachedTags).self) { group in
        var next = 0
        func add() {
            guard next < todo.count else { return }
            let (path, key) = todo[next]
            next += 1
            group.addTask {
                let t = await readTags(path)
                return (
                    path, CachedTags(key: key, title: t.title, artist: t.artist, album: t.album, duration: t.duration)
                )
            }
        }
        for _ in 0..<16 { add() }
        var done = fromCache
        while let (path, tags) = await group.next() {
            cache[path] = tags
            done += 1
            if done % 25 == 0 || done == files.count { progress(done, files.count) }
            add()
        }
    }

    // Forget files that are gone from this library
    let present = Set(files.map(\.path))
    let prefix = dir.path.hasSuffix("/") ? dir.path : dir.path + "/"
    for k in cache.keys where k.hasPrefix(prefix) && !present.contains(k) { cache[k] = nil }
    try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
    try? JSONEncoder().encode(cache).write(to: cacheFile, options: .atomic)

    let tracks = files.map { f -> LibraryTrack in
        let c = cache[f.path]!
        let fn = fromFilename(f.path)
        return LibraryTrack(
            file: f.path,
            title: c.title.isEmpty ? fn.title : c.title,
            artist: c.artist.isEmpty ? fn.artist : c.artist,
            album: c.album, duration: c.duration)
    }
    return ScanResult(index: LibraryIndex(tracks: tracks), newlyRead: todo.count)
}
