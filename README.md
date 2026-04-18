# Nuri

A static site generator that converts Markdown to [merjs](https://github.com/ivanleomk/merjs) (Zig web framework) pages.

Write your content in Markdown, and Nuri generates type-safe Zig code with routing, hot reload, and semantic HTML — all powered by merjs.

## Install

Download the latest binary for your platform:

```bash
# macOS (Apple Silicon)
curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri
chmod +x nuri
sudo mv nuri /usr/local/bin/
```

Or build from source (requires [Zig 0.16+](https://ziglang.org/download/)):

```bash
git clone https://github.com/ivanleomk/nuri.git
cd nuri
zig build -Doptimize=ReleaseSafe
# binary is at zig-out/bin/nuri
```

## Quick Start

```bash
# Create a new project
nuri init my-site
cd my-site

# Start development (watch, rebuild, serve on :3000)
nuri dev
```

That's it. Open http://localhost:3000 to see your site.

## How It Works

```
content/           →  nuri build  →  src/app/            →  zig build  →  binary
  index.md                           index.zig
  about.md                           about.zig
  blog/first.md                      blog/first.zig
                                   src/generated/
                                     routes.zig
```

1. You write Markdown in `content/`
2. `nuri build` parses each `.md` file and generates a merjs page module in `src/app/`
3. It also generates `src/generated/routes.zig` with all routes wired up
4. `zig build` compiles everything into a single binary server

`nuri dev` does all of this automatically — watches for changes, rebuilds, recompiles, and restarts the server.

## Project Structure

After `nuri init`, your project looks like this:

```
my-site/
├── build.zig          # Zig build config (auto-generated)
├── build.zig.zon      # Dependencies (merjs)
├── nuri.config.json   # Site metadata
├── content/           # Your Markdown files
│   └── index.md       # Homepage (required)
├── public/            # Static assets
├── src/
│   ├── main.zig       # Server entry point (auto-generated)
│   ├── app/           # Generated page modules
│   └── generated/
│       └── routes.zig # Generated route table
```

## Writing Content

Each Markdown file in `content/` becomes a route:

| File                    | Route          |
|-------------------------|----------------|
| `content/index.md`      | `/`            |
| `content/about.md`      | `/about`       |
| `content/blog/first.md` | `/blog/first`  |

Every site must have a `content/index.md` — this is your homepage.

### Frontmatter

Add metadata at the top of your Markdown files:

```markdown
---
title: About Us
description: Learn more about our team
---

# About Us

Your content here...
```

### Supported Markdown

- Headings (`# H1` through `###### H6`)
- Paragraphs
- **Bold** and *italic* text
- `Inline code`
- Code blocks with language hints
- Unordered and ordered lists
- [Links](https://example.com) — local `.md` links are auto-transformed to routes

## Commands

| Command           | Description                                      |
|-------------------|--------------------------------------------------|
| `nuri init <name>` | Create a new project                            |
| `nuri build`       | Convert Markdown to merjs pages                 |
| `nuri dev`         | Watch, rebuild, recompile, and serve on `:3000` |
| `nuri help`        | Show help                                       |

## Requirements

- [Zig 0.16+](https://ziglang.org/download/) (for building generated projects)
