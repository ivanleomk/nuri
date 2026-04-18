---
title: Nuri - Static Site Generator for merjs
description: Convert Markdown to type-safe Zig web pages
---

# Nuri

A static site generator that converts Markdown to [merjs](https://github.com/ivanleomk/merjs) pages.

Write your content in Markdown, and Nuri generates type-safe Zig code with routing, hot reload, and semantic HTML — all powered by merjs.

## Quick Start

Install the latest binary:

```bash
curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri
chmod +x nuri
sudo mv nuri /usr/local/bin/
```

Create and run a project:

```bash
nuri init my-site
cd my-site
nuri dev
```

Open **http://localhost:3000** to see your site.

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
2. `nuri build` generates a merjs page module in `src/app/` for each file
3. It also generates `src/generated/routes.zig` with all routes wired up
4. `zig build` compiles everything into a single binary server

## Learn More

- [Installation](install.md) — download or build from source
- [Writing Content](guide.md) — Markdown, frontmatter, and routing
- [Commands](commands.md) — CLI reference
