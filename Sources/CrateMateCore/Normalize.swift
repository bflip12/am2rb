// Text normalising and title splitting, shared by matching and search.

import Foundation

/// Lowercase, strip accents, "&" -> "and", everything that isn't a letter or digit becomes a single space.
public func norm(_ s: String) -> String {
    var out = String.UnicodeScalarView()
    var pendingSpace = false
    let folded = s.decomposedStringWithCompatibilityMapping
        .unicodeScalars.filter { !(0x300...0x36F).contains($0.value) }
    let lowered = String(String.UnicodeScalarView(folded)).lowercased().replacingOccurrences(of: "&", with: " and ")
    for u in lowered.unicodeScalars {
        if isLetterOrNumber(u) {
            if pendingSpace && !out.isEmpty { out.append(" ") }
            pendingSpace = false
            out.append(u)
        } else {
            pendingSpace = true
        }
    }
    return String(out)
}

private func isLetterOrNumber(_ u: Unicode.Scalar) -> Bool {
    switch u.properties.generalCategory {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
        .decimalNumber, .letterNumber, .otherNumber:
        return true
    default:
        return false
    }
}

/// The words of `s` after ``norm(_:)``.
public func tokens(_ s: String) -> [String] {
    norm(s).split(separator: " ").map(String.init)
}

let neutralVersion: Set<String> = ["original", "mix", "version", "the", "a", "and"]

/// A title taken apart by ``splitTitle(_:)``.
public struct SplitTitle: Equatable {
    /// The title without version or featured-artist parts, normalised.
    public var core: String
    /// Normalised words from the version parts, minus neutral ones like "original" and "mix".
    public var vtokens: Set<String>
    /// Featured artists, as written.
    public var feats: [String]
}

private let bracketRe = try! NSRegularExpression(pattern: #"[(\[]([^)\]]*)[)\]]"#)
private let featPrefixRe = try! NSRegularExpression(
    pattern: #"^\s*(feat\.?|ft\.?|featuring|with)\s+"#, options: .caseInsensitive)
private let featTailRe = try! NSRegularExpression(
    pattern: #"\s+(feat\.?|ft\.?|featuring)\s+(.*)$"#, options: .caseInsensitive)
private let dashVersionRe = try! NSRegularExpression(
    pattern:
        #"^(.*\S)\s+[-–—]\s+(.*(mix|remix|edit|dub|version|rework|vip|instrumental|bootleg|refix|remaster(ed)?).*)$"#,
    options: .caseInsensitive)

private func ns(_ s: String) -> NSRange { NSRange(s.startIndex..., in: s) }
private func group(_ m: NSTextCheckingResult, _ i: Int, in s: String) -> String {
    Range(m.range(at: i), in: s).map { String(s[$0]) } ?? ""
}

/// Split "Track (Someone Remix) [feat. X]" into core title, version tokens and featured artists.
public func splitTitle(_ raw: String) -> SplitTitle {
    var s = raw
    var versions: [String] = []
    var feats: [String] = []

    // Bracketed parts: either "feat. X" or a version like "Extended Mix"
    for m in bracketRe.matches(in: s, range: ns(s)).reversed() {
        let inner = group(m, 1, in: s)
        if let fm = featPrefixRe.firstMatch(in: inner, range: ns(inner)) {
            feats.insert(String(inner[Range(fm.range, in: inner)!.upperBound...]), at: 0)
        } else {
            versions.insert(inner, at: 0)
        }
        s.replaceSubrange(Range(m.range, in: s)!, with: " ")
    }
    // Trailing "feat. X" without brackets
    if let m = featTailRe.firstMatch(in: s, range: ns(s)) {
        feats.append(group(m, 2, in: s))
        s.replaceSubrange(Range(m.range, in: s)!, with: "")
    }
    // "Title - Extended Mix"
    if let m = dashVersionRe.firstMatch(in: s, range: ns(s)) {
        versions.append(group(m, 2, in: s))
        s = group(m, 1, in: s)
    }
    let vt = Set(tokens(versions.joined(separator: " ")).filter { !neutralVersion.contains($0) })
    return SplitTitle(core: norm(s), vtokens: vt, feats: feats)
}

func artistTokens(_ raw: String, _ feats: [String]) -> Set<String> {
    var t = Set(tokens(([raw] + feats).joined(separator: " ")))
    for w in ["feat", "ft", "featuring", "and", "x", "vs", "with", "the"] { t.remove(w) }
    return t
}

private let leadingTrackNo = try! NSRegularExpression(pattern: #"^\s*\d{1,3}\s*[-._)]?\s+"#)
private let dashSplit = try! NSRegularExpression(pattern: #"\s+[-–—]\s+"#)

/// Guess artist and title from a filename like "01 - Artist - Title.wav".
public func fromFilename(_ path: String) -> (artist: String, title: String) {
    var stem = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
    if let m = leadingTrackNo.firstMatch(in: stem, range: ns(stem)) {
        stem.removeSubrange(Range(m.range, in: stem)!)
    }
    var parts: [String] = []
    var last = stem.startIndex
    for m in dashSplit.matches(in: stem, range: ns(stem)) {
        let r = Range(m.range, in: stem)!
        parts.append(String(stem[last..<r.lowerBound]))
        last = r.upperBound
    }
    parts.append(String(stem[last...]))
    if parts.count >= 2 { return (parts[0], parts.dropFirst().joined(separator: " - ")) }
    return ("", stem)
}

/// Formats seconds as "m:ss", or "?:??" if unknown.
public func fmtDur(_ d: Double?) -> String {
    guard let d, d > 0 else { return "?:??" }
    let s = Int(d.rounded())
    return "\(s / 60):\(String(format: "%02d", s % 60))"
}
