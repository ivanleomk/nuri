const std = @import("std");
const mer = @import("mer");
const routes = @import("routes");

pub fn wrap(allocator: std.mem.Allocator, path: []const u8, body: []const u8, meta: mer.Meta) []const u8 {
    const title = if (meta.title.len > 0) meta.title else if (std.mem.eql(u8, path, "/")) "Home" else if (path.len > 1) path[1..] else "Nuri";
    const desc = if (meta.description.len > 0) meta.description else "Built with Nuri";

    var buf: std.ArrayList(u8) = .empty;

    buf.appendSlice(allocator,
        \\<!DOCTYPE html>
        \\<html lang="en">
        \\<head>
        \\  <meta charset="UTF-8">
        \\  <meta name="viewport" content="width=device-width, initial-scale=1.0">
        \\  <link rel="stylesheet" href="/styles.css">
        \\
    ) catch return body;

    buf.print(allocator, "  <title>{s}</title>\n", .{title}) catch return body;
    buf.print(allocator, "  <meta name=\"description\" content=\"{s}\">\n", .{desc}) catch return body;

    if (meta.extra_head) |extra| {
        buf.appendSlice(allocator, extra) catch {};
        buf.appendSlice(allocator, "\n") catch {};
    }

    buf.appendSlice(allocator,
        \\</head>
        \\<body>
        \\<div class="layout">
        \\  <aside class="route-sidebar-container">
        \\    
    ) catch return body;

    buf.appendSlice(allocator, routes.sidebarHtml(path)) catch return body;
    
    buf.appendSlice(allocator,
        \\  </aside>
        \\  <main class="main-content">
        \\    
    ) catch return body;

    buf.appendSlice(allocator, body) catch return body;

    buf.appendSlice(allocator,
        \\  </main>
        \\</div>
        \\</body>
        \\</html>
    ) catch return body;

    return buf.items;
}