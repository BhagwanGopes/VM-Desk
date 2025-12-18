import Foundation

/// Disk image format types
enum DiskImageFormat: String, Codable {
    case raw
    case sparseImage
}

/// Disk image metadata and operations
struct DiskImage: Codable, Identifiable {
    let id: UUID
    let path: URL
    let format: DiskImageFormat
    let sizeBytes: UInt64
    let createdAt: Date

    init(
        id: UUID = UUID(),
        path: URL,
        format: DiskImageFormat,
        sizeBytes: UInt64,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.path = path
        self.format = format
        self.sizeBytes = sizeBytes
        self.createdAt = createdAt
    }
}

/// Disk image creation and management utilities
final class DiskImageManager {
    enum DiskError: Error, LocalizedError {
        case invalidSize
        case creationFailed(underlying: Error)
        case fileAlreadyExists
        case unsupportedFormat

        var errorDescription: String? {
            switch self {
            case .invalidSize:
                return "Invalid disk size (must be > 0)"
            case .creationFailed(let error):
                return "Disk creation failed: \(error.localizedDescription)"
            case .fileAlreadyExists:
                return "Disk image already exists at path"
            case .unsupportedFormat:
                return "Unsupported disk format"
            }
        }
    }

    /// Create raw disk image (sparse file)
    static func createRawImage(
        at url: URL,
        sizeBytes: UInt64
    ) throws -> DiskImage {
        guard sizeBytes > 0 else {
            throw DiskError.invalidSize
        }

        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw DiskError.fileAlreadyExists
        }

        do {
            // Create sparse file using ftruncate via FileHandle
            FileManager.default.createFile(atPath: url.path, contents: nil)
            let fileHandle = try FileHandle(forWritingTo: url)
            defer { try? fileHandle.close() }

            try fileHandle.truncate(atOffset: sizeBytes)

            return DiskImage(
                path: url,
                format: .raw,
                sizeBytes: sizeBytes
            )
        } catch {
            // Clean up failed creation
            try? FileManager.default.removeItem(at: url)
            throw DiskError.creationFailed(underlying: error)
        }
    }

    /// Create Apple sparse image (APFS sparse bundle)
    static func createSparseImage(
        at url: URL,
        sizeBytes: UInt64,
        volumeName: String = "VMDisk"
    ) throws -> DiskImage {
        guard sizeBytes > 0 else {
            throw DiskError.invalidSize
        }

        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw DiskError.fileAlreadyExists
        }

        // Calculate size in MB for hdiutil
        let sizeMB = sizeBytes / 1024 / 1024

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = [
            "create",
            "-size", "\(sizeMB)m",
            "-type", "SPARSE",
            "-fs", "APFS",
            "-volname", volumeName,
            url.path
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw DiskError.creationFailed(
                    underlying: NSError(
                        domain: "DiskImageManager",
                        code: Int(process.terminationStatus),
                        userInfo: [NSLocalizedDescriptionKey: errorOutput]
                    )
                )
            }

            return DiskImage(
                path: url,
                format: .sparseImage,
                sizeBytes: sizeBytes
            )
        } catch {
            throw DiskError.creationFailed(underlying: error)
        }
    }

    /// Get actual disk usage (for sparse images)
    static func actualSize(of url: URL) -> UInt64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? UInt64
    }

    /// Resize disk image (raw format only)
    static func resize(
        _ url: URL,
        toSize newSize: UInt64
    ) throws {
        guard newSize > 0 else {
            throw DiskError.invalidSize
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DiskError.creationFailed(
                underlying: NSError(
                    domain: "DiskImageManager",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "File not found"]
                )
            )
        }

        do {
            let fileHandle = try FileHandle(forWritingTo: url)
            defer { try? fileHandle.close() }

            try fileHandle.truncate(atOffset: newSize)
        } catch {
            throw DiskError.creationFailed(underlying: error)
        }
    }

    /// Delete disk image
    static func delete(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
