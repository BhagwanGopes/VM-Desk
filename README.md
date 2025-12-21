# VM-Desk

High-performance virtualization platform for macOS leveraging Apple's Virtualization.framework.

## Project Status

🚧 **Active Development** - Phase 1: Linux ARM64 Virtualization MVP

## Goals

- **Performance**: Near-native VM performance using VirtIO paravirtualization
- **Integration**: Seamless macOS integration (shared folders, clipboard, coherence mode)
- **OS Support**: Linux ARM64 and Windows 11 ARM64 guest operating systems

## Architecture

Built on Apple's Virtualization.framework with Swift 6.0 strict concurrency.

### Technology Stack

- **Language**: Swift 6.0 (strict concurrency mode)
- **Platform**: macOS 15.0+
- **Frameworks**: Virtualization.framework, SwiftUI
- **Build System**: Swift Package Manager

### Core Components

```
Sources/VMDesk/
├── Core/           # VM configuration, lifecycle, bundles
├── Storage/        # VirtIO block devices, disk images
├── Networking/     # NAT, bridged networking
├── Display/        # VirtIO graphics, resolution management
├── Integration/    # Shared folders (VirtioFS), clipboard
└── UI/             # SwiftUI application shell
```

## Features Implemented

### Core Virtualization
- ✅ VM configuration model with isolation modes
- ✅ VM lifecycle management (start/stop/pause/resume)
- ✅ VMBundle format for persistent storage
- ✅ VirtIO block device storage
- ✅ Disk image creation (raw and sparse formats)

### Networking
- ✅ NAT networking (VirtIO NIC)
- ✅ MAC address management
- 🚧 Bridged networking (requires restricted entitlements)

### Display & Input
- ✅ VirtIO graphics with configurable resolutions
- ✅ USB keyboard and pointing device support
- ✅ Serial console for debugging

### Integration
- ✅ VirtioFS shared folders
- ✅ Clipboard manager infrastructure
- 🚧 Guest agent for bi-directional clipboard sync

## Entitlements & Security

### Core Entitlements (Enabled)
- `com.apple.security.virtualization` - VM execution
- `com.apple.security.network.client/server` - NAT networking
- `com.apple.security.cs.allow-jit` - JIT compilation for VMs

### Restricted Entitlements (Planned)
- `com.apple.vm.networking` - Bridged networking
- `com.apple.vm.device-access` - USB passthrough

### Isolation Modes
- **Isolated Mode** (Default): Sandboxed VM, NAT networking, user-selected disks
- **Unrestricted Mode**: Full hardware access (USB, raw disks, bridged networking)

## Development

### Build

```bash
swift build
```

### Test

```bash
swift test
```

### Project Structure

```
VM-Desk/
├── Sources/VMDesk/      # Application code
├── Tests/VMDeskTests/   # Unit tests
├── VM-Desk/             # App bundle resources
│   ├── Info.plist       # App metadata
│   └── VMDesk.entitlements
└── Package.swift        # Swift package manifest
```

## Roadmap

### Phase 1: MVP (Linux ARM64) - In Progress
- [x] Core VM configuration and lifecycle
- [x] VirtIO block device storage
- [x] NAT networking
- [x] VirtIO graphics
- [x] Shared folders (VirtioFS)
- [ ] Boot Ubuntu ARM64 to desktop
- [ ] GUI VM creation wizard
- [ ] VM library UI

### Phase 2: Windows ARM64 Support
- [ ] UEFI boot loader
- [ ] VirtIO driver integration
- [ ] TPM 2.0 emulation
- [ ] Windows guest agent

### Phase 3: Advanced Features
- [ ] Coherence mode (seamless app integration)
- [ ] GPU acceleration (DirectX → Metal translation)
- [ ] USB passthrough
- [ ] VM snapshots and linked clones

## Testing

Current test coverage: **15 passing tests**

- VMConfig initialization and serialization
- Disk image creation/resize/deletion
- Network device configuration
- All tests passing with no failures

## Requirements

- macOS 15.0 or later
- Apple Silicon (ARM64)
- Xcode 16.0+ (for development)

## License

*License to be determined*

## Contributing

This is a personal-use project currently in active development.

---

**Note**: This project is not affiliated with or endorsed by Parallels, Inc.
