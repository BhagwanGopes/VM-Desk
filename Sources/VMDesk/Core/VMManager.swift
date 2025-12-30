import Foundation
import Virtualization

/// Manages VM lifecycle (start, stop, pause, resume)
@MainActor
final class VMManager: NSObject, ObservableObject {
    @Published private(set) var state: VMState = .stopped
    @Published private(set) var errorMessage: String?

    private(set) var virtualMachine: VZVirtualMachine?
    let config: VMConfig

    enum VMState {
        case stopped
        case starting
        case running
        case paused
        case stopping
        case error
    }

    enum VMError: Error, LocalizedError {
        case configurationFailed(underlying: Error)
        case startFailed(underlying: Error)
        case stopFailed(underlying: Error)
        case invalidState(String)

        var errorDescription: String? {
            switch self {
            case .configurationFailed(let error):
                return "Configuration failed: \(error.localizedDescription)"
            case .startFailed(let error):
                return "Start failed: \(error.localizedDescription)"
            case .stopFailed(let error):
                return "Stop failed: \(error.localizedDescription)"
            case .invalidState(let message):
                return "Invalid state: \(message)"
            }
        }
    }

    init(config: VMConfig) {
        self.config = config
        super.init()
    }

    func start() async throws {
        guard state == .stopped else {
            throw VMError.invalidState("VM must be stopped to start")
        }

        state = .starting
        errorMessage = nil

        do {
            // Build VM configuration
            let vzConfig = try VMConfigurationBuilder.build(from: config)

            // Validate before creating VM
            try vzConfig.validate()

            // Create and configure VM
            let vm = VZVirtualMachine(configuration: vzConfig)
            vm.delegate = self
            self.virtualMachine = vm

            // Start VM
            try await vm.start()
            state = .running
        } catch let error as VMConfigurationBuilder.BuildError {
            state = .error
            errorMessage = formatBuildError(error)
            throw VMError.startFailed(underlying: error)
        } catch {
            state = .error
            errorMessage = "VM failed to start: \(error.localizedDescription)"
            throw VMError.startFailed(underlying: error)
        }
    }

    private func formatBuildError(_ error: VMConfigurationBuilder.BuildError) -> String {
        switch error {
        case .invalidCPUCount:
            return "Invalid CPU count. Must be between 1 and \(VZVirtualMachineConfiguration.maximumAllowedCPUCount)"
        case .invalidMemorySize:
            return "Invalid memory size. Must be between 1 GB and \(VZVirtualMachineConfiguration.maximumAllowedMemorySize / 1024 / 1024 / 1024) GB"
        case .diskImageNotFound:
            return "Disk image not found. Please check the disk path."
        case .unsupportedConfiguration:
            return "Unsupported configuration. Some features are not available on this system."
        }
    }

    func stop() async throws {
        guard let vm = virtualMachine, state == .running else {
            throw VMError.invalidState("VM must be running to stop")
        }

        state = .stopping

        do {
            try await vm.stop()
            state = .stopped
            virtualMachine = nil
        } catch {
            state = .error
            errorMessage = error.localizedDescription
            throw VMError.stopFailed(underlying: error)
        }
    }

    func pause() async throws {
        guard let vm = virtualMachine, state == .running, vm.canRequestStop else {
            throw VMError.invalidState("VM must be running to pause")
        }

        try await vm.pause()
        state = .paused
    }

    func resume() async throws {
        guard let vm = virtualMachine, state == .paused else {
            throw VMError.invalidState("VM must be paused to resume")
        }

        try await vm.resume()
        state = .running
    }
}

// MARK: - VZVirtualMachineDelegate

extension VMManager: VZVirtualMachineDelegate {
    nonisolated func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        Task { @MainActor in
            state = .stopped
            self.virtualMachine = nil
        }
    }

    nonisolated func virtualMachine(
        _ virtualMachine: VZVirtualMachine,
        didStopWithError error: Error
    ) {
        Task { @MainActor in
            state = .error
            errorMessage = error.localizedDescription
        }
    }
}
