const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Commands",
    .description = "Nuri CLI commands reference",
};

const page_node = page();

pub fn render(req: mer.Request) mer.Response {
    return mer.render(req.allocator, page_node);
}

fn page() h.Node {
    return h.div(.{ .class = "page" }, .{
        h.h1(.{ .class = "title" }, "Commands"),
        h.h2(.{ .class = "subtitle" }, "nuri init"),
        h.p(.{}, .{
            h.text("Create a new project:"),
        }),
        h.pre(.{}, .{h.code(.{}, "nuri init my-site")}),
        h.p(.{}, .{
            h.text("This scaffolds the full project structure including "),
            h.code(.{}, "build.zig"),
            h.text(", "),
            h.code(.{}, "src/main.zig"),
            h.text(", and a sample "),
            h.code(.{}, "content/index.md"),
            h.text("."),
        }),
        h.h2(.{ .class = "subtitle" }, "nuri build"),
        h.p(.{}, .{
            h.text("Convert Markdown files to merjs page modules:"),
        }),
        h.pre(.{}, .{h.code(.{}, "nuri build")}),
        h.p(.{}, .{
            h.text("Parses each "),
            h.code(.{}, ".md"),
            h.text(" file in "),
            h.code(.{}, "content/"),
            h.text(" and generates corresponding "),
            h.code(.{}, ".zig"),
            h.text(" files in "),
            h.code(.{}, "src/app/"),
            h.text(", plus "),
            h.code(.{}, "src/generated/routes.zig"),
            h.text("."),
        }),
        h.h2(.{ .class = "subtitle" }, "nuri dev"),
        h.p(.{}, .{
            h.text("Watch, rebuild, recompile, and serve:"),
        }),
        h.pre(.{}, .{h.code(.{}, "nuri dev")}),
        h.p(.{}, .{
            h.text("This command:"),
        }),
        h.ol(.{}, .{
            h.li(.{}, .{
                h.text("Runs an initial "),
                h.code(.{}, "nuri build"),
            }),
            h.li(.{}, .{
                h.text("Compiles the project with "),
                h.code(.{}, "zig build"),
            }),
            h.li(.{}, .{
                h.text("Starts the server on "),
                h.strong(.{}, "http://localhost:3000"),
            }),
            h.li(.{}, .{
                h.text("Watches "),
                h.code(.{}, "content/"),
                h.text(" for changes"),
            }),
            h.li(.{}, "Automatically rebuilds, recompiles, and restarts on changes"),
        }),
        h.p(.{}, .{
            h.text("Press "),
            h.strong(.{}, "Ctrl+C"),
            h.text(" to stop."),
        }),
        h.h2(.{ .class = "subtitle" }, "nuri help"),
        h.p(.{}, .{
            h.text("Show usage information:"),
        }),
        h.pre(.{}, .{h.code(.{}, "nuri help")}),
        h.p(.{}, .{
            h.a(.{ .href = "/guide" }, "← Writing Content"),
            h.text(" · "),
            h.a(.{ .href = "/" }, "Home"),
        }),
    });
}
