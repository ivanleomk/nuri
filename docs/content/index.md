---
title: Nuri
description: A static site generator that converts Markdown to merjs pages
---

# Nuri

Nuri converts Markdown files into type-safe Zig code using [merjs](https://github.com/ivanleomk/merjs). Write content in Markdown and get a fast web server with hot reload and auto-generated navigation. No complex configuration needed—just write and deploy.

## Quick Start

Get up and running in minutes:

```bash
# Install Nuri (macOS)
curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri
chmod +x nuri
sudo mv nuri /usr/local/bin/

# Create and run a new site
nuri init my-site
cd my-site
nuri dev
```

Visit http://localhost:3000. The dev server watches your files and rebuilds automatically when you make changes.

## Commands

Nuri provides a simple CLI for managing your site. These are the main commands you'll use day-to-day:

**nuri init <name>** — Creates a new project with all necessary files including the `content/` directory for your Markdown, `public/` for static assets, and configuration files. This sets up the entire project structure so you can start writing immediately.

**nuri build** — Converts all Markdown files in `content/` to Zig code in `src/app/`. It parses frontmatter, generates the route table, and creates the layout wrapper. Run this before deploying or when you want to see the generated code.

**nuri dev** — Starts the development server with hot reload. Watches both `content/` and `public/` directories for changes. When you edit a Markdown file, it rebuilds and restarts the server automatically. Press Ctrl+C to stop.

**nuri help** — Displays help information and available commands.

After running `nuri build`, you can use Zig's build system directly:

```bash
zig build serve      # Start dev server
zig build prerender  # Generate static HTML to dist/
zig build prod       # Full production build
```

## Writing Content

Content lives in the `content/` directory as Markdown files. Nuri uses file-based routing, which means your folder structure directly maps to your site's URL structure. Every `.md` file becomes a page.

| File | Route |
|------|-------|
| `content/index.md` | `/` |
| `content/about.md` | `/about` |
| `content/blog/post.md` | `/blog/post` |

Every site must have `content/index.md`—this is your homepage. Without it, Nuri will refuse to build.

Add metadata using YAML frontmatter at the top of your files:

```markdown
---
title: About Us
description: A brief description of our team
---

# About Us

Your content here...
```

The title appears in the page's HTML `<title>` tag and the table of contents. The description is used for SEO meta tags. Both are optional but recommended.

## Deployment

Deploy anywhere that supports static files or Zig binaries. For detailed Cloudflare Pages setup:

- [Cloudflare Pages](/deployment/cloudflare)

## Project Structure

Nuri generates a clean project layout:

```
my-site/
├── content/          # Your Markdown content
├── public/           # Static assets (CSS, images, fonts)
├── src/
│   ├── app/          # Generated Zig pages (don't edit)
│   └── generated/    # Route table (don't edit)
├── build.zig         # Zig build configuration
└── nuri.config.json  # Site metadata
```

The only directories you should edit are `content/` (for your writing) and `public/` (for custom styles and assets). Everything in `src/` is auto-generated and gets overwritten each time you run `nuri build`.

When you're ready to deploy, the build process compiles everything into either static HTML files in `dist/` (for static hosting) or a binary server at `zig-out/bin/nuri-site` (for running your own server).
