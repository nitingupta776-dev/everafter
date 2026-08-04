import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation

let outputPath = CommandLine.arguments.dropFirst().first
    ?? "assets/video/public-demo-memory.mp4"
let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try? FileManager.default.removeItem(at: outputURL)

let width = 640
let height = 360
let framesPerSecond: Int32 = 24
let durationSeconds = 3
let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
let input = AVAssetWriterInput(
    mediaType: .video,
    outputSettings: [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height,
    ]
)
input.expectsMediaDataInRealTime = false

let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: input,
    sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String:
            kCVPixelFormatType_32ARGB,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
    ]
)
guard writer.canAdd(input) else {
    fatalError("Could not add the public demo video input")
}
writer.add(input)
guard writer.startWriting() else {
    fatalError(writer.error?.localizedDescription ?? "Could not start writing")
}
writer.startSession(atSourceTime: .zero)

let colorSpace = CGColorSpaceCreateDeviceRGB()
for frameIndex in 0..<(Int(framesPerSecond) * durationSeconds) {
    while !input.isReadyForMoreMediaData {
        Thread.sleep(forTimeInterval: 0.002)
    }

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferPoolCreatePixelBuffer(
        nil,
        adaptor.pixelBufferPool!,
        &pixelBuffer
    )
    guard status == kCVReturnSuccess, let pixelBuffer else {
        fatalError("Could not allocate a public demo video frame")
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    let context = CGContext(
        data: CVPixelBufferGetBaseAddress(pixelBuffer),
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    )!

    let progress = CGFloat(frameIndex) /
        CGFloat(Int(framesPerSecond) * durationSeconds - 1)
    context.setFillColor(CGColor(red: 0.10, green: 0.07, blue: 0.05, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    let radius = 78 + 14 * sin(progress * .pi * 2)
    let centerX = CGFloat(width) * (0.34 + 0.32 * progress)
    let centerY = CGFloat(height) * 0.52
    context.setFillColor(CGColor(red: 0.72, green: 0.52, blue: 0.24, alpha: 1))
    context.fillEllipse(
        in: CGRect(
            x: centerX - radius,
            y: centerY - radius,
            width: radius * 2,
            height: radius * 2
        )
    )
    context.setStrokeColor(CGColor(red: 0.95, green: 0.88, blue: 0.70, alpha: 1))
    context.setLineWidth(3)
    context.strokeEllipse(
        in: CGRect(
            x: centerX - radius - 12,
            y: centerY - radius - 12,
            width: (radius + 12) * 2,
            height: (radius + 12) * 2
        )
    )

    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    let time = CMTime(value: Int64(frameIndex), timescale: framesPerSecond)
    guard adaptor.append(pixelBuffer, withPresentationTime: time) else {
        fatalError(writer.error?.localizedDescription ?? "Could not append frame")
    }
}

input.markAsFinished()
let semaphore = DispatchSemaphore(value: 0)
writer.finishWriting { semaphore.signal() }
semaphore.wait()
guard writer.status == .completed else {
    fatalError(writer.error?.localizedDescription ?? "Could not finish video")
}

print(outputURL.path)
