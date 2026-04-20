const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Deployment",
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
                h.li(.{ .class = "toc-h1" }, .{h.a(.{ .href = "#welcome-to-nuri" }, "Welcome to Nuri")}),
            }),
        }),
        h.div(.{ .class = "page-content" }, .{
            h.h1(.{ .class = "title", .id = "welcome-to-nuri" }, "Welcome to Nuri"),
            h.p(.{}, .{
                h.text("This is how to deploy stuff"),
            }),
        }),
    });
}
