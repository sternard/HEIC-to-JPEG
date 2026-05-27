import HEICtoJPEGCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ConversionViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(summary: viewModel.summaryText, clear: viewModel.clear)

            Divider()

            VStack(spacing: 18) {
                DropZone(
                    isTargeted: viewModel.isDropTargeted,
                    isConverting: viewModel.isConverting
                )
                .onDrop(
                    of: [.fileURL],
                    isTargeted: Binding(
                        get: { viewModel.isDropTargeted },
                        set: { viewModel.setDropTargeted($0) }
                    ),
                    perform: handleDrop
                )

                ConversionList(items: viewModel.items, reveal: viewModel.reveal)
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        Task {
            let urls = await loadFileURLs(from: providers)
            viewModel.convertDroppedURLs(urls)
        }
        return true
    }

    private func loadFileURLs(from providers: [NSItemProvider]) async -> [URL] {
        await withTaskGroup(of: URL?.self) { group in
            for provider in providers {
                group.addTask {
                    await loadFileURL(from: provider)
                }
            }

            var urls: [URL] = []
            for await url in group {
                if let url {
                    urls.append(url)
                }
            }
            return urls
        }
    }

    private func loadFileURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }

                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }
}

private struct HeaderView: View {
    let summary: String
    let clear: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title2)
                .foregroundStyle(.teal)

            VStack(alignment: .leading, spacing: 2) {
                Text("HEIC to JPEG")
                    .font(.title2.weight(.semibold))
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: clear) {
                Label("Clear", systemImage: "trash")
            }
            .disabled(summary == "Ready")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

private struct DropZone: View {
    let isTargeted: Bool
    let isConverting: Bool

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isTargeted ? Color.teal.opacity(0.18) : Color.teal.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: isConverting ? "arrow.triangle.2.circlepath" : "square.and.arrow.down")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.teal)
            }

            VStack(spacing: 5) {
                Text("Drop HEIC files or folders")
                    .font(.title3.weight(.semibold))

                Text("JPEG files are created next to the originals")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color.teal.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.teal : Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
        )
    }
}

private struct ConversionList: View {
    let items: [ConversionItem]
    let reveal: (ConversionItem) -> Void

    var body: some View {
        Group {
            if items.isEmpty {
                Spacer(minLength: 0)
            } else {
                List {
                    ForEach(items) { item in
                        ConversionRow(item: item, reveal: { reveal(item) })
                    }
                }
                .listStyle(.inset)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct ConversionRow: View {
    let item: ConversionItem
    let reveal: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.status.symbol)
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.sourceURL.lastPathComponent)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(item.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(item.status.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)
                .frame(width: 82, alignment: .trailing)

            Button(action: reveal) {
                Label("Reveal", systemImage: "magnifyingglass")
            }
            .labelStyle(.iconOnly)
            .help("Reveal in Finder")
            .disabled(item.status == .pending || item.status == .converting)
        }
        .padding(.vertical, 5)
    }

    private var color: Color {
        switch item.status {
        case .pending, .skipped:
            return .secondary
        case .converting:
            return .teal
        case .converted:
            return .green
        case .failed:
            return .red
        }
    }
}
