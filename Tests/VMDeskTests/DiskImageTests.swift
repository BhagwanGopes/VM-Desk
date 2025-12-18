import XCTest
@testable import VMDesk

final class DiskImageTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testCreateRawDiskImage() throws {
        let diskPath = tempDirectory.appendingPathComponent("test.img")
        let sizeBytes: UInt64 = 10 * 1024 * 1024 // 10 MB

        let disk = try DiskImageManager.createRawImage(
            at: diskPath,
            sizeBytes: sizeBytes
        )

        XCTAssertEqual(disk.format, .raw)
        XCTAssertEqual(disk.sizeBytes, sizeBytes)
        XCTAssertTrue(FileManager.default.fileExists(atPath: diskPath.path))

        // Verify file size
        let attributes = try FileManager.default.attributesOfItem(atPath: diskPath.path)
        let actualSize = attributes[.size] as? UInt64
        XCTAssertEqual(actualSize, sizeBytes)
    }

    func testCreateRawDiskImageFailsIfExists() throws {
        let diskPath = tempDirectory.appendingPathComponent("existing.img")

        // Create first disk
        _ = try DiskImageManager.createRawImage(at: diskPath, sizeBytes: 1024 * 1024)

        // Attempt to create again should fail
        XCTAssertThrowsError(
            try DiskImageManager.createRawImage(at: diskPath, sizeBytes: 1024 * 1024)
        ) { error in
            XCTAssertTrue(error is DiskImageManager.DiskError)
        }
    }

    func testCreateInvalidSizeFails() {
        let diskPath = tempDirectory.appendingPathComponent("invalid.img")

        XCTAssertThrowsError(
            try DiskImageManager.createRawImage(at: diskPath, sizeBytes: 0)
        ) { error in
            guard case DiskImageManager.DiskError.invalidSize = error else {
                XCTFail("Expected invalidSize error")
                return
            }
        }
    }

    func testResizeDiskImage() throws {
        let diskPath = tempDirectory.appendingPathComponent("resize.img")
        let initialSize: UInt64 = 10 * 1024 * 1024
        let newSize: UInt64 = 20 * 1024 * 1024

        // Create disk
        _ = try DiskImageManager.createRawImage(at: diskPath, sizeBytes: initialSize)

        // Resize
        try DiskImageManager.resize(diskPath, toSize: newSize)

        // Verify new size
        let attributes = try FileManager.default.attributesOfItem(atPath: diskPath.path)
        let actualSize = attributes[.size] as? UInt64
        XCTAssertEqual(actualSize, newSize)
    }

    func testDeleteDiskImage() throws {
        let diskPath = tempDirectory.appendingPathComponent("delete.img")

        // Create disk
        _ = try DiskImageManager.createRawImage(at: diskPath, sizeBytes: 1024 * 1024)
        XCTAssertTrue(FileManager.default.fileExists(atPath: diskPath.path))

        // Delete
        try DiskImageManager.delete(at: diskPath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: diskPath.path))
    }

    func testActualSize() throws {
        let diskPath = tempDirectory.appendingPathComponent("actual.img")
        let sizeBytes: UInt64 = 5 * 1024 * 1024

        _ = try DiskImageManager.createRawImage(at: diskPath, sizeBytes: sizeBytes)

        let actualSize = DiskImageManager.actualSize(of: diskPath)
        XCTAssertEqual(actualSize, sizeBytes)
    }

    func testActualSizeForNonexistentFile() {
        let nonexistentPath = tempDirectory.appendingPathComponent("nonexistent.img")
        let actualSize = DiskImageManager.actualSize(of: nonexistentPath)
        XCTAssertNil(actualSize)
    }
}
