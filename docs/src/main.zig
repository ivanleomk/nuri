const std = @import("std");
const mer = @import("mer");
const runtime = @import("runtime");

const log = std.log.scoped(.main);

pub fn main(init: std.process.Init.Minimal) !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    try runtime.init(alloc);
    defer runtime.deinit();

    // Check for prerender mode
    const args = try init.args.toSlice(alloc);
    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--prerender")) {
            std.debug.print("Prerendering static site to dist/...\n", .{});
            var router = mer.Router.fromGenerated(alloc, @import("routes"));
            defer router.deinit();
            try mer.runPrerender(alloc, &router);
            return;
        }
    }

    var config = mer.Config{
        .host = "127.0.0.1",
        .port = 3000,
        .dev = true,
    };

    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena_args = try init.args.toSlice(arena_state.allocator());

    var i: usize = 1;
    while (i < arena_args.len) : (i += 1) {
        if (std.mem.eql(u8, arena_args[i], "--port") and i + 1 < arena_args.len) {
            config.port = try std.fmt.parseInt(u16, arena_args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, arena_args[i], "--no-dev")) {
            config.dev = false;
        } else if (std.mem.eql(u8, arena_args[i], "--verbose") or std.mem.eql(u8, arena_args[i], "-v")) {
            config.verbose = true;
        }
    }

    var router = mer.Router.fromGenerated(alloc, @import("routes"));
    defer router.deinit();

    var watcher = mer.Watcher.init(alloc, "src/app");
    defer watcher.deinit();

    if (config.dev) {
        const wt = try std.Thread.spawn(.{}, mer.Watcher.run, .{&watcher});
        wt.detach();
        log.info("hot reload active — watching src/app/", .{});
    }

    var server = mer.Server.init(alloc, config, &router, if (config.dev) &watcher else null);
    try server.listen();
}