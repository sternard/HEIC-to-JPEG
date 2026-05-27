import Foundation
import ImageIO
import UniformTypeIdentifiers

public struct ConversionSummary: Equatable, Sendable {
    public let sourceURL: URL
    public let destinationURL: URL

    public init(sourceURL: URL, destinationURL: URL) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
    }
}

public enum HEICConversionError: Error, LocalizedError, Equatable {
    case unsupportedFile(URL)
    case cannotReadSource(URL)
    case sourceContainsNoImages(URL)
    case cannotCreateDestination(URL)
    case failedToWrite(URL)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFile(let url):
            return "\(url.lastPathComponent) is not a HEIC file."
        case .cannotReadSource(let url):
            return "Could not read \(url.lastPathComponent)."
        case .sourceContainsNoImages(let url):
            return "\(url.lastPathComponent) does not contain an image."
        case .cannotCreateDestination(let url):
            return "Could not create \(url.lastPathComponent)."
        case .failedToWrite(let url):
            return "Could not write \(url.lastPathComponent)."
        }
    }
}

public final class HEICtoJPEGConverter: @unchecked Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func convert(_ sourceURL: URL, quality: Double = 0.9) throws -> ConversionSummary {
        guard HEICFileLocator.isHEICFile(sourceURL) else {
            throw HEICConversionError.unsupportedFile(sourceURL)
        }

        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw HEICConversionError.cannotReadSource(sourceURL)
        }

        guard CGImageSourceGetCount(source) > 0 else {
            throw HEICConversionError.sourceContainsNoImages(sourceURL)
        }

        let destinationURL = HEICFileLocator.availableJPEGURL(for: sourceURL, fileManager: fileManager)

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw HEICConversionError.cannotCreateDestination(destinationURL)
        }

        let options = [
            kCGImageDestinationLossyCompressionQuality: max(0, min(1, quality))
        ] as CFDictionary

        CGImageDestinationAddImageFromSource(destination, source, 0, options)

        guard CGImageDestinationFinalize(destination) else {
            throw HEICConversionError.failedToWrite(destinationURL)
        }

        return ConversionSummary(sourceURL: sourceURL, destinationURL: destinationURL)
    }
}
