---
name: nuri
description: Convert Markdown to type-safe Zig web pages with file-based routing, hot reload, and static site generation. Use when building static sites with Nuri, generating pages from Markdown, or deploying to Cloudflare Pages/Netlify.
license: MIT
metadata:
  version: 0.1.0
---

# Nuri

Static site generator that converts Markdown to type-safe Zig web pages powered by merjs.

## What This Skill Does

- Generates Zig code from Markdown files with file-based routing
- Creates auto-generated table of contents from headings
- Provides hot reload development server
- Supports static site generation (SSG) for deployment

## When To Use It

Use this skill when:
- Building a static site with Nuri
- Converting Markdown to Zig/merjs pages
- Setting up file-based routing
- Configuring deployment to Cloudflare Pages, Netlify, or VPS
- Understanding the project structure and conventions

## Project Structure

```
my-site/
├── build.zig              # Zig build config
├── build.zig.zon          # Dependencies (merjs)
├── nuri.config.json       # Site metadata
├── content/               # Markdown source files
│   └── index.md          # Required homepage
├── public/               # Static assets (CSS, images, etc.)
└── src/
    ├── main.zig          # Server entry point
    ├── app/              # Generated page modules
    └── generated/
        └── routes.zig    # Auto-generated route table
```

## File-Based Routing

| Markdown File | Route |
|---------------|-------|
| `content/index.md` | `/` |
| `content/about.md` | `/about` |
| `content/blog/first.md` | `/blog/first` |

Every site **must** have `content/index.md` (homepage).

## Commands

```bash
nuri init <name>     # Create new project
nuri build          # Generate pages from Markdown
nuri dev            # Watch, rebuild, serve on :3000
zig build prod     # Static site to dist/
```

## Frontmatter

Add metadata to Markdown files:

```markdown
---
title: Page Title
description: Page description for SEO
---

# Your Content
```

## Development Workflow

1. **Initialize**: `nuri init my-site && cd my-site`
2. **Write**: Edit files in `content/`
3. **Preview**: `nuri dev` — auto-rebuilds on changes
4. **Build**: `nuri build` then `zig build` for production

## Deployment

### Static Site (Cloudflare Pages, Netlify)

```bash
nuri build
zig build prod    # Outputs to dist/
```

Upload `dist/` to any static host.

### Server (VPS, Fly.io)

```bash
nuri build
zig build -Doptimize=ReleaseFast
# Deploy zig-out/bin/nuri-site binary
```

## Key Conventions

- Always include `content/index.md` (required homepage)
- Use relative links to other `.md` files: `[About](about.md)`
- External links work normally: `[Example](https://example.com)`
- TOC only shows H1-H3 headings
- Edit `public/styles.css` for styling (won't be overwritten)
- Edit `src/app/layout.zig` for layout changes

## Installation

```bash
curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri
chmod +x nuri
sudo mv nuri /usr/local/bin/
```

Or build from source (requires Zig 0.16+):
```bash
git clone https://github.com/ivanleomk/nuri.git
cd nuri
zig build -Doptimize=ReleaseSafe
```

## Generated Code Pattern

```zig
const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Page Title",
    .description = "Page description",
};

pub fn render(req: mer.Request) mer.Response {
    return mer.render(req.allocator, page_node);
}

pub const prerender = true;  // Enable SSG
```

## Dependencies

Add to `build.zig.zon`:

```zig
.merjs = .{
    .url = "git+https://github.com/ivanleomk/merjs.git#v0.2.5",
    .hash = "merjs-0.2.5-qL9LkhRVZABuCKYsftrbz81_-4FGVeJMskrxGEw5obBo",
},
```
