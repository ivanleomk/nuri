const std = @import("std");
const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Nuri",
    .description = "A static site generator that converts Markdown to merjs pages",
};

const page_node = page();

const raw_markdown = "---\ntitle: Nuri\ndescription: A static site generator that converts Markdown to merjs pages\n---\n\n# Nuri\n\nNuri converts Markdown files into type-safe Zig code using [merjs](https://github.com/ivanleomk/merjs). Write content in Markdown and get a fast web server with hot reload and auto-generated navigation. No complex configuration needed—just write and deploy.\n\n## Quick Start\n\nGet up and running in minutes:\n\n```bash\n# Install Nuri (macOS)\ncurl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri\nchmod +x nuri\nsudo mv nuri /usr/local/bin/\n\n# Create and run a new site\nnuri init my-site\ncd my-site\nnuri dev\n```\n\nVisit http://localhost:3000. The dev server watches your files and rebuilds automatically when you make changes.\n\n## Commands\n\nNuri provides a simple CLI for managing your site. These are the main commands you'll use day-to-day:\n\n**nuri init <name>** — Creates a new project with all necessary files including the `content/` directory for your Markdown, `public/` for static assets, and configuration files. This sets up the entire project structure so you can start writing immediately.\n\n**nuri build** — Converts all Markdown files in `content/` to Zig code in `src/app/`. It parses frontmatter, generates the route table, and creates the layout wrapper. Run this before deploying or when you want to see the generated code.\n\n**nuri dev** — Starts the development server with hot reload. Watches both `content/` and `public/` directories for changes. When you edit a Markdown file, it rebuilds and restarts the server automatically. Press Ctrl+C to stop.\n\n**nuri help** — Displays help information and available commands.\n\nAfter running `nuri build`, you can use Zig's build system directly:\n\n```bash\nzig build serve      # Start dev server\nzig build prerender  # Generate static HTML to dist/\nzig build prod       # Full production build\n```\n\n## Writing Content\n\nContent lives in the `content/` directory as Markdown files. Nuri uses file-based routing, which means your folder structure directly maps to your site's URL structure. Every `.md` file becomes a page.\n\n| File | Route |\n|------|-------|\n| `content/index.md` | `/` |\n| `content/about.md` | `/about` |\n| `content/blog/post.md` | `/blog/post` |\n\nEvery site must have `content/index.md`—this is your homepage. Without it, Nuri will refuse to build.\n\nAdd metadata using YAML frontmatter at the top of your files:\n\n```markdown\n---\ntitle: About Us\ndescription: A brief description of our team\n---\n\n# About Us\n\nYour content here...\n```\n\nThe title appears in the page's HTML `<title>` tag and the table of contents. The description is used for SEO meta tags. Both are optional but recommended.\n\n## Programmatic Access\n\nEach page supports returning raw markdown via query parameter:\n\n```bash\n# Get HTML (default)\ncurl http://localhost:3000/\n\n# Get raw markdown\ncurl http://localhost:3000/?format=md\n```\n\nAdd `?format=md` to any page URL to retrieve the original markdown source. Returns `text/plain` content type.\n\n## Deployment\n\nDeploy anywhere that supports static files or Zig binaries. For detailed Cloudflare Pages setup:\n\n- [Cloudflare Pages](/deployment/cloudflare)\n\n## Project Structure\n\nNuri generates a clean project layout:\n\n```\nmy-site/\n├── content/          # Your Markdown content\n├── public/           # Static assets (CSS, images, fonts)\n├── src/\n│   ├── app/          # Generated Zig pages (don't edit)\n│   └── generated/    # Route table (don't edit)\n├── build.zig         # Zig build configuration\n└── nuri.config.json  # Site metadata\n```\n\nThe only directories you should edit are `content/` (for your writing) and `public/` (for custom styles and assets). Everything in `src/` is auto-generated and gets overwritten each time you run `nuri build`.\n\nWhen you're ready to deploy, the build process compiles everything into either static HTML files in `dist/` (for static hosting) or a binary server at `zig-out/bin/nuri-site` (for running your own server).\n";

pub fn render(req: mer.Request) mer.Response {
    // Check if client wants raw markdown
    if (std.mem.eql(u8, req.queryParam("format") orelse "", "md")) {
        return mer.text(.ok, raw_markdown);
    }
    return mer.render(req.allocator, page_node);
}

pub const prerender = true;

fn page() h.Node {
    return h.div(.{ .class = "page-wrapper" }, .{
        h.nav(.{ .class = "toc" }, .{
            h.div(.{ .class = "toc-header" }, "On this page"),
            h.ul(.{}, .{
                h.li(.{ .class = "toc-h1" }, .{h.a(.{ .href = "#nuri" }, "Nuri")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#quick-start" }, "Quick Start")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#commands" }, "Commands")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#writing-content" }, "Writing Content")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#programmatic-access" }, "Programmatic Access")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#deployment" }, "Deployment")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#project-structure" }, "Project Structure")}),
            }),
        }),
        h.div(.{ .class = "page-content" }, .{
            h.h1(.{ .class = "title", .id = "nuri" }, "Nuri"),
            h.p(.{}, .{
                h.text("Nuri converts Markdown files into type-safe Zig code using "),
                h.a(.{ .href = "https://github.com/ivanleomk/merjs" }, "merjs"),
                h.text(". Write content in Markdown and get a fast web server with hot reload and auto-generated navigation. No complex configuration needed—just write and deploy."),
            }),
            h.h2(.{ .class = "subtitle", .id = "quick-start" }, "Quick Start"),
            h.p(.{}, .{
                h.text("Get up and running in minutes:"),
            }),
            h.pre(.{}, .{h.code(.{}, "# Install Nuri (macOS)\ncurl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri\nchmod +x nuri\nsudo mv nuri /usr/local/bin/\n\n# Create and run a new site\nnuri init my-site\ncd my-site\nnuri dev")}),
            h.p(.{}, .{
                h.text("Visit http://localhost:3000. The dev server watches your files and rebuilds automatically when you make changes."),
            }),
            h.h2(.{ .class = "subtitle", .id = "commands" }, "Commands"),
            h.p(.{}, .{
                h.text("Nuri provides a simple CLI for managing your site. These are the main commands you'll use day-to-day:"),
            }),
            h.p(.{}, .{
                h.strong(.{}, "nuri init <name>"),
                h.text(" — Creates a new project with all necessary files including the "),
                h.code(.{}, "content/"),
                h.text(" directory for your Markdown, "),
                h.code(.{}, "public/"),
                h.text(" for static assets, and configuration files. This sets up the entire project structure so you can start writing immediately."),
            }),
            h.p(.{}, .{
                h.strong(.{}, "nuri build"),
                h.text(" — Converts all Markdown files in "),
                h.code(.{}, "content/"),
                h.text(" to Zig code in "),
                h.code(.{}, "src/app/"),
                h.text(". It parses frontmatter, generates the route table, and creates the layout wrapper. Run this before deploying or when you want to see the generated code."),
            }),
            h.p(.{}, .{
                h.strong(.{}, "nuri dev"),
                h.text(" — Starts the development server with hot reload. Watches both "),
                h.code(.{}, "content/"),
                h.text(" and "),
                h.code(.{}, "public/"),
                h.text(" directories for changes. When you edit a Markdown file, it rebuilds and restarts the server automatically. Press Ctrl+C to stop."),
            }),
            h.p(.{}, .{
                h.strong(.{}, "nuri help"),
                h.text(" — Displays help information and available commands."),
            }),
            h.p(.{}, .{
                h.text("After running "),
                h.code(.{}, "nuri build"),
                h.text(", you can use Zig's build system directly:"),
            }),
            h.pre(.{}, .{h.code(.{}, "zig build serve      # Start dev server\nzig build prerender  # Generate static HTML to dist/\nzig build prod       # Full production build")}),
            h.h2(.{ .class = "subtitle", .id = "writing-content" }, "Writing Content"),
            h.p(.{}, .{
                h.text("Content lives in the "),
                h.code(.{}, "content/"),
                h.text(" directory as Markdown files. Nuri uses file-based routing, which means your folder structure directly maps to your site's URL structure. Every "),
                h.code(.{}, ".md"),
                h.text(" file becomes a page."),
            }),
            h.table(.{}, .{
                h.thead(.{}, .{h.tr(.{}, .{
                    h.th(.{}, "File"),
                    h.th(.{}, "Route"),
                })}),
                h.tbody(.{}, .{
                    h.tr(.{}, .{
                        h.td(.{}, "`content/index.md`"),
                        h.td(.{}, "`/`"),
                    }),
                    h.tr(.{}, .{
                        h.td(.{}, "`content/about.md`"),
                        h.td(.{}, "`/about`"),
                    }),
                    h.tr(.{}, .{
                        h.td(.{}, "`content/blog/post.md`"),
                        h.td(.{}, "`/blog/post`"),
                    }),
                }),
            }),
            h.p(.{}, .{
                h.text("Every site must have "),
                h.code(.{}, "content/index.md"),
                h.text("—this is your homepage. Without it, Nuri will refuse to build."),
            }),
            h.p(.{}, .{
                h.text("Add metadata using YAML frontmatter at the top of your files:"),
            }),
            h.pre(.{}, .{h.code(.{}, "---\ntitle: About Us\ndescription: A brief description of our team\n---\n\n# About Us\n\nYour content here...")}),
            h.p(.{}, .{
                h.text("The title appears in the page's HTML "),
                h.code(.{}, "<title>"),
                h.text(" tag and the table of contents. The description is used for SEO meta tags. Both are optional but recommended."),
            }),
            h.h2(.{ .class = "subtitle", .id = "programmatic-access" }, "Programmatic Access"),
            h.p(.{}, .{
                h.text("Each page supports returning raw markdown via query parameter:"),
            }),
            h.pre(.{}, .{h.code(.{}, "# Get HTML (default)\ncurl http://localhost:3000/\n\n# Get raw markdown\ncurl http://localhost:3000/?format=md")}),
            h.p(.{}, .{
                h.text("Add "),
                h.code(.{}, "?format=md"),
                h.text(" to any page URL to retrieve the original markdown source. Returns "),
                h.code(.{}, "text/plain"),
                h.text(" content type."),
            }),
            h.h2(.{ .class = "subtitle", .id = "deployment" }, "Deployment"),
            h.p(.{}, .{
                h.text("Deploy anywhere that supports static files or Zig binaries. For detailed Cloudflare Pages setup:"),
            }),
            h.ul(.{}, .{
                h.li(.{}, .{
                    h.a(.{ .href = "/deployment/cloudflare" }, "Cloudflare Pages"),
                }),
            }),
            h.h2(.{ .class = "subtitle", .id = "project-structure" }, "Project Structure"),
            h.p(.{}, .{
                h.text("Nuri generates a clean project layout:"),
            }),
            h.pre(.{}, .{h.code(.{}, "my-site/\n├── content/          # Your Markdown content\n├── public/           # Static assets (CSS, images, fonts)\n├── src/\n│   ├── app/          # Generated Zig pages (don't edit)\n│   └── generated/    # Route table (don't edit)\n├── build.zig         # Zig build configuration\n└── nuri.config.json  # Site metadata")}),
            h.p(.{}, .{
                h.text("The only directories you should edit are "),
                h.code(.{}, "content/"),
                h.text(" (for your writing) and "),
                h.code(.{}, "public/"),
                h.text(" (for custom styles and assets). Everything in "),
                h.code(.{}, "src/"),
                h.text(" is auto-generated and gets overwritten each time you run "),
                h.code(.{}, "nuri build"),
                h.text("."),
            }),
            h.p(.{}, .{
                h.text("When you're ready to deploy, the build process compiles everything into either static HTML files in "),
                h.code(.{}, "dist/"),
                h.text(" (for static hosting) or a binary server at "),
                h.code(.{}, "zig-out/bin/nuri-site"),
                h.text(" (for running your own server)."),
            }),
        }),
    });
}
