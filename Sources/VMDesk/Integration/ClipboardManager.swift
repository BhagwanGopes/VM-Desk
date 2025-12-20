import Foundation
import AppKit

/// Clipboard integration between host and guest
/// Note: Full clipboard integration requires guest agent
/// This provides the host-side infrastructure
final class ClipboardManager {
    private var clipboardMonitor: Timer?
    private var lastClipboardChangeCount: Int = 0

    enum ClipboardError: Error, LocalizedError {
        case notImplemented
        case guestAgentRequired

        var errorDescription: String? {
            switch self {
            case .notImplemented:
                return "Clipboard integration not yet implemented"
            case .guestAgentRequired:
                return "Clipboard sync requires guest agent installation"
            }
        }
    }

    /// Start monitoring host clipboard for changes
    func startMonitoring(interval: TimeInterval = 1.0, onChange: @escaping (NSPasteboard) -> Void) {
        let pasteboard = NSPasteboard.general
        lastClipboardChangeCount = pasteboard.changeCount

        clipboardMonitor = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let currentCount = pasteboard.changeCount
            if currentCount != self.lastClipboardChangeCount {
                self.lastClipboardChangeCount = currentCount
                onChange(pasteboard)
            }
        }
    }

    /// Stop monitoring clipboard
    func stopMonitoring() {
        clipboardMonitor?.invalidate()
        clipboardMonitor = nil
    }

    /// Get text from host clipboard
    func getHostClipboardText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    /// Set text to host clipboard
    func setHostClipboardText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Send clipboard data to guest
    /// Note: Requires guest agent with virtio-serial channel
    func sendToGuest(_ data: Data) throws {
        // TODO: Implement virtio-serial communication with guest agent
        throw ClipboardError.guestAgentRequired
    }

    /// Receive clipboard data from guest
    /// Note: Requires guest agent with virtio-serial channel
    func receiveFromGuest() throws -> Data {
        // TODO: Implement virtio-serial communication with guest agent
        throw ClipboardError.guestAgentRequired
    }
}

/// Clipboard synchronization mode
enum ClipboardSyncMode: String, Codable {
    case disabled
    case hostToGuest    // One-way: Host → Guest
    case guestToHost    // One-way: Guest → Host
    case bidirectional  // Two-way sync

    var description: String {
        switch self {
        case .disabled:
            return "Disabled"
        case .hostToGuest:
            return "Host → Guest only"
        case .guestToHost:
            return "Guest → Host only"
        case .bidirectional:
            return "Bidirectional sync"
        }
    }
}

/// Clipboard configuration
struct ClipboardConfiguration: Codable {
    var syncMode: ClipboardSyncMode = .disabled
    var autoSync: Bool = false

    var isEnabled: Bool {
        syncMode != .disabled
    }
}
