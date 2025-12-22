import Foundation
import AppKit
import Virtualization

/// Handles input events and routes them to the VM
@MainActor
final class InputHandler: Sendable {
    static let shared = InputHandler()

    private init() {}

    // MARK: - Keyboard Events

    func handleKeyEvent(_ event: NSEvent, for vm: VZVirtualMachine?) {
        guard let vm = vm else { return }

        // Get keyboard configuration from VM
        guard let keyboardConfig = getKeyboardConfiguration(from: vm) else {
            return
        }

        // Note: VZVirtualMachine doesn't expose direct keyboard input API
        // Input is handled through VZVirtioGraphicsDevice automatically
        // This is a placeholder for future custom keyboard handling

        // For now, NSView's built-in keyboard handling will forward to the VM
    }

    // MARK: - Mouse Events

    func handleMouseEvent(_ event: NSEvent, for vm: VZVirtualMachine?) {
        guard let vm = vm else { return }

        // Get pointing device configuration
        guard let pointingConfig = getPointingDeviceConfiguration(from: vm) else {
            return
        }

        // Note: Similar to keyboard, mouse input is handled automatically
        // through VZVirtioGraphicsDevice's screen coordinate pointing device

        // Calculate relative position within view
        // This would be implemented with actual VirtIO input APIs
    }

    // MARK: - Scroll Events

    func handleScrollEvent(_ event: NSEvent, for vm: VZVirtualMachine?) {
        guard let vm = vm else { return }

        // Handle scroll wheel events
        // Note: Virtualization.framework handles this through pointing device
    }

    // MARK: - Configuration Helpers

    private func getKeyboardConfiguration(from vm: VZVirtualMachine) -> VZKeyboardConfiguration? {
        // In production, this would query the VM's keyboard configuration
        // For now, return nil as the framework handles this automatically
        return nil
    }

    private func getPointingDeviceConfiguration(from vm: VZVirtualMachine) -> VZPointingDeviceConfiguration? {
        // In production, this would query the VM's pointing device configuration
        return nil
    }

    // MARK: - Key Code Conversion

    /// Convert NSEvent key code to VirtIO scancode
    /// Note: This is a simplified mapping - full implementation would need complete scancode table
    private func convertKeyCode(_ keyCode: UInt16) -> UInt32 {
        // USB HID to PS/2 scancode conversion
        // This is a placeholder - actual implementation requires full mapping table
        return UInt32(keyCode)
    }

    /// Get modifier flags from NSEvent
    private func getModifierFlags(_ event: NSEvent) -> VZKeyboardModifierFlags {
        var flags: VZKeyboardModifierFlags = []

        if event.modifierFlags.contains(.shift) {
            // flags.insert(.shift)
        }
        if event.modifierFlags.contains(.control) {
            // flags.insert(.control)
        }
        if event.modifierFlags.contains(.option) {
            // flags.insert(.option)
        }
        if event.modifierFlags.contains(.command) {
            // flags.insert(.command)
        }

        return flags
    }
}

// MARK: - VZKeyboardModifierFlags

/// Modifier flags for keyboard events
/// Note: This is a placeholder - actual VZKeyboardModifierFlags from Virtualization.framework
struct VZKeyboardModifierFlags: OptionSet {
    let rawValue: UInt

    static let shift = VZKeyboardModifierFlags(rawValue: 1 << 0)
    static let control = VZKeyboardModifierFlags(rawValue: 1 << 1)
    static let option = VZKeyboardModifierFlags(rawValue: 1 << 2)
    static let command = VZKeyboardModifierFlags(rawValue: 1 << 3)
}
