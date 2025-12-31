# VM-Desk Testing Guide

This guide walks you through testing VM-Desk with a real operating system.

## Prerequisites

- macOS 15.0 or later (Apple Silicon Mac required)
- At least 20 GB free disk space
- 8+ GB RAM recommended for testing

## Quick Start Testing

### 1. Download Ubuntu ARM64 ISO

```bash
# Create directory for VM images
mkdir -p ~/VM-Images
cd ~/VM-Images

# Download Ubuntu 22.04 ARM64 Server (~1.4 GB)
curl -L -O https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.3-live-server-arm64.iso

# Verify download
ls -lh ubuntu-22.04.3-live-server-arm64.iso
```

### 2. Build and Test VM-Desk

```bash
cd ~/projects/VM-Desk

# Run automated tests
./test-vm.sh
```

### 3. Launch VM-Desk Application

```bash
# Build and run the application
swift run VMDesk
```

## Manual Testing Steps

### Creating Your First VM

1. **Launch VM-Desk**
   - Click the window that appears or use `swift run VMDesk`

2. **Create New VM**
   - Click the **"+"** button in the toolbar
   - Or use keyboard shortcut: **Cmd+N**

3. **Configure VM Settings**
   ```
   VM Name:      Ubuntu Test VM
   Boot Loader:  UEFI (for Ubuntu/Windows)
   CPU Cores:    2-4 (more = faster, but uses more resources)
   Memory:       4-8 GB (4 GB minimum for Ubuntu)
   Disk Size:    20-50 GB (20 GB minimum recommended)
   ```

4. **Select Installation ISO**
   - Click **"Select ISO..."**
   - Navigate to `~/VM-Images/`
   - Select `ubuntu-22.04.3-live-server-arm64.iso`
   - Click **"Open"**

5. **Create VM**
   - Click **"Create"** button
   - VM will appear in the sidebar

### Starting the VM

1. **Select VM**
   - Click on "Ubuntu Test VM" in the left sidebar

2. **Review Configuration**
   - Verify CPU, Memory, Disk, and CD-ROM settings are correct

3. **Start VM**
   - Click the **"Start VM"** button
   - A new window should open showing the VM display

### What to Expect

#### Successful Boot Sequence:
1. **UEFI Boot Screen** (2-3 seconds)
   - Black screen with white text
   - "Booting from CD-ROM..."

2. **GRUB Bootloader** (5-10 seconds)
   - Purple/blue screen
   - Ubuntu logo and boot options

3. **Ubuntu Installer** (30-60 seconds)
   - Text-based installer interface
   - Language selection screen

#### Testing Checklist:

- [ ] VM window opens
- [ ] Display shows UEFI boot messages
- [ ] GRUB menu appears
- [ ] Ubuntu installer loads
- [ ] Keyboard input works (navigate menus with arrow keys)
- [ ] Can select options with Enter key
- [ ] Status indicator shows "Running" (green dot)
- [ ] Can pause/resume VM
- [ ] Can stop VM cleanly

### Troubleshooting

#### VM Won't Start

**Error: "Disk image not found"**
- Check that the disk was created successfully
- Look in Terminal output for disk creation errors

**Error: "Invalid CPU count"**
- Your Mac may not support that many virtual CPUs
- Try reducing to 2 CPUs

**Error: "Invalid memory size"**
- Reduce memory allocation
- Ensure you have enough free RAM on your Mac

**Error: "ISO file not found"**
- Verify ISO path is correct
- Re-select the ISO file in the wizard

#### Display Issues

**Black screen / No display:**
- Wait 30-60 seconds (boot can be slow on first run)
- Check Console output for errors
- Verify Metal is supported on your Mac

**Display freezes:**
- This is expected - VirtIO framebuffer integration is placeholder
- Metal rendering is working but needs actual VM framebuffer data

#### Input Not Working

**Keyboard input doesn't work:**
- Click inside the VM display window to focus it
- Input handling is currently placeholder (will be wired up in future)

**Mouse not captured:**
- Expected - proper mouse capture not yet implemented

## Testing Different Scenarios

### Test 1: UEFI Boot (Ubuntu/Modern Linux)

```
Boot Loader: UEFI
ISO: Ubuntu ARM64
Expected: Should boot to Ubuntu installer
```

### Test 2: Linux Kernel Boot

```
Boot Loader: Linux Kernel
ISO: None (kernel in disk image)
Expected: Will fail without actual kernel - test error handling
```

### Test 3: ISO Boot Without Disk

```
Create VM with minimal disk (1 GB)
Add Ubuntu ISO
Expected: Should boot to installer from ISO
```

### Test 4: Multiple VMs

1. Create 2-3 VMs with different configurations
2. Start one VM
3. Verify others show "stopped" state
4. Start second VM while first is running
5. Both should run simultaneously (if RAM permits)

## Performance Testing

### Metrics to Check:

1. **Memory Usage**
   ```bash
   # Monitor VM-Desk memory
   ps aux | grep VMDesk
   ```

2. **Build Time**
   ```bash
   time swift build -c release
   # Should be under 10 seconds for incremental builds
   ```

3. **VM Startup Time**
   - From "Start VM" click to UEFI screen: 2-5 seconds
   - From UEFI to GRUB: 5-10 seconds
   - From GRUB to installer: 30-60 seconds

## Known Limitations (Current Implementation)

1. **VirtIO Framebuffer**: Placeholder - shows dark gray screen instead of actual VM output
2. **Input Handling**: Events captured but not routed to VM yet
3. **VM Persistence**: VMs lost on app restart (no save/load yet)
4. **Network**: NAT only (no bridged networking)
5. **Shared Folders**: Not wired up to UI yet

## Next Steps After Testing

If basic VM creation and startup works:

1. **Report Results**
   - Document what works and what doesn't
   - Take screenshots of successful boot
   - Note any errors or crashes

2. **Integration Testing**
   - Test with different ISOs (Debian, Fedora, Alpine)
   - Test error cases (invalid configs, missing files)
   - Stress test with multiple concurrent VMs

3. **Ready for Phase 2**
   - VirtIO framebuffer integration (actual display output)
   - Input event routing (functional keyboard/mouse)
   - VM persistence (save/restore VMs)

## Automated Test Script

The `test-vm.sh` script validates:
- ✅ ISO file exists
- ✅ Project builds successfully
- ✅ All 15 unit tests pass
- ✅ No compilation errors

Run it before manual testing to catch issues early.

## Getting Help

If you encounter issues:

1. Check build output for errors
2. Review Console.app for crash logs
3. Verify system requirements (macOS 15+, Apple Silicon)
4. Ensure enough disk space and RAM

## Success Criteria

VM-Desk is working correctly if:

1. ✅ Application launches without crashing
2. ✅ Can create VM with wizard
3. ✅ VM appears in sidebar
4. ✅ "Start VM" button triggers VM startup
5. ✅ VM display window opens
6. ✅ Status shows "Running" when VM starts
7. ✅ Can stop VM cleanly
8. ✅ No memory leaks or crashes

Even if the display shows a blank/gray screen, if the above work, the core infrastructure is solid and ready for the next phase of development.
