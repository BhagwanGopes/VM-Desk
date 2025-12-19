import Foundation
import Virtualization

/// Input device configuration
struct InputConfiguration {
    var keyboardEnabled: Bool = true
    var pointingDeviceEnabled: Bool = true

    /// Create keyboard configuration
    func createKeyboard() -> VZUSBKeyboardConfiguration {
        VZUSBKeyboardConfiguration()
    }

    /// Create pointing device (mouse/trackpad)
    func createPointingDevice() -> VZUSBScreenCoordinatePointingDeviceConfiguration {
        VZUSBScreenCoordinatePointingDeviceConfiguration()
    }

    /// Create all input devices
    func createAllInputDevices() -> (keyboard: VZKeyboardConfiguration?, pointing: VZPointingDeviceConfiguration?) {
        let keyboard: VZKeyboardConfiguration? = keyboardEnabled ? createKeyboard() : nil
        let pointing: VZPointingDeviceConfiguration? = pointingDeviceEnabled ? createPointingDevice() : nil
        return (keyboard, pointing)
    }
}
