#!/bin/bash
# Install Zig for Cloudflare Pages build and run the build

set -e

ZIG_VERSION="0.16.0"
ZIG_DIR="$HOME/.zig"

# Remember the original directory (docs/)
ORIGINAL_DIR=$(pwd)

# Download Zig if not already cached
if [ ! -f "$ZIG_DIR/zig" ]; then
    echo "Downloading Zig ${ZIG_VERSION}..."
    mkdir -p "$ZIG_DIR"
    cd "$ZIG_DIR"
    
    # URL pattern changed in 0.16.0: zig-x86_64-linux-VERSION.tar.xz
    DOWNLOAD_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz"
    
    echo "Downloading from: $DOWNLOAD_URL"
    
    # Download with proper error handling
    if ! curl -fL -o zig.tar.xz "$DOWNLOAD_URL"; then
        echo "Failed to download from ziglang.org, trying GitHub releases..."
        DOWNLOAD_URL="https://github.com/ziglang/zig/releases/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz"
        echo "Trying: $DOWNLOAD_URL"
        curl -fL -o zig.tar.xz "$DOWNLOAD_URL" || {
            echo "ERROR: Could not download Zig from any source"
            exit 1
        }
    fi
    
    # Check what we downloaded
    echo "Downloaded file size:"
    ls -lh zig.tar.xz
    
    # Verify it's a valid archive
    if ! file zig.tar.xz | grep -q "tar archive\|XZ compressed"; then
        echo "ERROR: Downloaded file is not a valid tar.xz archive"
        echo "File type:"
        file zig.tar.xz
        echo "First 200 bytes:"
        head -c 200 zig.tar.xz
        exit 1
    fi
    
    echo "Extracting..."
    tar -xf zig.tar.xz --strip-components=1
    rm zig.tar.xz
fi

# Go back to original directory (docs/) and run the build
cd "$ORIGINAL_DIR"
echo "Building WASM bundle in: $(pwd)"
$ZIG_DIR/zig build worker

echo "Build complete!"
