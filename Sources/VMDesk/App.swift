import SwiftUI
import Virtualization
import AppKit
import UniformTypeIdentifiers

// MARK: - ISO File Type Extension

extension UTType {
    static let iso = UTType(filenameExtension: "iso")!
}

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
    @State private var showingCreationWizard = false

    var body: some View {
        navigationView
            .frame(minWidth: 800, minHeight: 600)
            .sheet(isPresented: $showingCreationWizard) {
                VMCreationWizard(library: library)
            }
    }

    private var navigationView: some View {
        NavigationSplitView {
            vmListView
        } detail: {
            detailView
        }
    }

    private var vmListView: some View {
        List(library.vms, selection: $selectedVM) { vm in
            VMListRow(vm: vm, isRunning: library.runningVMs[vm.id] != nil)
                .tag(vm.id)
        }
        .navigationTitle("Virtual Machines")
        .toolbar {
            toolbarContent
        }
    }

    private var detailView: some View {
        Group {
            if let selectedVM = selectedVM,
               let vm = library.vms.first(where: { $0.id == selectedVM }) {
                VMDetailView(vm: vm, library: library)
            } else {
                emptyStateView
            }
        }
    }

    private var emptyStateView: some View {
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button(action: { showingCreationWizard = true }) {
                Label("Add VM", systemImage: "plus")
            }
        }
    }
}

/// VM list row view
struct VMListRow: View {
    let vm: VMConfig
    let isRunning: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(vm.name)
                .font(.headline)
            HStack {
                Text("\(vm.cpuCount) CPUs, \(vm.memorySize / 1024 / 1024 / 1024) GB RAM")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if isRunning {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

/// VM detail view with start/stop controls
struct VMDetailView: View {
    let vm: VMConfig
    @ObservedObject var library: VMLibrary
    @State private var showingError = false

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
                if let cdromPath = vm.cdromImagePath {
                    DetailRow(label: "CD-ROM", value: cdromPath.lastPathComponent)
                }
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
                        do {
                            try await library.startVM(id: vm.id)
                        } catch {
                            showingError = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .alert("VM Error", isPresented: $showingError, presenting: library.lastError) { _ in
            Button("OK") {
                showingError = false
                library.lastError = nil
            }
        } message: { error in
            Text(error)
        }
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
    @Published var lastError: String?

    func addVM(_ config: VMConfig) {
        vms.append(config)
    }

    func startVM(id: UUID) async throws {
        guard let config = vms.first(where: { $0.id == id }) else { return }
        guard runningVMs[id] == nil else { return }

        lastError = nil
        let manager = VMManager(config: config)
        runningVMs[id] = manager

        do {
            try await manager.start()
        } catch {
            lastError = manager.errorMessage ?? error.localizedDescription
            runningVMs.removeValue(forKey: id)
            throw error
        }
    }

    func stopVM(id: UUID) async throws {
        guard let manager = runningVMs[id] else { return }

        do {
            try await manager.stop()
            runningVMs.removeValue(forKey: id)
        } catch {
            lastError = manager.errorMessage ?? error.localizedDescription
            throw error
        }
    }
}
