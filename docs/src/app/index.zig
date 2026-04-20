const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Nuri",
    .description = "A static site generator that converts Markdown to merjs pages",
};

const page_node = page();

pub fn render(req: mer.Request) mer.Response {
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
