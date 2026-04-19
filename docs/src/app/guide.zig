const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Writing Content",
    .description = "How to write Markdown content for Nuri",
};

const page_node = page();

pub fn render(req: mer.Request) mer.Response {
    return mer.render(req.allocator, page_node);
}

fn page() h.Node {
    return h.div(.{ .class = "page" }, .{
        h.h1(.{ .class = "title" }, "Writing Content"),
        h.h2(.{ .class = "subtitle" }, "File-based Routing"),
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
            h.text(" have a "),
            h.code(.{}, "content/index.md"),
            h.text(" — this is your homepage."),
        }),
        h.h2(.{ .class = "subtitle" }, "Frontmatter"),
        h.p(.{}, .{
            h.text("Add metadata at the top of your Markdown files:"),
        }),
        h.pre(.{}, .{h.code(.{}, "---\ntitle: About Us\ndescription: Learn more about our team\n---\n\n# About Us\n\nYour content here...")}),
        h.h2(.{ .class = "subtitle" }, "Supported Markdown"),
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
                h.text(" links are auto-transformed to routes"),
            }),
        }),
        h.p(.{}, .{
            h.a(.{ .href = "/install" }, "← Installation"),
            h.text(" · "),
            h.a(.{ .href = "/commands" }, "Commands →"),
        }),
    });
}
