---
title: Installation
description: How to install Nuri
---

# Installation

## Pre-built Binary (macOS Apple Silicon)

```bash
curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri
chmod +x nuri
sudo mv nuri /usr/local/bin/
```

## Build from Source

Requires [Zig 0.16+](https://ziglang.org/download/):

```bash
git clone https://github.com/ivanleomk/nuri.git
cd nuri
zig build -Doptimize=ReleaseSafe
```

The binary is at `zig-out/bin/nuri`.

## Requirements

- **Zig 0.16+** — needed to compile generated projects

---

[← Home](index.md) · [Writing Content →](guide.md)
