// Renders a 1024×1024 app icon master PNG for Horn OK Please using Core
// Graphics only (runs headless). Usage: swift generate-app-icon.swift <out.png>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

guard let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Unable to create bitmap context")
}

let canvas = CGFloat(size)

func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r / 255, green: g / 255, blue: b / 255, alpha: a)
}

ctx.clear(CGRect(x: 0, y: 0, width: canvas, height: canvas))

// Rounded-square (squircle-ish) base.
let inset: CGFloat = 84
let rect = CGRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
let radius = rect.width * 0.2237
let basePath = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

ctx.saveGState()
ctx.addPath(basePath)
ctx.clip()

let baseColors = [rgb(20, 18, 30), rgb(8, 8, 13)] as CFArray
let baseGradient = CGGradient(colorsSpace: colorSpace, colors: baseColors, locations: [0, 1])!
ctx.drawLinearGradient(baseGradient, start: CGPoint(x: 0, y: canvas), end: CGPoint(x: 0, y: 0), options: [])

func radialGlow(_ center: CGPoint, _ color: CGColor, _ outerRadius: CGFloat) {
    let colors = [color, color.copy(alpha: 0)!] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: outerRadius, options: [])
}

// Monochrome: a single soft silver light from the top for depth.
radialGlow(CGPoint(x: canvas * 0.50, y: canvas * 0.72), rgb(255, 255, 255, 0.16), canvas * 0.60)
radialGlow(CGPoint(x: canvas * 0.50, y: canvas * 0.30), rgb(255, 255, 255, 0.05), canvas * 0.50)

// Waveform bars, center-weighted.
let heights: [CGFloat] = [0.30, 0.55, 0.80, 0.50, 0.34]
let barWidth: CGFloat = 78
let gap: CGFloat = 46
let totalWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * gap
var x = canvas / 2 - totalWidth / 2
let midY = canvas / 2

// Top-to-bottom silver gradient for a restrained, premium monochrome look.
let barColors = [rgb(245, 246, 250), rgb(170, 172, 182)] as CFArray
let barGradient = CGGradient(colorsSpace: colorSpace, colors: barColors, locations: [0, 1])!

for height in heights {
    let barHeight = canvas * height
    let barRect = CGRect(x: x, y: midY - barHeight / 2, width: barWidth, height: barHeight)
    let barPath = CGPath(roundedRect: barRect, cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil)
    ctx.saveGState()
    ctx.addPath(barPath)
    ctx.clip()
    ctx.drawLinearGradient(
        barGradient,
        start: CGPoint(x: barRect.midX, y: barRect.maxY),
        end: CGPoint(x: barRect.midX, y: barRect.minY),
        options: []
    )
    ctx.restoreGState()
    x += barWidth + gap
}

ctx.restoreGState()

// Thin luminous edge.
ctx.saveGState()
ctx.addPath(basePath)
ctx.setStrokeColor(rgb(255, 255, 255, 0.10))
ctx.setLineWidth(3)
ctx.strokePath()
ctx.restoreGState()

guard let image = ctx.makeImage() else { fatalError("Unable to render image") }

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let url = URL(fileURLWithPath: outPath)

guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Unable to create image destination")
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Unable to write PNG") }
print("Wrote \(outPath)")
