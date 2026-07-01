import AppKit
import AVFoundation

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let asset = AVURLAsset(url: input)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true

for second in [2, 4, 6, 8, 10] {
    let image = try generator.copyCGImage(
        at: CMTime(seconds: Double(second), preferredTimescale: 600),
        actualTime: nil
    )
    let representation = NSBitmapImageRep(cgImage: image)
    guard let data = representation.representation(using: .png, properties: [:]) else { continue }
    try data.write(to: outputDirectory.appendingPathComponent("frame-\(second)s.png"))
}
