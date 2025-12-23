import SwiftUI
import Virtualization

@main
struct VMDeskApp: App {
    @StateObject private var vmLibrary = VMLibrary()

    var body: some Scene {
        WindowGroup {
            ContentView(library: vmLibrary)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New VM...") {
                    // TODO: Open VM creation wizard
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        // Display window for running VM
        WindowGroup("VM Display", for: UUID.self) { $vmID in
            if let vmID = vmID,
               let manager = vmLibrary.runningVMs[vmID] {
                VMDisplayWindow(vmManager: manager)
            } else {
                VStack {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("VM Not Found")
                        .font(.title2)
                }
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var library: VMLibrary
    @State private var selectedVM: UUID?

    var body: some View {
        NavigationSplitView {
            List(library.vms, selection: $selectedVM) { vm in
                VStack(alignment: .leading) {
                    Text(vm.name)
                        .font(.headline)
                    HStack {
                        Text("\(vm.cpuCount) CPUs, \(vm.memorySize / 1024 / 1024 / 1024) GB RAM")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if library.runningVMs[vm.id] != nil {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .tag(vm.id)
            }
            .navigationTitle("Virtual Machines")
            .toolbar {
                Button(action: createTestVM) {
                    Label("Add VM", systemImage: "plus")
                }
            }
        } detail: {
            if let selectedVM = selectedVM,
               let vm = library.vms.first(where: { $0.id == selectedVM }) {
                VMDetailView(vm: vm, library: library)
            } else {
                VStack {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("No VM Selected")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Create a new virtual machine to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func createTestVM() {
        // Create a test VM config
        // TODO: Replace with proper VM creation wizard
        let diskPath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).img")

        let config = VMConfig(
            name: "Test VM \(library.vms.count + 1)",
            cpuCount: 2,
            memorySize: 2 * 1024 * 1024 * 1024,
            diskImagePath: diskPath
        )

        library.addVM(config)
    }
}

/// VM detail view with start/stop controls
struct VMDetailView: View {
    let vm: VMConfig
    @ObservedObject var library: VMLibrary

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 80))
                .foregroundColor(.secondary)

            Text(vm.name)
                .font(.title)

            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "CPU", value: "\(vm.cpuCount) cores")
                DetailRow(label: "Memory", value: "\(vm.memorySize / 1024 / 1024 / 1024) GB")
                DetailRow(label: "Disk", value: vm.diskImagePath.lastPathComponent)
                DetailRow(label: "Network", value: vm.networkingMode.rawValue.uppercased())
                DetailRow(label: "Mode", value: vm.isolationMode.rawValue.capitalized)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            if let manager = library.runningVMs[vm.id] {
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 12, height: 12)
                        Text("Running")
                            .font(.headline)
                    }

                    Button("Stop VM") {
                        Task {
                            try? await library.stopVM(id: vm.id)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                Button("Start VM") {
                    Task {
                        try? await library.startVM(id: vm.id)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

/// VM library managing all VMs
@MainActor
final class VMLibrary: ObservableObject {
    @Published var vms: [VMConfig] = []
    @Published var runningVMs: [UUID: VMManager] = [:]

    func addVM(_ config: VMConfig) {
        vms.append(config)
    }

    func startVM(id: UUID) async throws {
        guard let config = vms.first(where: { $0.id == id }) else { return }
        guard runningVMs[id] == nil else { return }

        let manager = VMManager(config: config)
        runningVMs[id] = manager

        do {
            try await manager.start()
        } catch {
            runningVMs.removeValue(forKey: id)
            throw error
        }
    }

    func stopVM(id: UUID) async throws {
        guard let manager = runningVMs[id] else { return }

        try await manager.stop()
        runningVMs.removeValue(forKey: id)
    }
}
