---
title: Nuri - Documentation
description: Complete guide to Nuri static site generator
---

# Nuri

A static site generator that converts Markdown to [merjs](https://github.com/ivanleomk/merjs) pages.

Write your content in Markdown, and Nuri generates type-safe Zig code with routing, hot reload, and semantic HTML — all powered by merjs. Deploy to Cloudflare Workers, VPS, or anywhere.

🚀 Successfully deployed via GitHub Actions!

## Installation

### Pre-built Binary (macOS Apple Silicon)

```bash
curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri
chmod +x nuri
sudo mv nuri /usr/local/bin/
```

### Build from Source

Requires [Zig 0.16+](https://ziglang.org/download/):

```bash
git clone https://github.com/ivanleomk/nuri.git
cd nuri
zig build -Doptimize=ReleaseSafe
# Binary is at zig-out/bin/nuri
```

## Quick Start

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

1. Write Markdown in `content/`
2. `nuri build` generates merjs page modules in `src/app/`
3. `src/generated/routes.zig` is auto-generated with all routes
4. `zig build` compiles to a single binary server

## Commands

| Command | Description |
|---------|-------------|
| `nuri init <name>` | Create new project |
| `nuri build` | Convert Markdown to merjs pages |
| `nuri dev` | Watch, rebuild, and serve on :3000 |
| `nuri help` | Show help |

## Writing Content

### File-based Routing

Each Markdown file in `content/` becomes a route:

| File | Route |
|------|-------|
| `content/index.md` | `/` |
| `content/about.md` | `/about` |
| `content/blog/first.md` | `/blog/first` |

Every site **must** have `content/index.md` (homepage).

### Frontmatter

Add metadata at the top of Markdown files:

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
- [Links](https://example.com) — local `.md` links auto-transform to routes

## Project Structure

```
my-site/
├── build.zig              # Zig build configuration
├── build.zig.zon          # Dependencies
├── nuri.config.json       # Site metadata
├── content/               # Markdown files
│   └── index.md
├── public/               # Static assets (CSS, images)
└── src/
    ├── main.zig          # Server entry point
    ├── app/              # Generated page modules
    └── generated/
        └── routes.zig    # Auto-generated routes
```

## Deployment

See the [deployment guide](deployment.md) for detailed instructions on deploying to Cloudflare Workers, VPS, or static hosts.

## Customization

Edit `public/styles.css` to customize styling — this file won't be overwritten.

## Agent Skill

Nuri includes a Vercel Agent Skill for AI assistants. Install it with:

```bash
npx skills add https://github.com/ivanleomk/nuri/tree/main/nuri
```

The skill provides project patterns, routing conventions, development workflows, and deployment configurations for AI tools that support the [Agent Skills standard](https://agentskills.io/specification).

---

**GitHub:** [github.com/ivanleomk/nuri](https://github.com/ivanleomk/nuri)
