import Foundation
import Virtualization
import Network

/// Network configuration modes
enum NetworkMode: String, Codable {
    case nat
    case bridged
    case hostOnly

    var description: String {
        switch self {
        case .nat:
            return "NAT (Network Address Translation)"
        case .bridged:
            return "Bridged (Direct host network access)"
        case .hostOnly:
            return "Host-Only (Isolated network)"
        }
    }
}

/// Network device configuration
struct NetworkDevice: Codable, Identifiable {
    let id: UUID
    var mode: NetworkMode
    var macAddress: VZMACAddress

    init(
        id: UUID = UUID(),
        mode: NetworkMode = .nat,
        macAddress: VZMACAddress = VZMACAddress.randomLocallyAdministered()
    ) {
        self.id = id
        self.mode = mode
        self.macAddress = macAddress
    }

    enum CodingKeys: String, CodingKey {
        case id, mode, macAddressString
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mode = try container.decode(NetworkMode.self, forKey: .mode)

        let macString = try container.decode(String.self, forKey: .macAddressString)
        guard let mac = VZMACAddress(string: macString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .macAddressString,
                in: container,
                debugDescription: "Invalid MAC address format"
            )
        }
        macAddress = mac
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(mode, forKey: .mode)
        try container.encode(macAddress.string, forKey: .macAddressString)
    }
}

/// Network configuration manager
final class NetworkConfigurationManager {
    enum NetworkError: Error, LocalizedError {
        case bridgedNotSupported
        case invalidConfiguration

        var errorDescription: String? {
            switch self {
            case .bridgedNotSupported:
                return "Bridged networking requires restricted entitlements"
            case .invalidConfiguration:
                return "Invalid network configuration"
            }
        }
    }

    /// Create VirtIO network device configuration
    static func createNetworkDevice(
        from config: NetworkDevice
    ) throws -> VZVirtioNetworkDeviceConfiguration {
        let device = VZVirtioNetworkDeviceConfiguration()
        device.macAddress = config.macAddress

        switch config.mode {
        case .nat:
            device.attachment = VZNATNetworkDeviceAttachment()

        case .bridged:
            // Bridged networking requires com.apple.vm.networking entitlement
            // For now, throw error (will implement with privileged helper later)
            throw NetworkError.bridgedNotSupported

        case .hostOnly:
            // Host-only networking (no external network access)
            // Note: Virtualization.framework doesn't have explicit host-only mode
            // We use NAT but could implement custom vmnet bridge later
            device.attachment = VZNATNetworkDeviceAttachment()
        }

        return device
    }

    /// Get available network interfaces for bridged networking
    static func availableInterfaces() -> [String] {
        // This requires elevated privileges and restricted entitlements
        // For MVP, return empty array
        return []
    }
}

/// Multi-network configuration
struct NetworkConfiguration {
    var devices: [NetworkDevice]

    init(devices: [NetworkDevice] = []) {
        self.devices = devices.isEmpty ? [NetworkDevice()] : devices
    }

    /// Create all network device configurations
    func createAllNetworkDevices() throws -> [VZVirtioNetworkDeviceConfiguration] {
        try devices.map { try NetworkConfigurationManager.createNetworkDevice(from: $0) }
    }

    /// Add network device
    mutating func addDevice(_ device: NetworkDevice) {
        devices.append(device)
    }

    /// Remove device by ID
    mutating func removeDevice(id: UUID) {
        devices.removeAll { $0.id == id }
    }
}
