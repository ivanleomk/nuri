const std = @import("std");
const ast = @import("ast.zig");

pub const Generator = struct {
    allocator: std.mem.Allocator,
    output: std.ArrayList(u8),

    pub fn init(allocator: std.mem.Allocator) Generator {
        return .{
            .allocator = allocator,
            .output = .empty,
        };
    }

    pub fn deinit(self: *Generator) void {
        self.output.deinit(self.allocator);
    }

    pub fn generate(self: *Generator, document: ast.Document) ![]const u8 {
        try self.generateMeta(document.meta);
        try self.output.appendSlice(self.allocator, "\n");
        try self.output.appendSlice(self.allocator, "pub fn render() !mer.Node {\n");
        try self.output.appendSlice(self.allocator, "    return mer.html(.{}, .{\n");

        for (document.content) |node| {
            try self.generateNode(node, 2);
        }

        try self.output.appendSlice(self.allocator, "    });\n");
        try self.output.appendSlice(self.allocator, "}\n");

        return try self.output.toOwnedSlice(self.allocator);
    }

    fn generateMeta(self: *Generator, meta: ast.Meta) !void {
        try self.output.appendSlice(self.allocator, "pub const meta = .{\n");
        if (meta.title) |title| {
            try self.output.appendSlice(self.allocator, "    .title = \"");
            try self.writeEscaped(title);
            try self.output.appendSlice(self.allocator, "\",\n");
        }
        if (meta.description) |desc| {
            try self.output.appendSlice(self.allocator, "    .description = \"");
            try self.writeEscaped(desc);
            try self.output.appendSlice(self.allocator, "\",\n");
        }
        try self.output.appendSlice(self.allocator, "};\n");
    }

    fn generateNode(self: *Generator, node: ast.Node, depth: usize) !void {
        try self.writeIndent(depth);

        switch (node) {
            .heading => |h| {
                const tag = switch (h.level) {
                    1 => "h1", 2 => "h2", 3 => "h3",
                    4 => "h4", 5 => "h5", 6 => "h6",
                    else => "h1",
                };
                try self.output.appendSlice(self.allocator, "mer.");
                try self.output.appendSlice(self.allocator, tag);
                try self.output.appendSlice(self.allocator, "(.{}, \"");
                for (h.content) |inline_node| {
                    try self.generateInline(inline_node);
                }
                try self.output.appendSlice(self.allocator, "\"),\n");
            },
            .paragraph => |p| {
                if (p.len == 1 and p[0] == .text) {
                    try self.output.appendSlice(self.allocator, "mer.p(.{}, \"");
                    try self.generateInline(p[0]);
                    try self.output.appendSlice(self.allocator, "\"),\n");
                } else {
                    try self.output.appendSlice(self.allocator, "mer.p(.{}, .{\n");
                    for (p) |inline_node| {
                        try self.writeIndent(depth + 1);
                        try self.output.appendSlice(self.allocator, "\"");
                        try self.generateInline(inline_node);
                        try self.output.appendSlice(self.allocator, "\",\n");
                    }
                    try self.writeIndent(depth);
                    try self.output.appendSlice(self.allocator, "}),\n");
                }
            },
            .list => |l| {
                const tag = if (l.ordered) "ol" else "ul";
                try self.output.appendSlice(self.allocator, "mer.");
                try self.output.appendSlice(self.allocator, tag);
                try self.output.appendSlice(self.allocator, "(.{}, .{\n");
                for (l.items) |item| {
                    try self.writeIndent(depth + 1);
                    try self.output.appendSlice(self.allocator, "mer.li(.{}, \"");
                    if (item == .list_item) {
                        for (item.list_item) |inline_node| {
                            try self.generateInline(inline_node);
                        }
                    }
                    try self.output.appendSlice(self.allocator, "\"),\n");
                }
                try self.writeIndent(depth);
                try self.output.appendSlice(self.allocator, "}),\n");
            },
            .code_block => |cb| {
                try self.output.appendSlice(self.allocator, "mer.pre(.{}, mer.code(.{}, \"");
                try self.writeEscaped(cb.content);
                try self.output.appendSlice(self.allocator, "\")),\n");
            },
            else => {},
        }
    }

    fn generateInline(self: *Generator, node: ast.Node) !void {
        switch (node) {
            .text => |s| try self.writeEscaped(s),
            .bold => |b| {
                try self.output.appendSlice(self.allocator, "\", mer.strong(.{}, \"");
                for (b) |n| try self.generateInline(n);
                try self.output.appendSlice(self.allocator, "\"), \"");
            },
            .italic => |i| {
                try self.output.appendSlice(self.allocator, "\", mer.em(.{}, \"");
                for (i) |n| try self.generateInline(n);
                try self.output.appendSlice(self.allocator, "\"), \"");
            },
            .code => |s| {
                try self.output.appendSlice(self.allocator, "\", mer.code(.{}, \"");
                try self.writeEscaped(s);
                try self.output.appendSlice(self.allocator, "\"), \"");
            },
            .link => |l| {
                try self.output.appendSlice(self.allocator, "\", mer.a(.{.href = \"");
                try self.output.appendSlice(self.allocator, l.url);
                try self.output.appendSlice(self.allocator, "\"}, \"");
                try self.output.appendSlice(self.allocator, l.text);
                try self.output.appendSlice(self.allocator, "\"), \"");
            },
            else => {},
        }
    }

    fn writeIndent(self: *Generator, depth: usize) !void {
        var i: usize = 0;
        while (i < depth) : (i += 1) {
            try self.output.appendSlice(self.allocator, "    ");
        }
    }

    fn writeEscaped(self: *Generator, text: []const u8) !void {
        for (text) |c| {
            switch (c) {
                '\\' => try self.output.appendSlice(self.allocator, "\\\\"),
                '"' => try self.output.appendSlice(self.allocator, "\\\""),
                '\n' => try self.output.appendSlice(self.allocator, "\\n"),
                else => try self.output.append(self.allocator, c),
            }
        }
    }
};

pub fn generate(allocator: std.mem.Allocator, document: ast.Document) ![]const u8 {
    var gen = Generator.init(allocator);
    defer gen.deinit();
    return try gen.generate(document);
}
