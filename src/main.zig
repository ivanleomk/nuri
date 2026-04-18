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
        \\  dev            Watch files and rebuild on changes
        \\  help           Show this help message
        \\
        \\Examples:
        \\  nuri init my-site
        \\  nuri build
        \\  nuri dev
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
        \\Check out [this link](./about.md).
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

    std.debug.print("✓ Created project in ./{s}/\n", .{name});
    std.debug.print("✓ Created content/index.md\n", .{});
    std.debug.print("✓ Created src/app/ directory\n", .{});
    std.debug.print("✓ Created public/ directory\n", .{});
    std.debug.print("✓ Created nuri.config.json\n", .{});
    std.debug.print("\nNext steps:\n", .{});
    std.debug.print("  cd {s}\n", .{name});
    std.debug.print("  nuri build\n", .{});
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

fn cmdDev(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.gpa;
    
    std.debug.print("🚀 Nuri development mode\n", .{});
    std.debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n", .{});

    try cmdBuild(init);

    std.debug.print("\n📁 Watching content/ directory for changes\n", .{});
    std.debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});
    std.debug.print("\n💡 To view your site:\n", .{});
    std.debug.print("   Run: mer serve\n", .{});
    std.debug.print("   Then: http://localhost:3000\n", .{});
    std.debug.print("\n✏️  Edit files in content/ and they will auto-rebuild\n\n", .{});

    var last_mtimes = std.StringHashMap(std.Io.Timestamp).init(allocator);
    defer {
        var it = last_mtimes.keyIterator();
        while (it.next()) |key| {
            allocator.free(key.*);
        }
        last_mtimes.deinit();
    }

    try scanDirectory(io, allocator, "content", &last_mtimes);

    while (true) {
        try std.Io.sleep(io, .{ .nanoseconds = 1_000_000_000 }, .awake);

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
            if (prev_mtime == null or prev_mtime.?.nanoseconds != mtime.nanoseconds) {
                changed = true;
                std.debug.print("\nChange detected: {s}\n", .{path});
            }
        }

        if (changed) {
            std.debug.print("🔄 Rebuilding...\n", .{});
            cmdBuild(init) catch |err| {
                std.debug.print("❌ Build failed: {any}\n", .{err});
            };
            std.debug.print("✅ Done! Reload your browser to see changes\n\n", .{});

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
        
        const stat = cwd.statFile(io, full_path, .{}) catch {
            allocator.free(full_path);
            continue;
        };

        const key = allocator.dupe(u8, full_path) catch continue;
        mtimes.put(key, stat.mtime) catch {
            allocator.free(key);
            continue;
        };
    }
}
