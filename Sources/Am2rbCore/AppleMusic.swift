// Reading playlists straight from Apple Music. This works for cloud-only tracks too,
// since only the metadata is needed.

import Foundation
import iTunesLibrary

/// A playlist to match, read from Apple Music or from an exported text file.
public struct Playlist: Identifiable, Hashable, Sendable {
    /// Apple Music's persistent ID, or `file:<path>` for a playlist read from an export.
    public var id: String
    /// The playlist name, also used as the `.m3u8` filename on export.
    public var name: String
    /// Name of the Apple Music folder it sits in, if any.
    public var folder: String?
    /// Whether it's a Smart Playlist. Shown with a different icon, otherwise treated the same.
    public var isSmart: Bool
    /// The songs in playlist order.
    public var tracks: [SourceTrack]

    /// Creates a playlist.
    public init(id: String, name: String, folder: String? = nil, isSmart: Bool = false, tracks: [SourceTrack]) {
        self.id = id
        self.name = name
        self.folder = folder
        self.isSmart = isSmart
        self.tracks = tracks
    }
}

/// The user's own playlists: built-in ones (Library, Music, Movies…) and folders are left out.
public func loadAppleMusicPlaylists() throws -> [Playlist] {
    let lib = try ITLibrary(apiVersion: "1.0")
    let all = lib.allPlaylists
    let folderNames = Dictionary(
        all.filter { $0.kind == .folder }.map { ($0.persistentID, $0.name) },
        uniquingKeysWith: { a, _ in a })
    return all.compactMap { p in
        guard !p.isMaster, p.isVisible, p.distinguishedKind == .kindNone, p.kind != .folder else { return nil }
        let songs = p.items.filter { $0.mediaKind == .kindSong }.map { item in
            SourceTrack(
                title: item.title,
                artist: item.artist?.name ?? "",
                album: item.album.title ?? "",
                duration: item.totalTime > 0 ? Double(item.totalTime) / 1000 : nil)
        }
        guard !songs.isEmpty else { return nil }
        return Playlist(
            id: p.persistentID.stringValue, name: p.name,
            folder: p.parentID.flatMap { folderNames[$0] },
            isSmart: p.kind == .smart, tracks: songs)
    }
}
