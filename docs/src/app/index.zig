const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Nuri - Static Site Generator for merjs",
    .description = "Convert Markdown to type-safe Zig web pages",
};

const page_node = page();

pub fn render(req: mer.Request) mer.Response {
    return mer.render(req.allocator, page_node);
}

fn page() h.Node {
    return h.div(.{ .class = "page" }, .{
        h.h1(.{ .class = "title" }, "Nuri"),
        h.p(.{}, .{
            h.text("A static site generator that converts Markdown to "),
            h.a(.{ .href = "https://github.com/ivanleomk/merjs" }, "merjs"),
            h.text(" pages."),
        }),
        h.p(.{}, .{
            h.text("Write your content in Markdown, and Nuri generates type-safe Zig code with routing, hot reload, and semantic HTML — all powered by merjs."),
        }),
        h.h2(.{ .class = "subtitle" }, "Quick Start"),
        h.p(.{}, .{
            h.text("Install the latest binary:"),
        }),
        h.pre(.{}, .{h.code(.{}, "curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri\nchmod +x nuri\nsudo mv nuri /usr/local/bin/")}),
        h.p(.{}, .{
            h.text("Create and run a project:"),
        }),
        h.pre(.{}, .{h.code(.{}, "nuri init my-site\ncd my-site\nnuri dev")}),
        h.p(.{}, .{
            h.text("Open "),
            h.strong(.{}, "http://localhost:3000"),
            h.text(" to see your site."),
        }),
        h.h2(.{ .class = "subtitle" }, "How It Works"),
        h.pre(.{}, .{h.code(.{}, "content/           →  nuri build  →  src/app/            →  zig build  →  binary\n  index.md                           index.zig\n  about.md                           about.zig\n  blog/first.md                      blog/first.zig\n                                   src/generated/\n                                     routes.zig")}),
        h.ol(.{}, .{
            h.li(.{}, .{
                h.text("You write Markdown in "),
                h.code(.{}, "content/"),
            }),
            h.li(.{}, .{
                h.code(.{}, "nuri build"),
                h.text(" generates a merjs page module in "),
                h.code(.{}, "src/app/"),
                h.text(" for each file"),
            }),
            h.li(.{}, .{
                h.text("It also generates "),
                h.code(.{}, "src/generated/routes.zig"),
                h.text(" with all routes wired up"),
            }),
            h.li(.{}, .{
                h.code(.{}, "zig build"),
                h.text(" compiles everything into a single binary server"),
            }),
        }),
        h.h2(.{ .class = "subtitle" }, "Learn More"),
        h.ul(.{}, .{
            h.li(.{}, .{
                h.a(.{ .href = "/install" }, "Installation"),
                h.text(" — download or build from source"),
            }),
            h.li(.{}, .{
                h.a(.{ .href = "/guide" }, "Writing Content"),
                h.text(" — Markdown, frontmatter, and routing"),
            }),
            h.li(.{}, .{
                h.a(.{ .href = "/commands" }, "Commands"),
                h.text(" — CLI reference"),
            }),
        }),
    });
}
