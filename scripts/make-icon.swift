// Draws the app icon at every size an .iconset needs. Run through scripts/make-icon.sh.
// The mark is two sets of rings printed in two inks, like a risograph: one is the Apple Music
// song, the other is your copy, and where they line up the inks overprint into a moiré.
// Geometry is in 1024-point units on Apple's macOS icon grid (an 824-point body, 100-point margin).

import AppKit

let paper: UInt32 = 0xF2ECDC
let forest: UInt32 = 0x2F5A49
let yellow: UInt32 = 0xF5D000
let deepForest: UInt32 = 0x1E3A2F

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func gradient(_ colors: [CGColor]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
}

// MARK: - Shapes

/// A rounded rectangle with continuous ("squircle") corners, using Figma's corner smoothing.
func squircle(_ rect: CGRect, radius r: CGFloat, smoothing s: CGFloat) -> CGPath {
    let p = (1 + s) * r
    let arcMeasure = 90 * (1 - s)
    let arcLength = sin(arcMeasure / 2 * .pi / 180) * r * sqrt(2)
    let alpha = (90 - arcMeasure) / 2
    let beta = 45 * s
    let c = r * tan(alpha / 2 * .pi / 180) * cos(beta * .pi / 180)
    let d = c * tan(beta * .pi / 180)
    let b = (p - arcLength - c - d) / 3
    let a = 2 * b

    // Each corner in its own frame: u runs along the incoming edge, v along the outgoing one.
    let corners: [(CGPoint, CGVector, CGVector)] = [
        (CGPoint(x: rect.maxX, y: rect.minY), CGVector(dx: 1, dy: 0), CGVector(dx: 0, dy: 1)),
        (CGPoint(x: rect.maxX, y: rect.maxY), CGVector(dx: 0, dy: 1), CGVector(dx: -1, dy: 0)),
        (CGPoint(x: rect.minX, y: rect.maxY), CGVector(dx: -1, dy: 0), CGVector(dx: 0, dy: -1)),
        (CGPoint(x: rect.minX, y: rect.minY), CGVector(dx: 0, dy: -1), CGVector(dx: 1, dy: 0)),
    ]
    let path = CGMutablePath()
    path.move(to: CGPoint(x: rect.minX + p, y: rect.minY))
    for (corner, u, v) in corners {
        let start = CGPoint(x: corner.x - p * u.dx, y: corner.y - p * u.dy)
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: start.x + x * u.dx + y * v.dx, y: start.y + x * u.dy + y * v.dy)
        }
        path.addLine(to: start)
        path.addCurve(to: pt(a + b + c, d), control1: pt(a, 0), control2: pt(a + b, 0))
        // The arc between the two curves, sampled so it's independent of the context's flip
        let arcStart = (x: a + b + c, y: d)
        let arcCenter = (x: p - r, y: r)
        let from = atan2(arcStart.y - arcCenter.y, arcStart.x - arcCenter.x)
        let to = from + arcMeasure * .pi / 180
        for i in 1...24 {
            let t = from + (to - from) * CGFloat(i) / 24
            path.addLine(to: pt(arcCenter.x + r * cos(t), arcCenter.y + r * sin(t)))
        }
        let e = (x: arcStart.x + arcLength, y: arcStart.y + arcLength)
        path.addCurve(
            to: pt(e.x + d, e.y + a + b + c), control1: pt(e.x + d, e.y + c), control2: pt(e.x + d, e.y + b + c))
    }
    path.closeSubpath()
    return path
}

func circle(_ center: CGPoint, _ r: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r), transform: nil)
}

/// One set of rings, outermost at `outer`, spaced evenly in to the center.
func rings(_ ctx: CGContext, center: CGPoint, count: Int, outer: CGFloat, width: CGFloat, ink: UInt32) {
    ctx.setStrokeColor(color(ink))
    ctx.setLineWidth(width)
    for i in 1...count {
        ctx.addPath(circle(center, outer * CGFloat(i) / CGFloat(count)))
    }
    ctx.strokePath()
}

/// Paper grain: a fixed scatter of faint dark specks, the same on every run.
func grain(_ ctx: CGContext, in rect: CGRect) {
    var seed: UInt64 = 7
    func next() -> CGFloat {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return CGFloat(seed >> 33) / CGFloat(UInt32.max >> 1)
    }
    for _ in 0..<9000 {
        let x = rect.minX + next() * rect.width
        let y = rect.minY + next() * rect.height
        ctx.setFillColor(color(deepForest, 0.05 + 0.1 * next()))
        ctx.fill(CGRect(x: x, y: y, width: 1.5 + 2 * next(), height: 1.5 + 2 * next()))
    }
}

// MARK: - Drawing

/// Renders the icon at `px` pixels square. Smaller sizes use fewer, thicker rings so the two
/// inks stay separate instead of turning to mush.
func render(px: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    let scale = CGFloat(px) / 1024
    // Work top-down, in 1024-point units
    ctx.translateBy(x: 0, y: CGFloat(px))
    ctx.scaleBy(x: scale, y: -scale)

    let (count, width): (Int, CGFloat) = px <= 16 ? (2, 64) : px <= 32 ? (3, 44) : px <= 64 ? (4, 28) : (5, 20)
    let outer: CGFloat = px <= 32 ? 236 : 222
    let bodyRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let body = squircle(bodyRect, radius: 185.4, smoothing: 0.6)

    // Body, with the drop shadow from Apple's icon template
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 20 * scale, color: color(0x000000, 0.3))
    ctx.addPath(body)
    ctx.setFillColor(color(paper))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(body)
    ctx.clip()
    // A faint fall-off across the sheet, so it reads as paper rather than a flat fill
    ctx.drawLinearGradient(
        gradient([color(0xF7F2E5), color(paper), color(0xE8E0CC)]), start: CGPoint(x: 512, y: 100),
        end: CGPoint(x: 512, y: 924), options: [])

    // First ink, then the second overprinted on it and a touch off register
    rings(ctx, center: CGPoint(x: 446, y: 512), count: count, outer: outer, width: width, ink: forest)
    ctx.setBlendMode(.multiply)
    let offset: CGFloat = px >= 128 ? 1 : 0
    rings(
        ctx, center: CGPoint(x: 578 + 4 * offset, y: 512 + 3.3 * offset), count: count, outer: outer, width: width,
        ink: yellow)
    if px >= 128 { grain(ctx, in: bodyRect) }
    ctx.setBlendMode(.normal)

    // An edge so the pale sheet doesn't dissolve into a white Finder window
    ctx.addPath(body)
    ctx.setStrokeColor(color(deepForest, px <= 32 ? 0.35 : 0.14))
    ctx.setLineWidth(px <= 32 ? 24 : 6)
    ctx.strokePath()
    ctx.restoreGState()
    return rep
}

// MARK: - Output

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset")
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for factor in [1, 2] {
        let name = factor == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        let png = render(px: points * factor).representation(using: .png, properties: [:])!
        try png.write(to: out.appendingPathComponent(name))
    }
}
