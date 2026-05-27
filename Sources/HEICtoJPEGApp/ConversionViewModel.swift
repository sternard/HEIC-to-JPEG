import AppKit
import Foundation
import HEICtoJPEGCore

@MainActor
final class ConversionViewModel: ObservableObject {
    @Published private(set) var items: [ConversionItem] = []
    @Published private(set) var isDropTargeted = false
    @Published private(set) var isConverting = false

    private let converter = HEICtoJPEGConverter()

    var summaryText: String {
        let convertedCount = items.filter { $0.status == .converted }.count
        let failedCount = items.filter { $0.status == .failed }.count
        let skippedCount = items.filter { $0.status == .skipped }.count

        if items.isEmpty {
            return "Ready"
        }

        var parts = ["\(convertedCount) converted"]
        if failedCount > 0 {
            parts.append("\(failedCount) failed")
        }
        if skippedCount > 0 {
            parts.append("\(skippedCount) skipped")
        }
        return parts.joined(separator: " - ")
    }

    func setDropTargeted(_ targeted: Bool) {
        isDropTargeted = targeted
    }

    func convertDroppedURLs(_ urls: [URL]) {
        let accessTokens = urls.map { url in
            (url, url.startAccessingSecurityScopedResource())
        }
        defer {
            for (url, accessed) in accessTokens where accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let candidates = HEICFileLocator.heicFiles(in: urls)
        let skipped = urls.filter { !HEICFileLocator.isHEICFile($0) && HEICFileLocator.heicFiles(in: $0).isEmpty }

        if candidates.isEmpty && skipped.isEmpty {
            return
        }

        let pendingItems = candidates.map {
            ConversionItem(sourceURL: $0, destinationURL: nil, status: .pending, message: "Queued")
        }
        let skippedItems = skipped.map {
            ConversionItem(sourceURL: $0, destinationURL: nil, status: .skipped, message: "No HEIC files found")
        }

        items = pendingItems + skippedItems + items
        isConverting = true

        Task {
            for sourceURL in candidates {
                await convert(sourceURL)
            }
            isConverting = false
        }
    }

    private func convert(_ sourceURL: URL) async {
        update(sourceURL, status: .converting, message: "Converting")

        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let summary = try await Task.detached(priority: .userInitiated) {
                try self.converter.convert(sourceURL)
            }.value

            update(
                sourceURL,
                destinationURL: summary.destinationURL,
                status: .converted,
                message: summary.destinationURL.lastPathComponent
            )
        } catch {
            update(sourceURL, status: .failed, message: error.localizedDescription)
        }
    }

    func reveal(_ item: ConversionItem) {
        guard let url = item.destinationURL ?? (item.sourceURL.isFileURL ? item.sourceURL : nil) else {
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func clear() {
        items = []
    }

    private func update(
        _ sourceURL: URL,
        destinationURL: URL? = nil,
        status: ConversionStatus,
        message: String
    ) {
        guard let index = items.firstIndex(where: { $0.sourceURL == sourceURL }) else {
            return
        }

        items[index].destinationURL = destinationURL
        items[index].status = status
        items[index].message = message
    }
}

struct ConversionItem: Identifiable, Equatable {
    let id = UUID()
    let sourceURL: URL
    var destinationURL: URL?
    var status: ConversionStatus
    var message: String
}

enum ConversionStatus: Equatable {
    case pending
    case converting
    case converted
    case skipped
    case failed

    var title: String {
        switch self {
        case .pending:
            return "Pending"
        case .converting:
            return "Converting"
        case .converted:
            return "Converted"
        case .skipped:
            return "Skipped"
        case .failed:
            return "Failed"
        }
    }

    var symbol: String {
        switch self {
        case .pending:
            return "clock"
        case .converting:
            return "arrow.triangle.2.circlepath"
        case .converted:
            return "checkmark.circle.fill"
        case .skipped:
            return "minus.circle"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
}
