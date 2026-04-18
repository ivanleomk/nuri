const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Home",
};

const page_node = page();

pub fn render(req: mer.Request) mer.Response {
    return mer.render(req.allocator, page_node);
}

fn page() h.Node {
    return h.div(.{ .class = "page" }, .{
        h.h1(.{ .class = "title" }, "Welcome to Nuri"),
        h.p(.{}, .{
            h.text("This is your first page with "),
            h.strong(.{}, "bold"),
            h.text(" and "),
            h.em(.{}, "italic"),
            h.text(" text."),
        }),
        h.p(.{}, .{
            h.text("Check out "),
            h.a(.{ .href = "/about" }, "this link"),
            h.text("."),
        }),
    });
}
