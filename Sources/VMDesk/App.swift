import SwiftUI
import Virtualization

@main
struct VMDeskApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New VM...") {
                    // TODO: Open VM creation wizard
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}

struct ContentView: View {
    @State private var vms: [VMConfiguration] = []

    var body: some View {
        NavigationSplitView {
            List(vms) { vm in
                VStack(alignment: .leading) {
                    Text(vm.name)
                        .font(.headline)
                    Text("\(vm.cpuCount) CPUs, \(vm.memorySize / 1024 / 1024 / 1024) GB RAM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Virtual Machines")
            .toolbar {
                Button(action: createVM) {
                    Label("Add VM", systemImage: "plus")
                }
            }
        } detail: {
            if vms.isEmpty {
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
            } else {
                Text("VM Details")
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func createVM() {
        // Placeholder for VM creation
        let newVM = VMConfiguration(
            id: UUID(),
            name: "Test VM",
            cpuCount: 4,
            memorySize: 4 * 1024 * 1024 * 1024
        )
        vms.append(newVM)
    }
}

struct VMConfiguration: Identifiable {
    let id: UUID
    let name: String
    let cpuCount: Int
    let memorySize: UInt64
}
