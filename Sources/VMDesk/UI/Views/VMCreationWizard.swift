import SwiftUI
import UniformTypeIdentifiers

/// VM creation wizard with step-by-step configuration
struct VMCreationWizard: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var library: VMLibrary

    @State private var vmName: String = ""
    @State private var cpuCount: Int = 2
    @State private var memoryGB: Int = 4
    @State private var diskSizeGB: Int = 20
    @State private var isoPath: URL?
    @State private var bootLoader: VMConfig.BootLoaderType = .uefi
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Virtual Machine")
                .font(.title)
                .padding(.top)

            Form {
                Section("Basic Configuration") {
                    TextField("VM Name", text: $vmName)
                        .textFieldStyle(.roundedBorder)

                    Picker("Boot Loader", selection: $bootLoader) {
                        Text("UEFI (Windows, Modern Linux)").tag(VMConfig.BootLoaderType.uefi)
                        Text("Linux Kernel").tag(VMConfig.BootLoaderType.linux)
                    }
                    .pickerStyle(.radioGroup)
                }

                Section("Hardware") {
                    Stepper("CPU Cores: \(cpuCount)", value: $cpuCount, in: 1...8)
                    Stepper("Memory: \(memoryGB) GB", value: $memoryGB, in: 2...32)
                    Stepper("Disk Size: \(diskSizeGB) GB", value: $diskSizeGB, in: 10...500)
                }

                Section("Installation Media") {
                    HStack {
                        if let isoPath = isoPath {
                            Text(isoPath.lastPathComponent)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button("Change") {
                                selectISO()
                            }

                            Button("Remove") {
                                self.isoPath = nil
                            }
                        } else {
                            Text("No ISO selected")
                                .foregroundColor(.secondary)

                            Spacer()

                            Button("Select ISO...") {
                                selectISO()
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding()

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Create") {
                    createVM()
                }
                .buttonStyle(.borderedProminent)
                .disabled(vmName.isEmpty || isCreating)
                .keyboardShortcut(.return)
            }
            .padding(.bottom)
        }
        .frame(width: 500, height: 600)
        .disabled(isCreating)
    }

    private func selectISO() {
        let panel = NSOpenPanel()
        panel.message = "Select an ISO file"
        panel.allowedContentTypes = [.iso]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            isoPath = panel.url
        }
    }

    private func createVM() {
        guard !vmName.isEmpty else {
            errorMessage = "Please enter a VM name"
            return
        }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                // Create disk image
                let diskPath = FileManager.default
                    .temporaryDirectory
                    .appendingPathComponent("\(vmName)-\(UUID().uuidString).img")

                let diskSizeBytes = UInt64(diskSizeGB) * 1024 * 1024 * 1024
                _ = try DiskImageManager.createRawImage(at: diskPath, sizeBytes: diskSizeBytes)

                // Create VM config
                let config = VMConfig(
                    name: vmName,
                    cpuCount: cpuCount,
                    memorySize: UInt64(memoryGB) * 1024 * 1024 * 1024,
                    diskImagePath: diskPath,
                    cdromImagePath: isoPath,
                    bootLoaderType: bootLoader
                )

                await MainActor.run {
                    library.addVM(config)
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create VM: \(error.localizedDescription)"
                    isCreating = false
                }
            }
        }
    }
}
