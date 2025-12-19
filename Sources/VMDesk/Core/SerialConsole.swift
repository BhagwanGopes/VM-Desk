import Foundation
import Virtualization

/// Serial console for VM debugging and kernel output
final class SerialConsole {
    private var outputHandle: FileHandle?
    private let logPath: URL?

    init(logPath: URL? = nil) {
        self.logPath = logPath

        if let logPath = logPath {
            // Create log file if it doesn't exist
            FileManager.default.createFile(atPath: logPath.path, contents: nil)
            self.outputHandle = try? FileHandle(forWritingTo: logPath)
        }
    }

    deinit {
        try? outputHandle?.close()
    }

    /// Create VirtIO console device configuration
    func createConsoleDevice() -> VZVirtioConsoleDeviceConfiguration {
        let console = VZVirtioConsoleDeviceConfiguration()

        let port = VZVirtioConsolePortConfiguration()
        port.name = "console"
        port.attachment = createAttachment()

        console.ports[0] = port
        return console
    }

    /// Create file handle attachment for console output
    private func createAttachment() -> VZFileHandleSerialPortAttachment {
        if let outputHandle = outputHandle {
            // Log to file
            return VZFileHandleSerialPortAttachment(
                fileHandleForReading: nil,
                fileHandleForWriting: outputHandle
            )
        } else {
            // Log to stdout
            return VZFileHandleSerialPortAttachment(
                fileHandleForReading: nil,
                fileHandleForWriting: FileHandle.standardOutput
            )
        }
    }

    /// Clear log file
    func clearLog() {
        guard let logPath = logPath else { return }

        try? outputHandle?.close()
        try? FileManager.default.removeItem(at: logPath)
        FileManager.default.createFile(atPath: logPath.path, contents: nil)
        outputHandle = try? FileHandle(forWritingTo: logPath)
    }

    /// Read log file contents
    func readLog() -> String? {
        guard let logPath = logPath else { return nil }
        return try? String(contentsOf: logPath, encoding: .utf8)
    }
}
