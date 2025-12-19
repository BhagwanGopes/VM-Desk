import XCTest
@testable import VMDesk

final class NetworkConfigTests: XCTestCase {
    func testNetworkDeviceInitialization() {
        let device = NetworkDevice()

        XCTAssertEqual(device.mode, .nat)
        XCTAssertNotNil(device.macAddress)
    }

    func testNetworkDeviceCodable() throws {
        let original = NetworkDevice(mode: .nat)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NetworkDevice.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.mode, original.mode)
        XCTAssertEqual(decoded.macAddress.string, original.macAddress.string)
    }

    func testCreateNATNetworkDevice() throws {
        let device = NetworkDevice(mode: .nat)
        let vzDevice = try NetworkConfigurationManager.createNetworkDevice(from: device)

        XCTAssertNotNil(vzDevice.attachment)
    }

    func testBridgedNetworkThrows() {
        let device = NetworkDevice(mode: .bridged)

        XCTAssertThrowsError(
            try NetworkConfigurationManager.createNetworkDevice(from: device)
        ) { error in
            XCTAssertTrue(error is NetworkConfigurationManager.NetworkError)
        }
    }

    func testNetworkConfiguration() throws {
        var config = NetworkConfiguration()

        XCTAssertEqual(config.devices.count, 1)
        XCTAssertEqual(config.devices.first?.mode, .nat)

        let newDevice = NetworkDevice(mode: .nat)
        config.addDevice(newDevice)
        XCTAssertEqual(config.devices.count, 2)

        let devices = try config.createAllNetworkDevices()
        XCTAssertEqual(devices.count, 2)
    }

    func testRemoveNetworkDevice() {
        var config = NetworkConfiguration()
        let device = NetworkDevice()

        config.addDevice(device)
        XCTAssertEqual(config.devices.count, 2)

        config.removeDevice(id: device.id)
        XCTAssertEqual(config.devices.count, 1)
    }
}
