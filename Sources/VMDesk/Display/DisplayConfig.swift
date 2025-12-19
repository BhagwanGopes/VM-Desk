import Foundation
import Virtualization

/// Display resolution configuration
struct DisplayResolution: Codable, Equatable {
    let width: Int
    let height: Int

    /// Common display resolutions
    static let hd = DisplayResolution(width: 1280, height: 720)
    static let fullHD = DisplayResolution(width: 1920, height: 1080)
    static let quadHD = DisplayResolution(width: 2560, height: 1440)
    static let ultraHD = DisplayResolution(width: 3840, height: 2160)

    var description: String {
        "\(width)×\(height)"
    }
}

/// Graphics device configuration
struct GraphicsDevice: Codable {
    var resolution: DisplayResolution
    var pixelsPerInch: Int

    init(
        resolution: DisplayResolution = .fullHD,
        pixelsPerInch: Int = 144
    ) {
        self.resolution = resolution
        self.pixelsPerInch = pixelsPerInch
    }

    /// Create VirtIO graphics device configuration
    func createGraphicsDevice() -> VZVirtioGraphicsDeviceConfiguration {
        let device = VZVirtioGraphicsDeviceConfiguration()

        let scanout = VZVirtioGraphicsScanoutConfiguration(
            widthInPixels: resolution.width,
            heightInPixels: resolution.height
        )
        device.scanouts = [scanout]

        return device
    }
}

/// Display configuration manager
final class DisplayConfigurationManager {
    /// Create graphics device with custom resolution
    static func createGraphicsDevice(
        width: Int,
        height: Int
    ) -> VZVirtioGraphicsDeviceConfiguration {
        let device = VZVirtioGraphicsDeviceConfiguration()

        let scanout = VZVirtioGraphicsScanoutConfiguration(
            widthInPixels: width,
            heightInPixels: height
        )
        device.scanouts = [scanout]

        return device
    }

    /// Get host display resolution
    static func hostDisplayResolution() -> DisplayResolution? {
        guard let screen = NSScreen.main else { return nil }
        let frame = screen.frame
        return DisplayResolution(
            width: Int(frame.width),
            height: Int(frame.height)
        )
    }

    /// Recommended resolutions based on host display
    static func recommendedResolutions() -> [DisplayResolution] {
        var resolutions: [DisplayResolution] = [
            .hd,
            .fullHD,
            .quadHD
        ]

        // Add 4K if host supports it
        if let host = hostDisplayResolution(), host.width >= 3840 {
            resolutions.append(.ultraHD)
        }

        return resolutions
    }
}
