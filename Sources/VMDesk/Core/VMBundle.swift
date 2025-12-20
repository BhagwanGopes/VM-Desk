import Foundation

/// VM bundle structure for persistent storage
/// Format: VMName.vmdesk/
///   - config.json          (VM configuration)
///   - disk.img             (Primary disk image)
///   - nvram.bin            (UEFI NVRAM, if applicable)
///   - aux_storage/         (Auxiliary storage)
///   - snapshots/           (VM snapshots)
///   - logs/                (Console logs, crash logs)
struct VMBundle {
    let url: URL

    enum BundleError: Error, LocalizedError {
        case invalidBundle
        case configNotFound
        case corruptedConfig

        var errorDescription: String? {
            switch self {
            case .invalidBundle:
                return "Invalid VM bundle structure"
            case .configNotFound:
                return "VM configuration file not found"
            case .corruptedConfig:
                return "VM configuration file is corrupted"
            }
        }
    }

    /// Bundle directory structure
    struct Layout {
        static let configFileName = "config.json"
        static let diskFileName = "disk.img"
        static let nvramFileName = "nvram.bin"
        static let auxStorageDir = "aux_storage"
        static let snapshotsDir = "snapshots"
        static let logsDir = "logs"
        static let consoleLogFileName = "console.log"
    }

    /// Create new VM bundle
    static func create(
        name: String,
        at parentDirectory: URL,
        config: VMConfig
    ) throws -> VMBundle {
        let bundleURL = parentDirectory
            .appendingPathComponent(name)
            .appendingPathExtension("vmdesk")

        // Create bundle directory
        try FileManager.default.createDirectory(
            at: bundleURL,
            withIntermediateDirectories: true
        )

        let bundle = VMBundle(url: bundleURL)

        // Create subdirectories
        try bundle.createDirectoryStructure()

        // Save configuration
        try bundle.saveConfig(config)

        return bundle
    }

    /// Load existing VM bundle
    static func load(from url: URL) throws -> (bundle: VMBundle, config: VMConfig) {
        let bundle = VMBundle(url: url)

        guard bundle.isValid else {
            throw BundleError.invalidBundle
        }

        let config = try bundle.loadConfig()
        return (bundle, config)
    }

    /// Check if bundle structure is valid
    var isValid: Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue else {
            return false
        }

        let configURL = url.appendingPathComponent(Layout.configFileName)
        return FileManager.default.fileExists(atPath: configURL.path)
    }

    /// Create directory structure
    private func createDirectoryStructure() throws {
        let directories = [
            Layout.auxStorageDir,
            Layout.snapshotsDir,
            Layout.logsDir
        ]

        for dir in directories {
            let dirURL = url.appendingPathComponent(dir)
            try FileManager.default.createDirectory(
                at: dirURL,
                withIntermediateDirectories: true
            )
        }
    }

    /// Save VM configuration to bundle
    func saveConfig(_ config: VMConfig) throws {
        let configURL = url.appendingPathComponent(Layout.configFileName)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(config)
        try data.write(to: configURL)
    }

    /// Load VM configuration from bundle
    func loadConfig() throws -> VMConfig {
        let configURL = url.appendingPathComponent(Layout.configFileName)

        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw BundleError.configNotFound
        }

        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            return try decoder.decode(VMConfig.self, from: data)
        } catch {
            throw BundleError.corruptedConfig
        }
    }

    /// Get disk image path
    func diskImagePath() -> URL {
        url.appendingPathComponent(Layout.diskFileName)
    }

    /// Get NVRAM path (for UEFI VMs)
    func nvramPath() -> URL {
        url.appendingPathComponent(Layout.nvramFileName)
    }

    /// Get console log path
    func consoleLogPath() -> URL {
        url
            .appendingPathComponent(Layout.logsDir)
            .appendingPathComponent(Layout.consoleLogFileName)
    }

    /// Get auxiliary storage directory
    func auxStorageDirectory() -> URL {
        url.appendingPathComponent(Layout.auxStorageDir)
    }

    /// Get snapshots directory
    func snapshotsDirectory() -> URL {
        url.appendingPathComponent(Layout.snapshotsDir)
    }

    /// Delete VM bundle
    func delete() throws {
        try FileManager.default.removeItem(at: url)
    }

    /// Get bundle size on disk
    func calculateSize() -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: UInt64 = 0

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += UInt64(fileSize)
        }

        return totalSize
    }
}
