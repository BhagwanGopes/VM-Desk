import Foundation
import Virtualization

/// VM configuration model
struct VMConfig: Codable, Identifiable {
    let id: UUID
    var name: String
    var cpuCount: Int
    var memorySize: UInt64
    var diskImagePath: URL
    var cdromImagePath: URL?
    var bootLoaderType: BootLoaderType
    var networkingMode: NetworkingMode
    var isolationMode: IsolationMode

    enum BootLoaderType: String, Codable {
        case linux
        case uefi
    }

    enum NetworkingMode: String, Codable {
        case nat
        case bridged
    }

    enum IsolationMode: String, Codable {
        case isolated
        case unrestricted
    }

    init(
        id: UUID = UUID(),
        name: String,
        cpuCount: Int,
        memorySize: UInt64,
        diskImagePath: URL,
        cdromImagePath: URL? = nil,
        bootLoaderType: BootLoaderType = .linux,
        networkingMode: NetworkingMode = .nat,
        isolationMode: IsolationMode = .isolated
    ) {
        self.id = id
        self.name = name
        self.cpuCount = cpuCount
        self.memorySize = memorySize
        self.diskImagePath = diskImagePath
        self.cdromImagePath = cdromImagePath
        self.bootLoaderType = bootLoaderType
        self.networkingMode = networkingMode
        self.isolationMode = isolationMode
    }
}

/// Converts VMConfig to VZVirtualMachineConfiguration
final class VMConfigurationBuilder {
    enum BuildError: Error {
        case invalidCPUCount
        case invalidMemorySize
        case diskImageNotFound
        case unsupportedConfiguration
    }

    static func build(from config: VMConfig) throws -> VZVirtualMachineConfiguration {
        let vzConfig = VZVirtualMachineConfiguration()

        // CPU configuration
        guard config.cpuCount > 0, config.cpuCount <= VZVirtualMachineConfiguration.maximumAllowedCPUCount else {
            throw BuildError.invalidCPUCount
        }
        vzConfig.cpuCount = config.cpuCount

        // Memory configuration
        guard config.memorySize > 0, config.memorySize <= VZVirtualMachineConfiguration.maximumAllowedMemorySize else {
            throw BuildError.invalidMemorySize
        }
        vzConfig.memorySize = config.memorySize

        // Storage attachment
        guard FileManager.default.fileExists(atPath: config.diskImagePath.path) else {
            throw BuildError.diskImageNotFound
        }

        let diskAttachment = try VZDiskImageStorageDeviceAttachment(
            url: config.diskImagePath,
            readOnly: false
        )
        let blockDevice = VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)

        var storageDevices: [VZStorageDeviceConfiguration] = [blockDevice]

        // CD-ROM attachment (if ISO provided)
        if let cdromPath = config.cdromImagePath {
            if FileManager.default.fileExists(atPath: cdromPath.path) {
                let cdromAttachment = try VZDiskImageStorageDeviceAttachment(
                    url: cdromPath,
                    readOnly: true
                )
                let cdromDevice = VZUSBMassStorageDeviceConfiguration(attachment: cdromAttachment)
                storageDevices.append(cdromDevice)
            }
        }

        vzConfig.storageDevices = storageDevices

        // Boot loader
        switch config.bootLoaderType {
        case .linux:
            vzConfig.bootLoader = VZLinuxBootLoader(kernelURL: config.diskImagePath)
        case .uefi:
            vzConfig.bootLoader = VZEFIBootLoader()
        }

        // Networking
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        switch config.networkingMode {
        case .nat:
            networkDevice.attachment = VZNATNetworkDeviceAttachment()
        case .bridged:
            throw BuildError.unsupportedConfiguration
        }
        vzConfig.networkDevices = [networkDevice]

        // Graphics device
        let graphicsDevice = VZVirtioGraphicsDeviceConfiguration()
        graphicsDevice.scanouts = [
            VZVirtioGraphicsScanoutConfiguration(widthInPixels: 1920, heightInPixels: 1080)
        ]
        vzConfig.graphicsDevices = [graphicsDevice]

        // Validate configuration
        try vzConfig.validate()

        return vzConfig
    }
}
