# VM-Desk Quick Start Guide

## TL;DR - Test in 5 Minutes

```bash
# 1. Download Ubuntu ISO (~1.4 GB)
mkdir -p ~/VM-Images && cd ~/VM-Images
curl -L -o ubuntu-22.04.3-live-server-arm64.iso \
  https://cdimage.ubuntu.com/releases/22.04.3/release/ubuntu-22.04.3-live-server-arm64.iso

# 2. Build and run VM-Desk
cd ~/projects/VM-Desk
swift run VMDesk
```

## Using VM-Desk

### Create a VM

1. Click **"+"** in toolbar
2. Enter name: **"Ubuntu Test"**
3. Select **UEFI** boot loader
4. Set **4 GB** RAM, **2** CPUs, **20 GB** disk
5. Click **"Select ISO..."** → Choose the Ubuntu ISO
6. Click **"Create"**

### Start the VM

1. Select VM from sidebar
2. Click **"Start VM"**
3. VM display window opens
4. Watch it boot (takes 30-60 seconds)

## What You Should See

### ✅ Success Indicators

- VM appears in sidebar with green dot when running
- Display window opens (may show gray screen - this is expected)
- No error messages
- Can stop VM with "Stop VM" button
- Console output shows "VM starting..." messages

### ❌ Common Issues

**"Disk image not found"**
- The disk creation failed - check Terminal output

**"Invalid memory size"**
- Reduce RAM to 2-4 GB

**ISO not loading**
- Re-select the ISO file
- Verify ISO downloaded completely (should be ~1.4 GB)

**Gray/black screen**
- This is expected! VirtIO framebuffer integration is placeholder
- As long as VM shows "Running" status, it's working

## Current Limitations

The current build has:
- ✅ Complete VM configuration and lifecycle
- ✅ ISO mounting as CD-ROM
- ✅ Metal rendering pipeline (ready for framebuffer)
- ⚠️  Framebuffer display (placeholder - shows gray screen)
- ⚠️  Input handling (captured but not routed yet)

Even with a gray screen, if the VM starts successfully and shows "Running" status, **the core infrastructure is working correctly** and ready for the next phase of development.

## Verify Installation

```bash
# Run automated tests
cd ~/projects/VM-Desk
./test-vm.sh

# Expected output:
# ✅ Found Ubuntu ISO
# ✅ Build successful
# ✅ All tests passed
```

## Next Steps

Once you've successfully created and started a VM:

1. ✅ Core VM management works
2. 🔄 Next: Wire up VirtIO framebuffer for actual display
3. 🔄 Next: Route input events to VM
4. 🔄 Next: Add VM persistence (save/restore)

See [TESTING.md](TESTING.md) for detailed testing procedures.
