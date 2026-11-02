import AppKit
import Foundation

func fail(_ message: String) -> Never {
    fputs("图标生成失败：\(message)\n", stderr)
    exit(1)
}

guard CommandLine.arguments.count == 3 else {
    fail("用法：swift generate-icon.swift /path/to/AppIcon.png /path/to/AppIcon.iconset")
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
guard FileManager.default.fileExists(atPath: sourceURL.path) else {
    fail("找不到图标素材：\(sourceURL.path)")
}
guard let sourceData = try? Data(contentsOf: sourceURL),
      let sourceBitmap = NSBitmapImageRep(data: sourceData),
      let sourceImage = sourceBitmap.cgImage else {
    fail("无法读取 PNG 图标素材：\(sourceURL.path)")
}

func makeIcon(pixels: Int, name: String) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "TimeIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建图标画布"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics
    defer { NSGraphicsContext.restoreGraphicsState() }
    let context = graphics.cgContext
    let size = CGFloat(pixels)
    context.clear(CGRect(x: 0, y: 0, width: size, height: size))
    context.interpolationQuality = .high
    context.setShouldAntialias(true)

    // Keep the original artwork and transparency. Non-square assets are fitted
    // without cropping, distortion, or any additional background or decoration.
    let scale = min(size / CGFloat(sourceImage.width), size / CGFloat(sourceImage.height))
    let width = CGFloat(sourceImage.width) * scale
    let height = CGFloat(sourceImage.height) * scale
    context.draw(sourceImage, in: CGRect(x: (size - width) / 2, y: (size - height) / 2,
                                        width: width, height: height))
    graphics.flushGraphics()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "TimeIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法编码图标"])
    }
    try data.write(to: destination.appendingPathComponent(name))
}

do {
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
    for size in [16, 32, 128, 256, 512] {
        try makeIcon(pixels: size, name: "icon_\(size)x\(size).png")
        try makeIcon(pixels: size * 2, name: "icon_\(size)x\(size)@2x.png")
    }
} catch {
    fail(error.localizedDescription)
}
