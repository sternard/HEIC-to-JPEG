import Foundation
import XCTest
@testable import HEICtoJPEGCore

final class HEICFileLocatorTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        temporaryDirectory = nil
    }

    func testHEICDetectionIsCaseInsensitive() {
        XCTAssertTrue(HEICFileLocator.isHEICFile(URL(fileURLWithPath: "/tmp/Photo.HEIC")))
        XCTAssertTrue(HEICFileLocator.isHEICFile(URL(fileURLWithPath: "/tmp/Photo.heics")))
        XCTAssertFalse(HEICFileLocator.isHEICFile(URL(fileURLWithPath: "/tmp/Photo.jpg")))
    }

    func testFolderExpansionFindsNestedHEICFiles() throws {
        let nestedDirectory = temporaryDirectory.appendingPathComponent("Nested", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedDirectory, withIntermediateDirectories: true)

        let firstHEIC = temporaryDirectory.appendingPathComponent("First.heic")
        let secondHEIC = nestedDirectory.appendingPathComponent("Second.HEIC")
        let ignoredJPEG = nestedDirectory.appendingPathComponent("Ignored.jpg")

        FileManager.default.createFile(atPath: firstHEIC.path, contents: Data())
        FileManager.default.createFile(atPath: secondHEIC.path, contents: Data())
        FileManager.default.createFile(atPath: ignoredJPEG.path, contents: Data())

        let results = Set(HEICFileLocator.heicFiles(in: temporaryDirectory))

        XCTAssertEqual(results, Set([firstHEIC, secondHEIC]))
    }

    func testAvailableJPEGURLAvoidsExistingFiles() throws {
        let sourceURL = temporaryDirectory.appendingPathComponent("Photo.heic")
        let firstJPEG = temporaryDirectory.appendingPathComponent("Photo.jpg")
        let secondJPEG = temporaryDirectory.appendingPathComponent("Photo 2.jpg")

        FileManager.default.createFile(atPath: sourceURL.path, contents: Data())
        FileManager.default.createFile(atPath: firstJPEG.path, contents: Data())

        XCTAssertEqual(HEICFileLocator.availableJPEGURL(for: sourceURL), secondJPEG)
    }
}
