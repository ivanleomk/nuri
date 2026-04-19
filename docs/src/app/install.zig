const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Installation",
    .description = "How to install Nuri",
};

const page_node = page();

pub fn render(req: mer.Request) mer.Response {
    return mer.render(req.allocator, page_node);
}

fn page() h.Node {
    return h.div(.{ .class = "page" }, .{
        h.h1(.{ .class = "title" }, "Installation"),
        h.p(.{}, .{
            h.text("These are instructions on how to use MerjS"),
        }),
        h.h2(.{ .class = "subtitle" }, "Pre-built Binary (macOS Apple Silicon)"),
        h.pre(.{}, .{h.code(.{}, "curl -L https://github.com/ivanleomk/nuri/releases/latest/download/nuri-aarch64-macos -o nuri\nchmod +x nuri\nsudo mv nuri /usr/local/bin/")}),
        h.h2(.{ .class = "subtitle" }, "Build from Source"),
        h.p(.{}, .{
            h.text("Requires "),
            h.a(.{ .href = "https://ziglang.org/download/" }, "Zig 0.16+"),
            h.text(":"),
        }),
        h.pre(.{}, .{h.code(.{}, "git clone https://github.com/ivanleomk/nuri.git\ncd nuri\nzig build -Doptimize=ReleaseSafe")}),
        h.p(.{}, .{
            h.text("The binary is at "),
            h.code(.{}, "zig-out/bin/nuri"),
            h.text("."),
        }),
        h.h2(.{ .class = "subtitle" }, "Requirements"),
        h.ul(.{}, .{
            h.li(.{}, .{
                h.strong(.{}, "Zig 0.16+"),
                h.text(" — needed to compile generated projects"),
            }),
        }),
        h.p(.{}, .{
            h.a(.{ .href = "/" }, "← Home"),
            h.text(" · "),
            h.a(.{ .href = "/guide" }, "Writing Content →"),
        }),
    });
}
