import Foundation

public enum HEICFileLocator {
    public static let heicExtensions: Set<String> = ["heic", "heics"]

    public static func isHEICFile(_ url: URL) -> Bool {
        guard url.isFileURL else {
            return false
        }

        return heicExtensions.contains(url.pathExtension.lowercased())
    }

    public static func heicFiles(in droppedURLs: [URL], fileManager: FileManager = .default) -> [URL] {
        droppedURLs.flatMap { url in
            heicFiles(in: url, fileManager: fileManager)
        }
    }

    public static func heicFiles(in url: URL, fileManager: FileManager = .default) -> [URL] {
        guard url.isFileURL else {
            return []
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return isHEICFile(url) ? [url] : []
        }

        if !isDirectory.boolValue {
            return isHEICFile(url) ? [url] : []
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item in
            guard let fileURL = item as? URL else {
                return nil
            }

            return isHEICFile(fileURL) ? fileURL : nil
        }
    }

    public static func availableJPEGURL(for sourceURL: URL, fileManager: FileManager = .default) -> URL {
        let baseURL = sourceURL.deletingPathExtension()
        let firstCandidate = baseURL.appendingPathExtension("jpg")

        guard fileManager.fileExists(atPath: firstCandidate.path) else {
            return firstCandidate
        }

        for suffix in 2... {
            let candidate = baseURL
                .deletingLastPathComponent()
                .appendingPathComponent("\(baseURL.lastPathComponent) \(suffix)")
                .appendingPathExtension("jpg")

            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return firstCandidate
    }
}
