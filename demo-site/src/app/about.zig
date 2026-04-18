const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "About Us",
};

const page_node = page();

pub fn render(req: mer.Request) mer.Response {
    return mer.render(req.allocator, page_node);
}

fn page() h.Node {
    return h.div(.{ .class = "page" }, .{
        h.h1(.{ .class = "title" }, "About This Site"),
        h.p(.{}, .{
            h.text("This is a "),
            h.strong(.{}, "demo site"),
            h.text(" built with Nuri!"),
        }),
        h.h2(.{ .class = "subtitle" }, "Features"),
        h.ul(.{}, .{
            h.li(.{}, "Fast static site generation"),
            h.li(.{}, "Markdown to merjs conversion"),
            h.li(.{}, "Hot reload during development"),
            h.li(.{}, "Clean, semantic HTML output"),
        }),
        h.h2(.{ .class = "subtitle" }, "Code Example"),
        h.pre(.{}, .{h.code(.{}, "const std = @import(\"std\");\n\npub fn main() void {\n    std.debug.print(\"Hello from Zig!\\n\", .{});\n}")}),
        h.p(.{}, .{
            h.text("Learn more on "),
            h.a(.{ .href = "/index" }, "the homepage"),
            h.text("."),
        }),
    });
}
