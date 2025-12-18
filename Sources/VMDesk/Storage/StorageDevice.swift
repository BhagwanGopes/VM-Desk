import Foundation
import Virtualization

/// VirtIO block device configuration wrapper
struct StorageDevice {
    let diskImage: DiskImage
    let readOnly: Bool

    enum StorageError: Error, LocalizedError {
        case diskImageNotFound
        case attachmentFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .diskImageNotFound:
                return "Disk image file not found"
            case .attachmentFailed(let error):
                return "Storage attachment failed: \(error.localizedDescription)"
            }
        }
    }

    /// Create VirtIO block device configuration
    func createBlockDevice() throws -> VZVirtioBlockDeviceConfiguration {
        guard FileManager.default.fileExists(atPath: diskImage.path.path) else {
            throw StorageError.diskImageNotFound
        }

        do {
            let attachment = try VZDiskImageStorageDeviceAttachment(
                url: diskImage.path,
                readOnly: readOnly
            )

            let blockDevice = VZVirtioBlockDeviceConfiguration(attachment: attachment)
            return blockDevice
        } catch {
            throw StorageError.attachmentFailed(underlying: error)
        }
    }
}

/// Multi-disk storage configuration
struct StorageConfiguration {
    var bootDisk: StorageDevice
    var additionalDisks: [StorageDevice] = []

    /// Create all block device configurations
    func createAllBlockDevices() throws -> [VZVirtioBlockDeviceConfiguration] {
        var devices: [VZVirtioBlockDeviceConfiguration] = []

        // Boot disk first
        devices.append(try bootDisk.createBlockDevice())

        // Additional disks
        for disk in additionalDisks {
            devices.append(try disk.createBlockDevice())
        }

        return devices
    }

    /// Add additional disk
    mutating func addDisk(_ disk: StorageDevice) {
        additionalDisks.append(disk)
    }

    /// Remove disk by index
    mutating func removeDisk(at index: Int) {
        guard index >= 0 && index < additionalDisks.count else { return }
        additionalDisks.remove(at: index)
    }
}
