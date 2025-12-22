import SwiftUI
import Virtualization

/// Main window for displaying running VM
struct VMDisplayWindow: View {
    @ObservedObject var vmManager: VMManager
    @State private var isFullScreen = false
    @State private var showingConsole = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text(vmManager.config.name)
                    .font(.headline)

                Spacer()

                // VM State indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                    Text(stateText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Control buttons
                Button(action: pauseResume) {
                    Image(systemName: vmManager.state == .running ? "pause.fill" : "play.fill")
                }
                .disabled(vmManager.state == .stopped)
                .help(vmManager.state == .running ? "Pause VM" : "Resume VM")

                Button(action: stop) {
                    Image(systemName: "stop.fill")
                }
                .disabled(vmManager.state == .stopped)
                .help("Stop VM")

                Button(action: { showingConsole.toggle() }) {
                    Image(systemName: "terminal")
                }
                .help("Toggle Console")

                Button(action: { isFullScreen.toggle() }) {
                    Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                }
                .help("Toggle Full Screen")
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // VM Display
            if let vm = vmManager.virtualMachine,
               let graphicsConfig = getGraphicsConfig() {
                VMDisplayView(virtualMachine: vm, graphicsDevice: graphicsConfig)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("VM Not Running")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    if let error = vmManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            }

            // Console overlay
            if showingConsole {
                Divider()

                ConsoleView(logPath: getConsoleLogPath())
                    .frame(height: 200)
            }
        }
        .frame(
            minWidth: 800,
            idealWidth: 1920,
            minHeight: 600,
            idealHeight: 1080
        )
    }

    // MARK: - Helpers

    private var stateColor: Color {
        switch vmManager.state {
        case .stopped:
            return .gray
        case .starting:
            return .yellow
        case .running:
            return .green
        case .paused:
            return .orange
        case .stopping:
            return .yellow
        case .error:
            return .red
        }
    }

    private var stateText: String {
        switch vmManager.state {
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting..."
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .stopping:
            return "Stopping..."
        case .error:
            return "Error"
        }
    }

    private func pauseResume() {
        Task {
            do {
                if vmManager.state == .running {
                    try await vmManager.pause()
                } else if vmManager.state == .paused {
                    try await vmManager.resume()
                }
            } catch {
                print("Failed to pause/resume: \(error)")
            }
        }
    }

    private func stop() {
        Task {
            do {
                try await vmManager.stop()
            } catch {
                print("Failed to stop VM: \(error)")
            }
        }
    }

    private func getGraphicsConfig() -> VZVirtioGraphicsDeviceConfiguration? {
        // In a real implementation, this would be stored in VMManager
        // For now, create a default config matching what VMConfigurationBuilder creates
        let config = VZVirtioGraphicsDeviceConfiguration()
        config.scanouts = [
            VZVirtioGraphicsScanoutConfiguration(widthInPixels: 1920, heightInPixels: 1080)
        ]
        return config
    }

    private func getConsoleLogPath() -> URL? {
        // Return console log path if available
        // In production, this would come from VMBundle
        return nil
    }
}

/// Simple console view for serial output
struct ConsoleView: View {
    let logPath: URL?
    @State private var logContent = ""
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Console Output")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)

                Button("Clear") {
                    logContent = ""
                }
                .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    Text(logContent.isEmpty ? "No output" : logContent)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .id("bottom")
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: logContent) { _ in
                    if autoScroll {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
        .onAppear {
            loadLog()
        }
    }

    private func loadLog() {
        guard let logPath = logPath else { return }

        if let content = try? String(contentsOf: logPath, encoding: .utf8) {
            logContent = content
        }
    }
}
