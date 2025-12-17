import XCTest
@testable import VMDesk

final class VMConfigTests: XCTestCase {
    func testVMConfigInitialization() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.img")

        let config = VMConfig(
            name: "Test VM",
            cpuCount: 4,
            memorySize: 4 * 1024 * 1024 * 1024,
            diskImagePath: tempURL
        )

        XCTAssertEqual(config.name, "Test VM")
        XCTAssertEqual(config.cpuCount, 4)
        XCTAssertEqual(config.memorySize, 4 * 1024 * 1024 * 1024)
        XCTAssertEqual(config.diskImagePath, tempURL)
        XCTAssertEqual(config.bootLoaderType, .linux)
        XCTAssertEqual(config.networkingMode, .nat)
        XCTAssertEqual(config.isolationMode, .isolated)
    }

    func testVMConfigCodable() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.img")
        let original = VMConfig(
            name: "Test VM",
            cpuCount: 2,
            memorySize: 2 * 1024 * 1024 * 1024,
            diskImagePath: tempURL
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(VMConfig.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.cpuCount, original.cpuCount)
        XCTAssertEqual(decoded.memorySize, original.memorySize)
    }
}
