#!/bin/bash
# VM-Desk Testing Script
# Tests VM creation and startup with Ubuntu ARM64

set -e

echo "VM-Desk Testing Script"
echo "======================"
echo ""

# Check if ISO downloaded
ISO_PATH="$HOME/VM-Images/ubuntu-22.04.3-live-server-arm64.iso"
if [ ! -f "$ISO_PATH" ]; then
    echo "⚠️  Ubuntu ISO not found at: $ISO_PATH"
    echo ""
    echo "Download Ubuntu ARM64 ISO:"
    echo "  1. Visit: https://cdimage.ubuntu.com/releases/22.04.3/release/"
    echo "  2. Download: ubuntu-22.04.3-live-server-arm64.iso (~1.4 GB)"
    echo "  3. Move to: ~/VM-Images/"
    echo ""
    echo "Or use any ARM64 Linux ISO (Debian, Fedora, Alpine, etc.)"
    echo ""
    echo "Skipping ISO validation..."
    ISO_PATH=""
else
    echo "✅ Found Ubuntu ISO: $ISO_PATH"
    ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
    echo "   Size: $ISO_SIZE"
fi
echo ""

# Build VM-Desk
echo "📦 Building VM-Desk..."
cd "$(dirname "$0")"
swift build -c release
echo "✅ Build successful"
echo ""

# Run tests
echo "🧪 Running unit tests..."
swift test
echo "✅ All tests passed"
echo ""

echo "🎉 VM-Desk is ready for manual testing!"
echo ""
echo "Next steps:"
echo "1. Open VM-Desk application"
echo "2. Click the '+' button to create a new VM"
echo "3. Configure VM:"
echo "   - Name: Ubuntu Test VM"
echo "   - Boot Loader: UEFI"
echo "   - CPU: 2-4 cores"
echo "   - Memory: 4-8 GB"
echo "   - Disk: 20+ GB"
echo "4. Select ISO: $ISO_PATH"
echo "5. Click 'Create' and then 'Start VM'"
echo ""
echo "Expected behavior:"
echo "- VM should boot to Ubuntu installer"
echo "- Display window should show Ubuntu boot screen"
echo "- Keyboard/mouse input should work"
echo ""
