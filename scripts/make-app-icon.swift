#!/usr/bin/env swift
//
// Renders the app icon.
//
// The icon is generated rather than committed as an opaque binary so that it
// can be reviewed, tweaked and reproduced like any other source. Run it after
// changing anything here; the PNG it writes is committed alongside it because
// the build must not depend on macOS-only tooling.
//
//   ./scripts/make-app-icon.swift
//   ./scripts/make-app-icon.swift /tmp/preview.png   # render somewhere else
//
// Design: a deep navy field, a pair of braces holding a single crumb. "Kod
// Kırıntısı" is Turkish for "code crumb", and one puzzle a day is exactly one
// crumb. Kept to three shapes because the icon is read at 60 points on a Home
// Screen far more often than at 1024.

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Palette

/// Deep navy, top of the background gradient.
let backgroundTop = CGColor(srgbRed: 0.106, green: 0.137, blue: 0.243, alpha: 1)
/// Near-black navy, bottom of the background gradient.
let backgroundBottom = CGColor(srgbRed: 0.043, green: 0.059, blue: 0.114, alpha: 1)
/// Slightly warm off-white for the braces — pure white reads as harsh here.
let braceColor = CGColor(srgbRed: 0.937, green: 0.949, blue: 0.973, alpha: 1)
/// The crumb. Warm orange so the eye lands on it first.
let crumbColor = CGColor(srgbRed: 1.0, green: 0.624, blue: 0.271, alpha: 1)

// MARK: - Geometry

let side = 1024.0
let canvas = CGRect(x: 0, y: 0, width: side, height: side)

/// Menlo ships with every macOS install, so the render is reproducible on any
/// machine. A UI font would drift between OS releases and silently restyle the
/// icon on the next run.
let braceFontName = "Menlo-Bold"
let braceFontSize = 620.0
/// How far each brace sits from the centre line.
let braceOffset = 176.0
/// Nudges the pair up so the optical centre, not the box centre, is centred.
let braceBaselineNudge = 12.0
let crumbRadius = 54.0

// MARK: - Rendering

/// Draws one brace centred on `centre`, measuring the glyph itself so the two
/// braces balance regardless of the font's side bearings.
/// - Returns: The rectangle the glyph actually covers, for checking that the
///   composition stays inside the icon's safe area.
@discardableResult
func drawBrace(_ character: String, centeredAt centre: CGPoint, in context: CGContext) -> CGRect {
    let font = CTFontCreateWithName(braceFontName as CFString, braceFontSize, nil)
    // The CoreText attribute names, not the AppKit/UIKit ones: this script has
    // no view layer and must build with Foundation alone.
    let attributed = NSAttributedString(
        string: character,
        attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): braceColor
        ]
    )
    let line = CTLineCreateWithAttributedString(attributed)
    // Glyph path bounds, not typographic bounds: the latter includes the
    // font's line spacing and would push the braces off centre.
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

    // The glyph covers [textPosition + bounds.origin, ... + bounds.size], so
    // its centre lands at textPosition + bounds.mid. Subtracting the origin as
    // well would count the descender twice and push the pair off centre.
    let position = CGPoint(x: centre.x - bounds.midX, y: centre.y - bounds.midY)
    context.textPosition = position
    CTLineDraw(line, context)

    return bounds.offsetBy(dx: position.x, dy: position.y)
}

func drawIcon(in context: CGContext) {
    // Full-bleed background: iOS applies the rounded mask itself, and an icon
    // that rounds its own corners ends up with a dark halo inside the mask.
    guard let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [backgroundTop, backgroundBottom] as CFArray,
        locations: [0, 1]
    ) else {
        FileHandle.standardError.write(Data("Could not build the background gradient.\n".utf8))
        exit(1)
    }
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: side),
        end: CGPoint(x: 0, y: 0),
        options: []
    )

    let centre = CGPoint(x: canvas.midX, y: canvas.midY + braceBaselineNudge)
    let left = drawBrace("{", centeredAt: CGPoint(x: centre.x - braceOffset, y: centre.y), in: context)
    let right = drawBrace("}", centeredAt: CGPoint(x: centre.x + braceOffset, y: centre.y), in: context)

    context.setFillColor(crumbColor)
    context.fillEllipse(in: CGRect(
        x: centre.x - crumbRadius,
        y: centre.y - crumbRadius,
        width: crumbRadius * 2,
        height: crumbRadius * 2
    ))

    report(artwork: left.union(right))
}

/// Prints how much of the canvas the artwork occupies.
///
/// Apple's icon grid keeps content well inside the square — the rounded mask
/// and the visual weight of a full-bleed shape both eat into it — so anything
/// much past ~70% starts to look like it is bursting out of the icon.
func report(artwork: CGRect) {
    let widthShare = artwork.width / side * 100
    let heightShare = artwork.height / side * 100
    let message = String(
        format: "Artwork spans %.0f×%.0f px (%.0f%% × %.0f%% of the canvas).\n",
        artwork.width, artwork.height, widthShare, heightShare
    )
    FileHandle.standardError.write(Data(message.utf8))
}

// MARK: - Output

let defaultPath = "App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultPath
let outputURL = URL(fileURLWithPath: outputPath)

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
    FileHandle.standardError.write(Data("sRGB is unavailable on this machine.\n".utf8))
    exit(1)
}

// App Store icons must be fully opaque, so the context carries no alpha
// channel at all rather than relying on the drawing to cover every pixel.
guard let context = CGContext(
    data: nil,
    width: Int(side),
    height: Int(side),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    FileHandle.standardError.write(Data("Could not create the drawing context.\n".utf8))
    exit(1)
}

drawIcon(in: context)

guard let image = context.makeImage() else {
    FileHandle.standardError.write(Data("Could not snapshot the drawing context.\n".utf8))
    exit(1)
}

try? FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL, UTType.png.identifier as CFString, 1, nil
) else {
    FileHandle.standardError.write(Data("Could not open \(outputPath) for writing.\n".utf8))
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("Could not write \(outputPath).\n".utf8))
    exit(1)
}

print("Wrote \(Int(side))×\(Int(side)) icon to \(outputPath)")
