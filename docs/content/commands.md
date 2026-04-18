---
title: Commands
description: Nuri CLI commands reference
---

# Commands

## nuri init

Create a new project:

```bash
nuri init my-site
```

This scaffolds the full project structure including `build.zig`, `src/main.zig`, and a sample `content/index.md`.

## nuri build

Convert Markdown files to merjs page modules:

```bash
nuri build
```

Parses each `.md` file in `content/` and generates corresponding `.zig` files in `src/app/`, plus `src/generated/routes.zig`.

## nuri dev

Watch, rebuild, recompile, and serve:

```bash
nuri dev
```

This command:

1. Runs an initial `nuri build`
2. Compiles the project with `zig build`
3. Starts the server on **http://localhost:3000**
4. Watches `content/` for changes
5. Automatically rebuilds, recompiles, and restarts on changes

Press **Ctrl+C** to stop.

## nuri help

Show usage information:

```bash
nuri help
```

---

[← Writing Content](guide.md) · [Home](index.md)
