#!/usr/bin/env swift
//
// Converts a screen recording into an animated GIF for the README.
//
// This exists so that recording the widget needs nothing but Xcode. The
// obvious tool is ffmpeg, but the project has a zero-dependency rule and a
// README animation is not a good reason to make every contributor install a
// video toolchain — AVFoundation can read the movie and ImageIO can write the
// GIF, and both ship with macOS.
//
//   ./scripts/movie-to-gif.swift recording.mov docs/widget.gif
//   ./scripts/movie-to-gif.swift recording.mov docs/widget.gif 12 480 0
//
// Arguments: input, output, frames per second (default 10), width in pixels
// (default 420), and how long to hold the last frame before the loop restarts
// (default 1.5 seconds, 0 to disable). Height follows the source aspect ratio.
//
// The hold matters more than it sounds. A README GIF loops forever, and the
// last frame is the one carrying the payoff — the answer marked right or
// wrong. Without a pause it flashes past and the animation restarts before
// that has registered.
//
// GIF is a poor codec — 256 colours, no interframe compression worth the name
// — so the defaults trade smoothness for a file size a README can carry. Ten
// frames a second is enough to read a button tap.

import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Arguments

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    fail("Usage: movie-to-gif.swift <input.mov> <output.gif> [fps] [width] [hold]")
}

let inputURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2])
let framesPerSecond = arguments.count > 3 ? Int(arguments[3]) ?? 10 : 10
let targetWidth = arguments.count > 4 ? Int(arguments[4]) ?? 420 : 420
let finalHold = arguments.count > 5 ? Double(arguments[5]) ?? 1.5 : 1.5

guard framesPerSecond > 0, targetWidth > 0 else {
    fail("Frames per second and width must both be positive.")
}

guard finalHold >= 0 else {
    fail("The final hold cannot be negative.")
}

guard FileManager.default.fileExists(atPath: inputURL.path) else {
    fail("No such file: \(inputURL.path)")
}

// MARK: - Sampling

let asset = AVURLAsset(url: inputURL)

guard let duration = try? await asset.load(.duration), duration.seconds > 0 else {
    fail("Could not read \(inputURL.lastPathComponent) — is it a movie?")
}

let frameCount = max(1, Int(duration.seconds * Double(framesPerSecond)))
let times = (0 ..< frameCount).map { index in
    CMTime(seconds: Double(index) / Double(framesPerSecond), preferredTimescale: 600)
}

let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
// Without a zero tolerance the generator is free to return the nearest
// keyframe, which on a screen recording means several sampled "frames"
// collapsing onto the same image and a GIF that visibly stutters.
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
// A zero height tells AVFoundation to preserve the aspect ratio.
generator.maximumSize = CGSize(width: targetWidth, height: 0)

/// Each frame is kept with the time it was requested for. A screen recording
/// is variable frame rate — `simctl` emits almost nothing while the screen is
/// still — so with zero tolerance many of the requested times have no frame to
/// return and get skipped. Skipping is the right call, but the *time* they
/// covered still has to be paid: giving every surviving frame an identical
/// delay silently compresses a 14 s recording into an 8 s GIF that plays too
/// fast. Holding the previous frame on screen for the gap instead keeps
/// playback honest no matter how many frames the generator drops.
var frames: [(image: CGImage, time: Double)] = []
frames.reserveCapacity(frameCount)
// `images(for:)` yields in the order the times were requested, so appending
// keeps playback order without any sorting.
for await result in generator.images(for: times) {
    guard let image = try? result.image else { continue }
    frames.append((image, result.requestedTime.seconds))
}

guard !frames.isEmpty else {
    fail("Could not extract any frames from \(inputURL.lastPathComponent).")
}

// MARK: - Writing

try? FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true
)

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL, UTType.gif.identifier as CFString, frames.count, nil
) else {
    fail("Could not open \(outputURL.path) for writing.")
}

// Loop count zero means forever, which is what a README animation wants.
CGImageDestinationSetProperties(destination, [
    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]
] as CFDictionary)

let interval = 1.0 / Double(framesPerSecond)

for (index, frame) in frames.enumerated() {
    // A frame stays up until the next surviving one was due, so any gap left
    // by a dropped frame is spent holding the last real image rather than
    // being cut out of the running time.
    let isLast = index + 1 == frames.count
    let nextTime = isLast ? frame.time + interval : frames[index + 1].time
    let delay = max(interval, nextTime - frame.time) + (isLast ? finalHold : 0)
    // The unclamped delay is the one modern viewers honour; the clamped one is
    // written too because some older renderers still floor anything under
    // 0.1 s to a tenth of a second and would otherwise play at the wrong speed.
    let frameProperties = [
        kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFUnclampedDelayTime: delay,
            kCGImagePropertyGIFDelayTime: delay
        ]
    ] as CFDictionary
    CGImageDestinationAddImage(destination, frame.image, frameProperties)
}

guard CGImageDestinationFinalize(destination) else {
    fail("Could not write \(outputURL.path).")
}

let size = (try? outputURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
let megabytes = Double(size) / 1_048_576
print(String(
    format: "Wrote %d frames (%.1f s at %d fps, %d px wide) to %@ — %.1f MB",
    frames.count, duration.seconds, framesPerSecond, targetWidth, outputURL.path, megabytes
))

// GitHub serves READMEs over a CDN but a heavy GIF still hurts the first
// impression the file exists to make.
if megabytes > 5 {
    FileHandle.standardError.write(Data(
        "This is large for a README. Try a lower fps, a smaller width, or a shorter clip.\n".utf8
    ))
}
