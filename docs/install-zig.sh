#!/bin/bash
# Install Zig and build Nuri WASM binary for Cloudflare Workers

set -e

ZIG_VERSION="0.16.0"
ZIG_DIR="$HOME/.zig"

# Save original directory
ORIGINAL_DIR=$(pwd)

# Download Zig if not already cached
if [ ! -f "$ZIG_DIR/zig" ]; then
    echo "Downloading Zig ${ZIG_VERSION}..."
    mkdir -p "$ZIG_DIR"
    cd "$ZIG_DIR"
    
    curl -L "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" -o zig.tar.xz
    tar -xf zig.tar.xz --strip-components=1
    rm zig.tar.xz
    
    cd "$ORIGINAL_DIR"
fi

# Add to PATH
export PATH="$ZIG_DIR:$PATH"

# Verify and build
zig version
echo "Building WASM binary for Cloudflare Workers..."
zig build -Dtarget=wasm32-wasi -Doptimize=ReleaseSmall

echo "Build complete! Binary at: zig-out/bin/nuri-site.wasm"
