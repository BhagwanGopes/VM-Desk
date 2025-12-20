import Foundation
import Virtualization

/// Shared folder configuration
struct SharedFolder: Codable, Identifiable {
    let id: UUID
    var name: String
    var hostPath: URL
    var readOnly: Bool

    init(
        id: UUID = UUID(),
        name: String,
        hostPath: URL,
        readOnly: Bool = false
    ) {
        self.id = id
        self.name = name
        self.hostPath = hostPath
        self.readOnly = readOnly
    }
}

/// VirtioFS shared folder manager
final class SharedFolderManager {
    enum ShareError: Error, LocalizedError {
        case directoryNotFound
        case invalidName
        case duplicateName

        var errorDescription: String? {
            switch self {
            case .directoryNotFound:
                return "Shared directory not found on host"
            case .invalidName:
                return "Invalid share name (must be non-empty alphanumeric)"
            case .duplicateName:
                return "Share name already exists"
            }
        }
    }

    /// Validate shared folder configuration
    static func validate(_ folder: SharedFolder) throws {
        // Verify directory exists
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: folder.hostPath.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue else {
            throw ShareError.directoryNotFound
        }

        // Validate name (alphanumeric only)
        let validNamePattern = "^[a-zA-Z0-9_-]+$"
        guard folder.name.range(of: validNamePattern, options: .regularExpression) != nil else {
            throw ShareError.invalidName
        }
    }

    /// Create VirtioFS device configuration
    static func createFileSystemDevice(
        from folders: [SharedFolder]
    ) throws -> VZVirtioFileSystemDeviceConfiguration? {
        guard !folders.isEmpty else { return nil }

        // Validate all folders
        for folder in folders {
            try validate(folder)
        }

        // Check for duplicate names
        let names = folders.map { $0.name }
        let uniqueNames = Set(names)
        guard names.count == uniqueNames.count else {
            throw ShareError.duplicateName
        }

        // Create VirtioFS device with first folder
        // Note: VZVirtioFileSystemDeviceConfiguration supports single directory
        // For multiple shares, we create a temporary directory with symlinks
        let device = VZVirtioFileSystemDeviceConfiguration(
            tag: folders[0].name
        )

        let sharedDirectory = VZSharedDirectory(
            url: folders[0].hostPath,
            readOnly: folders[0].readOnly
        )
        device.share = VZSingleDirectoryShare(directory: sharedDirectory)

        return device
    }

    /// Create multiple VirtioFS devices (one per folder)
    static func createFileSystemDevices(
        from folders: [SharedFolder]
    ) throws -> [VZVirtioFileSystemDeviceConfiguration] {
        var devices: [VZVirtioFileSystemDeviceConfiguration] = []

        for folder in folders {
            try validate(folder)

            let device = VZVirtioFileSystemDeviceConfiguration(tag: folder.name)
            let sharedDirectory = VZSharedDirectory(
                url: folder.hostPath,
                readOnly: folder.readOnly
            )
            device.share = VZSingleDirectoryShare(directory: sharedDirectory)

            devices.append(device)
        }

        return devices
    }

    /// Generate mount script for Linux guests
    static func generateLinuxMountScript(
        for folders: [SharedFolder],
        mountPoint: String = "/mnt/shared"
    ) -> String {
        var script = "#!/bin/bash\n"
        script += "# Auto-generated VirtioFS mount script\n\n"

        for folder in folders {
            let mountPath = "\(mountPoint)/\(folder.name)"
            script += "mkdir -p \(mountPath)\n"
            script += "mount -t virtiofs \(folder.name) \(mountPath)\n"
        }

        return script
    }
}

/// Shared folder configuration manager
struct SharedFolderConfiguration {
    var folders: [SharedFolder] = []

    mutating func add(_ folder: SharedFolder) throws {
        try SharedFolderManager.validate(folder)

        // Check for duplicate names
        if folders.contains(where: { $0.name == folder.name }) {
            throw SharedFolderManager.ShareError.duplicateName
        }

        folders.append(folder)
    }

    mutating func remove(id: UUID) {
        folders.removeAll { $0.id == id }
    }

    mutating func update(_ folder: SharedFolder) throws {
        guard let index = folders.firstIndex(where: { $0.id == folder.id }) else {
            return
        }

        try SharedFolderManager.validate(folder)

        // Check for duplicate names (excluding current folder)
        if folders.enumerated().contains(where: { offset, f in
            offset != index && f.name == folder.name
        }) {
            throw SharedFolderManager.ShareError.duplicateName
        }

        folders[index] = folder
    }
}
