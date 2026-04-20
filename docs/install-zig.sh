#!/bin/bash
# Install Zig and build Nuri site for Cloudflare Pages

set -e

ZIG_VERSION="0.16.0"
ZIG_DIR="$HOME/.zig"

# Download Zig if not already cached
if [ ! -f "$ZIG_DIR/zig" ]; then
    echo "Downloading Zig ${ZIG_VERSION}..."
    mkdir -p "$ZIG_DIR"
    cd "$ZIG_DIR"
    
    curl -L "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz" -o zig.tar.xz
    tar -xf zig.tar.xz --strip-components=1
    rm zig.tar.xz
fi

# Add to PATH
export PATH="$ZIG_DIR:$PATH"

# Verify and build
zig version
echo "Building site..."
zig build prod

echo "Build complete!"
