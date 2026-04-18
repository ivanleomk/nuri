const std = @import("std");
const parser = @import("parser.zig");
const generator = @import("generator.zig");

const Command = enum {
    init,
    build,
    dev,
    help,
    unknown,
};

pub fn main(init: std.process.Init) !void {
    const args = init.minimal.args;
    
    var iter = args.iterate();
    
    // Skip program name
    _ = iter.next();
    
    const first_arg = iter.next() orelse {
        try printHelp();
        return;
    };

    const cmd = parseCommand(first_arg);

    switch (cmd) {
        .init => {
            const project_name = iter.next() orelse {
                std.debug.print("Error: init requires a project name\n", .{});
                std.debug.print("Usage: nuri init <name>\n", .{});
                return error.MissingProjectName;
            };
            try cmdInit(init, project_name);
        },
        .build => {
            try cmdBuild(init);
        },
        .dev => {
            try cmdDev(init);
        },
        .help => {
            try printHelp();
        },
        .unknown => {
            std.debug.print("Unknown command: {s}\n", .{first_arg});
            try printHelp();
            return error.UnknownCommand;
        },
    }
}

fn parseCommand(arg: []const u8) Command {
    if (std.mem.eql(u8, arg, "init")) return .init;
    if (std.mem.eql(u8, arg, "build")) return .build;
    if (std.mem.eql(u8, arg, "dev")) return .dev;
    if (std.mem.eql(u8, arg, "help") or std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) return .help;
    return .unknown;
}

fn printHelp() !void {
    const help_text =
        \\Nuri - Static site generator for merjs
        \\
        \\Usage: nuri <command> [options]
        \\
        \\Commands:
        \\  init <name>    Create a new project
        \\  build          Build markdown files to merjs
        \\  dev            Watch, rebuild, and auto-restart merjs
        \\  help           Show this help message
        \\
        \\Quick Start:
        \\  nuri init my-site
        \\  cd my-site
        \\  nuri dev      # Watch files, rebuild, and serve on :3000
        \\
        \\The dev command will:
        \\  - Watch content/ for changes
        \\  - Rebuild markdown to src/app/
        \\  - Auto-restart merjs to pick up changes
        \\  - Press Ctrl+C to stop
        \\
    ;
    std.debug.print("{s}", .{help_text});
}

fn cmdInit(init: std.process.Init, name: []const u8) !void {
    const io = init.io;
    const allocator = init.gpa;
    
    std.debug.print("Creating project: {s}\n", .{name});

    const cwd = std.Io.Dir.cwd();
    
    cwd.createDir(io, name, .default_dir) catch |err| {
        if (err == error.PathAlreadyExists) {
            std.debug.print("Error: Directory '{s}' already exists\n", .{name});
            return error.DirectoryExists;
        }
        return err;
    };

    const project_path = try cwd.realPathFileAlloc(io, name, allocator);
    defer allocator.free(project_path);

    const content_dir = try std.fs.path.join(allocator, &.{ project_path, "content" });
    defer allocator.free(content_dir);
    try cwd.createDir(io, content_dir, .default_dir);

    const src_dir = try std.fs.path.join(allocator, &.{ project_path, "src", "app" });
    defer allocator.free(src_dir);
    try cwd.createDirPath(io, src_dir);

    const public_dir = try std.fs.path.join(allocator, &.{ project_path, "public" });
    defer allocator.free(public_dir);
    try cwd.createDir(io, public_dir, .default_dir);

    const sample_md =
        \\---
        \\title: Home
        \\---
        \\
        \\# Welcome to Nuri
        \\
        \\This is your first page with **bold** and *italic* text.
        \\
    ;

    const index_path = try std.fs.path.join(allocator, &.{ content_dir, "index.md" });
    defer allocator.free(index_path);

    try cwd.writeFile(io, .{
        .sub_path = index_path,
        .data = sample_md,
        .flags = .{},
    });

    const config =
        \\{
        \\  "title": "My Nuri Site",
        \\  "description": "A site built with Nuri"
        \\}
        \\
    ;

    const config_path = try std.fs.path.join(allocator, &.{ project_path, "nuri.config.json" });
    defer allocator.free(config_path);

    try cwd.writeFile(io, .{
        .sub_path = config_path,
        .data = config,
        .flags = .{},
    });

    // build.zig.zon
    const build_zig_zon =
        \\.{
        \\    .name = .@"nuri-site",
        \\    .fingerprint = 0xaabbccdd11223344,
        \\    .version = "0.1.0",
        \\    .minimum_zig_version = "0.16.0",
        \\    .dependencies = .{
        \\        .merjs = .{
        \\            .url = "git+https://github.com/ivanleomk/merjs.git#93519ad5fdfbd2350a1ca051a391c3dee60b0b02",
        \\            .hash = "merjs-0.2.5-qL9LkovAYADBMdEWeU1UdlopMdgX_cYo8BTsMjRBVm0Q",
        \\        },
        \\    },
        \\    .paths = .{
        \\        "build.zig",
        \\        "build.zig.zon",
        \\        "src",
        \\    },
        \\}
        \\
    ;

    const build_zig_zon_path = try std.fs.path.join(allocator, &.{ project_path, "build.zig.zon" });
    defer allocator.free(build_zig_zon_path);

    try cwd.writeFile(io, .{
        .sub_path = build_zig_zon_path,
        .data = build_zig_zon,
        .flags = .{},
    });

    // build.zig
    const build_zig =
        \\const std = @import("std");
        \\
        \\pub fn build(b: *std.Build) void {
        \\    const target = b.standardTargetOptions(.{});
        \\    const optimize = b.standardOptimizeOption(.{});
        \\
        \\    const merjs_dep = b.dependency("merjs", .{});
        \\    const mer_mod = merjs_dep.module("mer");
        \\    const runtime_mod = merjs_dep.module("runtime");
        \\
        \\    // Routes module (generated by nuri)
        \\    const routes_mod = b.createModule(.{
        \\        .root_source_file = b.path("src/generated/routes.zig"),
        \\    });
        \\    routes_mod.addImport("mer", mer_mod);
        \\
        \\    // Wire up each page module in src/app/
        \\    var app_dir = std.Io.Dir.cwd().openDir(b.graph.io, "src/app", .{ .iterate = true }) catch {
        \\        std.debug.print("nuri: no src/app/ directory found — run 'nuri build' first.\n", .{});
        \\        return;
        \\    };
        \\    defer app_dir.close(b.graph.io);
        \\
        \\    var walker = app_dir.walk(b.allocator) catch return;
        \\    defer walker.deinit();
        \\    while (walker.next(b.graph.io) catch null) |entry| {
        \\        if (entry.kind != .file) continue;
        \\        if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;
        \\
        \\        const file_path = b.fmt("src/app/{s}", .{entry.path});
        \\        const import_name = b.fmt("app/{s}", .{entry.path[0 .. entry.path.len - 4]});
        \\
        \\        const page_mod = b.createModule(.{ .root_source_file = b.path(file_path) });
        \\        page_mod.addImport("mer", mer_mod);
        \\        routes_mod.addImport(import_name, page_mod);
        \\    }
        \\
        \\    // Main executable
        \\    const main_mod = b.createModule(.{
        \\        .root_source_file = b.path("src/main.zig"),
        \\        .target = target,
        \\        .optimize = optimize,
        \\        .link_libc = true,
        \\    });
        \\    main_mod.addImport("mer", mer_mod);
        \\    main_mod.addImport("runtime", runtime_mod);
        \\    main_mod.addImport("routes", routes_mod);
        \\
        \\    const exe = b.addExecutable(.{ .name = "nuri-site", .root_module = main_mod });
        \\    b.installArtifact(exe);
        \\
        \\    const run_exe = b.addRunArtifact(exe);
        \\    run_exe.step.dependOn(b.getInstallStep());
        \\    if (b.args) |args| run_exe.addArgs(args);
        \\    b.step("serve", "Start the dev server").dependOn(&run_exe.step);
        \\}
        \\
    ;

    const build_zig_path = try std.fs.path.join(allocator, &.{ project_path, "build.zig" });
    defer allocator.free(build_zig_path);

    try cwd.writeFile(io, .{
        .sub_path = build_zig_path,
        .data = build_zig,
        .flags = .{},
    });

    // src/generated/ directory and routes.zig
    const generated_dir = try std.fs.path.join(allocator, &.{ project_path, "src", "generated" });
    defer allocator.free(generated_dir);
    try cwd.createDirPath(io, generated_dir);

    const routes_zig =
        \\// GENERATED by nuri — do not edit by hand.
        \\
        \\const Route = @import("mer").Route;
        \\
        \\pub const routes: []const Route = &.{};
        \\
    ;

    const routes_zig_path = try std.fs.path.join(allocator, &.{ generated_dir, "routes.zig" });
    defer allocator.free(routes_zig_path);

    try cwd.writeFile(io, .{
        .sub_path = routes_zig_path,
        .data = routes_zig,
        .flags = .{},
    });

    // src/main.zig
    const src_main_zig =
        \\const std = @import("std");
        \\const mer = @import("mer");
        \\const runtime = @import("runtime");
        \\
        \\const log = std.log.scoped(.main);
        \\
        \\pub fn main(init: std.process.Init.Minimal) !void {
        \\    var gpa: std.heap.DebugAllocator(.{}) = .init;
        \\    defer _ = gpa.deinit();
        \\    const alloc = gpa.allocator();
        \\
        \\    try runtime.init(alloc);
        \\    defer runtime.deinit();
        \\
        \\    var config = mer.Config{
        \\        .host = "127.0.0.1",
        \\        .port = 3000,
        \\        .dev = true,
        \\    };
        \\
        \\    var arena_state: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
        \\    defer arena_state.deinit();
        \\    const args = try init.args.toSlice(arena_state.allocator());
        \\
        \\    var i: usize = 1;
        \\    while (i < args.len) : (i += 1) {
        \\        if (std.mem.eql(u8, args[i], "--port") and i + 1 < args.len) {
        \\            config.port = try std.fmt.parseInt(u16, args[i + 1], 10);
        \\            i += 1;
        \\        } else if (std.mem.eql(u8, args[i], "--no-dev")) {
        \\            config.dev = false;
        \\        } else if (std.mem.eql(u8, args[i], "--verbose") or std.mem.eql(u8, args[i], "-v")) {
        \\            config.verbose = true;
        \\        }
        \\    }
        \\
        \\    var router = mer.Router.fromGenerated(alloc, @import("routes"));
        \\    defer router.deinit();
        \\
        \\    var watcher = mer.Watcher.init(alloc, "src/app");
        \\    defer watcher.deinit();
        \\
        \\    if (config.dev) {
        \\        const wt = try std.Thread.spawn(.{}, mer.Watcher.run, .{&watcher});
        \\        wt.detach();
        \\        log.info("hot reload active — watching src/app/", .{});
        \\    }
        \\
        \\    var server = mer.Server.init(alloc, config, &router, if (config.dev) &watcher else null);
        \\    try server.listen();
        \\}
        \\
    ;

    const src_main_path = try std.fs.path.join(allocator, &.{ project_path, "src", "main.zig" });
    defer allocator.free(src_main_path);

    try cwd.writeFile(io, .{
        .sub_path = src_main_path,
        .data = src_main_zig,
        .flags = .{},
    });

    std.debug.print("✓ Created project in ./{s}/\n", .{name});
    std.debug.print("✓ Created content/index.md\n", .{});
    std.debug.print("✓ Created src/app/ directory\n", .{});
    std.debug.print("✓ Created public/ directory\n", .{});
    std.debug.print("✓ Created nuri.config.json\n", .{});
    std.debug.print("✓ Created build.zig\n", .{});
    std.debug.print("✓ Created build.zig.zon\n", .{});
    std.debug.print("✓ Created src/main.zig\n", .{});
    std.debug.print("✓ Created src/generated/routes.zig\n", .{});
    std.debug.print("\nNext steps:\n", .{});
    std.debug.print("  cd {s}\n", .{name});
    std.debug.print("  nuri dev      # Watch files, rebuild, and serve on :3000\n", .{});
}

fn cmdBuild(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;
    
    const cwd = std.Io.Dir.cwd();
    
    var content_dir = cwd.openDir(io, "content", .{ .iterate = true }) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("Error: No content/ directory found. Run 'nuri init <name>' first.\n", .{});
            return error.NoContentDirectory;
        }
        return err;
    };
    defer content_dir.close(io);

    // Clean src/app/ so deleted markdown files don't leave stale .zig routes
    try cleanGeneratedFiles(io, allocator);

    cwd.createDirPath(io, "src/app") catch |err| {
        if (err != error.PathAlreadyExists) {
            return err;
        }
    };

    std.debug.print("Building markdown files...\n", .{});

    var walker = try content_dir.walk(allocator);
    defer walker.deinit();

    var file_count: usize = 0;

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.basename, ".md")) continue;

        const content_path = try std.fs.path.join(allocator, &.{ "content", entry.path });
        defer allocator.free(content_path);

        const output_path = blk: {
            const base_name = entry.basename[0 .. entry.basename.len - 3];
            const rel_dir = std.fs.path.dirname(entry.path) orelse "";
            if (rel_dir.len == 0) {
                break :blk try std.fmt.allocPrint(allocator, "src/app/{s}.zig", .{base_name});
            } else {
                break :blk try std.fmt.allocPrint(allocator, "src/app/{s}/{s}.zig", .{ rel_dir, base_name });
            }
        };
        defer allocator.free(output_path);

        try processMarkdownFile(init, content_path, output_path);
        file_count += 1;
        std.debug.print("  ✓ {s} → {s}\n", .{ entry.path, output_path });
    }

    if (file_count == 0) {
        std.debug.print("Warning: No .md files found in content/\n", .{});
    } else {
        std.debug.print("\nBuilt {d} file(s)\n", .{file_count});
    }

    // Ensure content/index.md exists — every site needs a homepage
    _ = cwd.statFile(io, "content/index.md", .{}) catch {
        std.debug.print("Error: content/index.md is required (every site needs a homepage)\n", .{});
        return error.MissingIndexPage;
    };

    // Generate src/generated/routes.zig
    try generateRoutes(init);
}

fn processMarkdownFile(init: std.process.Init, input_path: []const u8, output_path: []const u8) !void {
    const io = init.io;
    const allocator = init.gpa;
    
    const cwd = std.Io.Dir.cwd();
    
    // Read markdown file
    const content = try cwd.readFileAlloc(io, input_path, allocator, .unlimited);
    defer allocator.free(content);

    // Parse markdown
    var doc = try parser.parse(allocator, content);
    defer doc.deinit(allocator);

    // Generate merjs code
    const output = try generator.generate(allocator, doc);
    defer allocator.free(output);

    // Ensure output directory exists
    const output_dir = std.fs.path.dirname(output_path) orelse return error.InvalidPath;
    try cwd.createDirPath(io, output_dir);

    // Write output file
    try cwd.writeFile(io, .{
        .sub_path = output_path,
        .data = output,
        .flags = .{},
    });
}

fn generateRoutes(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;
    const cwd = std.Io.Dir.cwd();

    // Scan src/app/ for .zig files
    var entries = std.ArrayList([]u8).empty;
    defer {
        for (entries.items) |e| allocator.free(e);
        entries.deinit(allocator);
    }

    var app_dir = cwd.openDir(io, "src/app", .{ .iterate = true }) catch return;
    defer app_dir.close(io);

    var walker = try app_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;
        const full = try std.fmt.allocPrint(allocator, "app/{s}", .{entry.path});
        try entries.append(allocator, full);
    }

    // Sort alphabetically
    std.mem.sort([]u8, entries.items, {}, struct {
        fn lessThan(_: void, a: []u8, b: []u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);

    // Build routes.zig content
    var buf = std.ArrayList(u8).empty;
    defer buf.deinit(allocator);

    try buf.appendSlice(allocator,
        \\// GENERATED by nuri — do not edit by hand.
        \\
        \\const Route = @import("mer").Route;
        \\
        \\
    );

    for (entries.items) |path| {
        const ident = try toIdent(allocator, path);
        defer allocator.free(ident);
        const import_name = path[0 .. path.len - 4]; // strip .zig
        try buf.print(allocator, "const {s} = @import(\"{s}\");\n", .{ ident, import_name });
    }

    try buf.appendSlice(allocator, "\npub const routes: []const Route = &.{\n");
    for (entries.items) |path| {
        const ident = try toIdent(allocator, path);
        defer allocator.free(ident);
        const url = try toUrl(allocator, path);
        defer allocator.free(url);
        try buf.print(allocator, "    .{{ .path = \"{s}\", .render = {s}.render, .render_stream = if (@hasDecl({s}, \"renderStream\")) {s}.renderStream else null, .meta = if (@hasDecl({s}, \"meta\")) {s}.meta else .{{}}, .prerender = if (@hasDecl({s}, \"prerender\")) {s}.prerender else false }},\n", .{ url, ident, ident, ident, ident, ident, ident, ident });
    }
    try buf.appendSlice(allocator, "};\n");

    // Ensure output directory exists
    cwd.createDirPath(io, "src/generated") catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    try cwd.writeFile(io, .{
        .sub_path = "src/generated/routes.zig",
        .data = buf.items,
        .flags = .{},
    });

    std.debug.print("  ✓ Generated src/generated/routes.zig ({d} routes)\n", .{entries.items.len});
}

/// "app/about.zig" → "app_about"
fn toIdent(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const without_ext = if (std.mem.endsWith(u8, path, ".zig")) path[0 .. path.len - 4] else path;
    const buf = try allocator.dupe(u8, without_ext);
    for (buf) |*c| {
        if (c.* != '_' and (c.* < 'a' or c.* > 'z') and (c.* < 'A' or c.* > 'Z') and (c.* < '0' or c.* > '9')) {
            c.* = '_';
        }
    }
    return buf;
}

/// URL mapping: app/index.zig → "/", app/about.zig → "/about"
fn toUrl(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const without_ext = if (std.mem.endsWith(u8, path, ".zig")) path[0 .. path.len - 4] else path;

    // Strip "app/" prefix
    const rel = if (std.mem.startsWith(u8, without_ext, "app/"))
        without_ext["app/".len..]
    else
        without_ext;

    if (std.mem.eql(u8, rel, "index")) return allocator.dupe(u8, "/");

    var result = try allocator.alloc(u8, rel.len + 1);
    result[0] = '/';
    @memcpy(result[1..], rel);
    return result;
}

fn cleanGeneratedFiles(io: std.Io, allocator: std.mem.Allocator) !void {
    const cwd = std.Io.Dir.cwd();

    var app_dir = cwd.openDir(io, "src/app", .{ .iterate = true }) catch return;
    defer app_dir.close(io);

    var walker = try app_dir.walk(allocator);
    defer walker.deinit();

    var to_delete = std.ArrayList([]u8).empty;
    defer {
        for (to_delete.items) |p| allocator.free(p);
        to_delete.deinit(allocator);
    }

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;
        const p = try std.fmt.allocPrint(allocator, "src/app/{s}", .{entry.path});
        try to_delete.append(allocator, p);
    }

    for (to_delete.items) |p| {
        cwd.deleteFile(io, p) catch {};
    }
}

fn cmdDev(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;
    
    std.debug.print("🚀 Nuri development mode\n", .{});
    std.debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n", .{});

    // Initial build (markdown → zig + routes.zig)
    try cmdBuild(init);

    std.debug.print("\n🌐 Compiling and starting server...\n", .{});
    std.debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n", .{});
    std.debug.print("📁 Watching content/ directory for changes...\n", .{});
    std.debug.print("Press Ctrl+C to stop\n\n", .{});

    // Set up file watcher
    var last_mtimes = std.StringHashMap(std.Io.Timestamp).init(allocator);
    defer {
        var it = last_mtimes.keyIterator();
        while (it.next()) |key| {
            allocator.free(key.*);
        }
        last_mtimes.deinit();
    }

    try scanDirectory(io, allocator, "content", &last_mtimes);

    // Server process (runs zig-out/bin/nuri-site directly)
    var server_child: ?std.process.Child = null;
    defer if (server_child) |*child| {
        child.kill(io);
    };

    // Compile the project
    const compileProject = struct {
        fn call(io_inner: std.Io) !void {
            std.debug.print("⏳ Compiling...\n", .{});
            var build_child = try std.process.spawn(io_inner, .{
                .argv = &[_][]const u8{ "zig", "build" },
                .stdin = .ignore,
                .stdout = .inherit,
                .stderr = .inherit,
            });
            const term = try build_child.wait(io_inner);
            if (term != .exited or term.exited != 0) {
                return error.CompileFailed;
            }
        }
    }.call;

    // Helper to (re)start the server binary
    const restartServer = struct {
        fn call(io_inner: std.Io, child: *?std.process.Child) !void {
            // Kill existing server if any (kill() reaps the child in zig 0.16)
            if (child.*) |*c| {
                std.debug.print("🔄 Stopping server...\n", .{});
                c.kill(io_inner);
                child.* = null;
            }

            // Run the compiled binary directly
            const argv = &[_][]const u8{ "zig-out/bin/nuri-site" };
            child.* = try std.process.spawn(io_inner, .{
                .argv = argv,
                .stdin = .ignore,
                .stdout = .inherit,
                .stderr = .inherit,
            });
            std.debug.print("✅ Server running at http://localhost:3000\n", .{});
        }
    }.call;

    // Initial compile + start
    try compileProject(io);
    try restartServer(io, &server_child);

    // Watch loop - runs until Ctrl+C
    while (true) {
        try std.Io.sleep(io, .fromNanoseconds(1_000_000_000), .awake);

        var current_mtimes = std.StringHashMap(std.Io.Timestamp).init(allocator);
        defer {
            var it = current_mtimes.keyIterator();
            while (it.next()) |key| {
                allocator.free(key.*);
            }
            current_mtimes.deinit();
        }

        try scanDirectory(io, allocator, "content", &current_mtimes);

        var changed = false;
        var it = current_mtimes.iterator();
        while (it.next()) |entry| {
            const path = entry.key_ptr.*;
            const mtime = entry.value_ptr.*;

            const prev_mtime = last_mtimes.get(path);
            if (prev_mtime == null or !std.meta.eql(prev_mtime.?, mtime)) {
                changed = true;
                std.debug.print("📝 Change detected: {s}\n", .{path});
            }
        }

        // Also detect deleted files
        var deleted = false;
        var old_check = last_mtimes.iterator();
        while (old_check.next()) |entry| {
            if (!current_mtimes.contains(entry.key_ptr.*)) {
                changed = true;
                deleted = true;
                std.debug.print("🗑️  Deleted: {s}\n", .{entry.key_ptr.*});
            }
        }

        if (changed) {
            std.debug.print("🔄 Rebuilding...\n", .{});
            cmdBuild(init) catch |err| {
                std.debug.print("❌ Build failed: {any}\n", .{err});
                continue;
            };
            
            // Recompile + restart server to pick up new routes
            compileProject(io) catch |err| {
                std.debug.print("❌ Compile failed: {any}\n", .{err});
                continue;
            };
            restartServer(io, &server_child) catch |err| {
                std.debug.print("❌ Server start failed: {any}\n", .{err});
                continue;
            };

            var old_it = last_mtimes.keyIterator();
            while (old_it.next()) |key| {
                allocator.free(key.*);
            }
            last_mtimes.clearRetainingCapacity();

            var new_it = current_mtimes.iterator();
            while (new_it.next()) |entry| {
                const key_copy = try allocator.dupe(u8, entry.key_ptr.*);
                try last_mtimes.put(key_copy, entry.value_ptr.*);
            }
        }
    }
}

fn scanDirectory(io: std.Io, allocator: std.mem.Allocator, dir_path: []const u8, mtimes: *std.StringHashMap(std.Io.Timestamp)) !void {
    const cwd = std.Io.Dir.cwd();
    
    var dir = cwd.openDir(io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(io);

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (walker.next(io) catch return) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.basename, ".md")) continue;

        const full_path = std.fs.path.join(allocator, &.{ dir_path, entry.path }) catch continue;
        defer allocator.free(full_path);
        
        const stat = cwd.statFile(io, full_path, .{}) catch continue;

        const key = allocator.dupe(u8, full_path) catch continue;
        mtimes.put(key, stat.mtime) catch {
            allocator.free(key);
            continue;
        };
    }
}
