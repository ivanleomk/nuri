const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Nuri - Documentation",
    .description = "Complete guide to Nuri static site generator",
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
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#installation" }, "Installation")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#pre-built-binary-macos-apple-silicon" }, "Pre-built Binary (macOS Apple Silicon)")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#build-from-source" }, "Build from Source")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#quick-start" }, "Quick Start")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#how-it-works" }, "How It Works")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#commands" }, "Commands")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#writing-content" }, "Writing Content")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#file-based-routing" }, "File-based Routing")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#frontmatter" }, "Frontmatter")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#supported-markdown" }, "Supported Markdown")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#project-structure" }, "Project Structure")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#deployment" }, "Deployment")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#customization" }, "Customization")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#agent-skill" }, "Agent Skill")}),
            }),
        }),
        h.div(.{ .class = "page-content" }, .{
            h.h1(.{ .class = "title", .id = "nuri" }, "Nuri"),
            h.p(.{}, .{
                h.text("A static site generator that converts Markdown to "),
                h.a(.{ .href = "https://github.com/ivanleomk/merjs" }, "merjs"),
                h.text(" pages."),
            }),
            h.p(.{}, .{
                h.text("Write your content in Markdown, and Nuri generates type-safe Zig code with routing, hot reload, and semantic HTML — all powered by merjs. Deploy to Cloudflare Workers, VPS, or anywhere."),
            }),
            h.p(.{}, .{
                h.text("🚀 Successfully deployed via Cloudflare Workers with auto-installed Zig 0.16.0!"),
            }),
            h.h2(.{ .class = "subtitle", .id = "installation" }, "Installation"),
            h.h3(.{ .class = "heading", .id = "pre-built-binary-macos-apple-silicon" }, "Pre-built Binary (macOS Apple Silicon)"),
            h.pre(.{}, .{h.code(.{}, "curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri\nchmod +x nuri\nsudo mv nuri /usr/local/bin/")}),
            h.h3(.{ .class = "heading", .id = "build-from-source" }, "Build from Source"),
            h.p(.{}, .{
                h.text("Requires "),
                h.a(.{ .href = "https://ziglang.org/download/" }, "Zig 0.16+"),
                h.text(":"),
            }),
            h.pre(.{}, .{h.code(.{}, "git clone https://github.com/ivanleomk/nuri.git\ncd nuri\nzig build -Doptimize=ReleaseSafe\n# Binary is at zig-out/bin/nuri")}),
            h.h2(.{ .class = "subtitle", .id = "quick-start" }, "Quick Start"),
            h.pre(.{}, .{h.code(.{}, "nuri init my-site\ncd my-site\nnuri dev")}),
            h.p(.{}, .{
                h.text("Open "),
                h.strong(.{}, "http://localhost:3000"),
                h.text(" to see your site."),
            }),
            h.h2(.{ .class = "subtitle", .id = "how-it-works" }, "How It Works"),
            h.pre(.{}, .{h.code(.{}, "content/           →  nuri build  →  src/app/            →  zig build  →  binary\n  index.md                           index.zig\n  about.md                           about.zig\n  blog/first.md                      blog/first.zig\n                                    src/generated/\n                                      routes.zig")}),
            h.ol(.{}, .{
                h.li(.{}, .{
                    h.text("Write Markdown in "),
                    h.code(.{}, "content/"),
                }),
                h.li(.{}, .{
                    h.code(.{}, "nuri build"),
                    h.text(" generates merjs page modules in "),
                    h.code(.{}, "src/app/"),
                }),
                h.li(.{}, .{
                    h.code(.{}, "src/generated/routes.zig"),
                    h.text(" is auto-generated with all routes"),
                }),
                h.li(.{}, .{
                    h.code(.{}, "zig build"),
                    h.text(" compiles to a single binary server"),
                }),
            }),
            h.h2(.{ .class = "subtitle", .id = "commands" }, "Commands"),
            h.table(.{}, .{
                h.thead(.{}, .{h.tr(.{}, .{
                    h.th(.{}, "Command"),
                    h.th(.{}, "Description"),
                })}),
                h.tbody(.{}, .{
                    h.tr(.{}, .{
                        h.td(.{}, "`nuri init <name>`"),
                        h.td(.{}, "Create new project"),
                    }),
                    h.tr(.{}, .{
                        h.td(.{}, "`nuri build`"),
                        h.td(.{}, "Convert Markdown to merjs pages"),
                    }),
                    h.tr(.{}, .{
                        h.td(.{}, "`nuri dev`"),
                        h.td(.{}, "Watch, rebuild, and serve on :3000"),
                    }),
                    h.tr(.{}, .{
                        h.td(.{}, "`nuri help`"),
                        h.td(.{}, "Show help"),
                    }),
                }),
            }),
            h.h2(.{ .class = "subtitle", .id = "writing-content" }, "Writing Content"),
            h.h3(.{ .class = "heading", .id = "file-based-routing" }, "File-based Routing"),
            h.p(.{}, .{
                h.text("Each Markdown file in "),
                h.code(.{}, "content/"),
                h.text(" becomes a route:"),
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
                        h.td(.{}, "`content/blog/first.md`"),
                        h.td(.{}, "`/blog/first`"),
                    }),
                }),
            }),
            h.p(.{}, .{
                h.text("Every site "),
                h.strong(.{}, "must"),
                h.text(" have "),
                h.code(.{}, "content/index.md"),
                h.text(" (homepage)."),
            }),
            h.h3(.{ .class = "heading", .id = "frontmatter" }, "Frontmatter"),
            h.p(.{}, .{
                h.text("Add metadata at the top of Markdown files:"),
            }),
            h.pre(.{}, .{h.code(.{}, "---\ntitle: About Us\ndescription: Learn more about our team\n---\n\n# About Us\n\nYour content here...")}),
            h.h3(.{ .class = "heading", .id = "supported-markdown" }, "Supported Markdown"),
            h.ul(.{}, .{
                h.li(.{}, .{
                    h.text("Headings ("),
                    h.code(.{}, "# H1"),
                    h.text(" through "),
                    h.code(.{}, "###### H6"),
                    h.text(")"),
                }),
                h.li(.{}, "Paragraphs"),
                h.li(.{}, .{
                    h.strong(.{}, "Bold"),
                    h.text(" and "),
                    h.em(.{}, "italic"),
                    h.text(" text"),
                }),
                h.li(.{}, .{
                    h.code(.{}, "Inline code"),
                }),
                h.li(.{}, "Code blocks with language hints"),
                h.li(.{}, "Unordered and ordered lists"),
                h.li(.{}, .{
                    h.a(.{ .href = "https://example.com" }, "Links"),
                    h.text(" — local "),
                    h.code(.{}, ".md"),
                    h.text(" links auto-transform to routes"),
                }),
            }),
            h.h2(.{ .class = "subtitle", .id = "project-structure" }, "Project Structure"),
            h.pre(.{}, .{h.code(.{}, "my-site/\n├── build.zig              # Zig build configuration\n├── build.zig.zon          # Dependencies\n├── nuri.config.json       # Site metadata\n├── content/               # Markdown files\n│   └── index.md\n├── public/               # Static assets (CSS, images)\n└── src/\n    ├── main.zig          # Server entry point\n    ├── app/              # Generated page modules\n    └── generated/\n        └── routes.zig    # Auto-generated routes")}),
            h.h2(.{ .class = "subtitle", .id = "deployment" }, "Deployment"),
            h.p(.{}, .{
                h.text("See the "),
                h.a(.{ .href = "/deployment" }, "deployment guide"),
                h.text(" for detailed instructions on deploying to Cloudflare Workers, VPS, or static hosts."),
            }),
            h.h2(.{ .class = "subtitle", .id = "customization" }, "Customization"),
            h.p(.{}, .{
                h.text("Edit "),
                h.code(.{}, "public/styles.css"),
                h.text(" to customize styling — this file won't be overwritten."),
            }),
            h.h2(.{ .class = "subtitle", .id = "agent-skill" }, "Agent Skill"),
            h.p(.{}, .{
                h.text("Nuri includes a Vercel Agent Skill for AI assistants. Install it with:"),
            }),
            h.pre(.{}, .{h.code(.{}, "npx skills add https://github.com/ivanleomk/nuri/tree/main/nuri")}),
            h.p(.{}, .{
                h.text("The skill provides project patterns, routing conventions, development workflows, and deployment configurations for AI tools that support the "),
                h.a(.{ .href = "https://agentskills.io/specification" }, "Agent Skills standard"),
                h.text("."),
            }),
            h.p(.{}, .{
                h.strong(.{}, "GitHub:"),
                h.text(" "),
                h.a(.{ .href = "https://github.com/ivanleomk/nuri" }, "github.com/ivanleomk/nuri"),
            }),
        }),
    });
}
