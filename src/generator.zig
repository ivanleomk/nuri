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
        // Imports
        try self.output.appendSlice(self.allocator, "const mer = @import(\"mer\");\n");
        try self.output.appendSlice(self.allocator, "const h = mer.h;\n\n");
        
        // Meta block
        try self.generateMeta(document.meta);
        try self.output.appendSlice(self.allocator, "\n");
        
        // Pre-rendered page node
        try self.output.appendSlice(self.allocator, "const page_node = page();\n\n");
        
        // Render function
        try self.output.appendSlice(self.allocator, "pub fn render(req: mer.Request) mer.Response {\n");
        try self.output.appendSlice(self.allocator, "    return mer.render(req.allocator, page_node);\n");
        try self.output.appendSlice(self.allocator, "}\n\n");
        
        // Page function
        try self.output.appendSlice(self.allocator, "fn page() h.Node {\n");
        try self.output.appendSlice(self.allocator, "    return h.div(.{ .class = \"page\" }, .{\n");
        
        // Generate document content
        for (document.content) |node| {
            try self.generateNode(node, 2);
        }
        
        try self.output.appendSlice(self.allocator, "    });\n");
        try self.output.appendSlice(self.allocator, "}\n");

        return try self.output.toOwnedSlice(self.allocator);
    }

    fn generateMeta(self: *Generator, meta: ast.Meta) !void {
        try self.output.appendSlice(self.allocator, "pub const meta: mer.Meta = .{\n");
        if (meta.title) |title| {
            try self.output.appendSlice(self.allocator, "    .title = \"");
            try self.writeEscaped(title);
            try self.output.appendSlice(self.allocator, "\",\n");
        } else {
            try self.output.appendSlice(self.allocator, "    .title = \"Untitled\",\n");
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
                const class = switch (h.level) {
                    1 => "title",
                    2 => "subtitle", 
                    else => "heading",
                };
                const tag = switch (h.level) {
                    1 => "h1",
                    2 => "h2",
                    3 => "h3",
                    4 => "h4",
                    5 => "h5",
                    6 => "h6",
                    else => "h1",
                };
                try self.output.appendSlice(self.allocator, "h.");
                try self.output.appendSlice(self.allocator, tag);
                try self.output.appendSlice(self.allocator, "(.{ .class = \"");
                try self.output.appendSlice(self.allocator, class);
                try self.output.appendSlice(self.allocator, "\" }, ");
                
                // For simple single-text headings
                if (h.content.len == 1 and h.content[0] == .text) {
                    try self.output.appendSlice(self.allocator, "\"");
                    try self.writeEscaped(h.content[0].text);
                    try self.output.appendSlice(self.allocator, "\"),\n");
                } else {
                    try self.output.appendSlice(self.allocator, ".{\n");
                    for (h.content) |inline_node| {
                        try self.writeIndent(depth + 1);
                        try self.generateInline(inline_node);
                        try self.output.appendSlice(self.allocator, ",\n");
                    }
                    try self.writeIndent(depth);
                    try self.output.appendSlice(self.allocator, "}),\n");
                }
            },
            .paragraph => |p| {
                try self.output.appendSlice(self.allocator, "h.p(.{}, .{\n");
                for (p) |inline_node| {
                    try self.writeIndent(depth + 1);
                    try self.generateInline(inline_node);
                    try self.output.appendSlice(self.allocator, ",\n");
                }
                try self.writeIndent(depth);
                try self.output.appendSlice(self.allocator, "}),\n");
            },
            .list => |l| {
                const tag = if (l.ordered) "ol" else "ul";
                try self.output.appendSlice(self.allocator, "h.");
                try self.output.appendSlice(self.allocator, tag);
                try self.output.appendSlice(self.allocator, "(.{}, .{\n");
                for (l.items) |item| {
                    try self.writeIndent(depth + 1);
                    try self.output.appendSlice(self.allocator, "h.li(.{}, ");
                    if (item == .list_item) {
                        if (item.list_item.len == 1 and item.list_item[0] == .text) {
                            try self.output.appendSlice(self.allocator, "\"");
                            try self.writeEscaped(item.list_item[0].text);
                            try self.output.appendSlice(self.allocator, "\"),\n");
                        } else {
                            try self.output.appendSlice(self.allocator, ".{\n");
                            for (item.list_item) |inline_node| {
                                try self.writeIndent(depth + 2);
                                try self.generateInline(inline_node);
                                try self.output.appendSlice(self.allocator, ",\n");
                            }
                            try self.writeIndent(depth + 1);
                            try self.output.appendSlice(self.allocator, "}),\n");
                        }
                    }
                }
                try self.writeIndent(depth);
                try self.output.appendSlice(self.allocator, "}),\n");
            },
            .code_block => |cb| {
                try self.output.appendSlice(self.allocator, "h.pre(.{}, .{h.code(.{}, \"");
                try self.writeEscaped(cb.content);
                try self.output.appendSlice(self.allocator, "\")}),\n");
            },
            else => {},
        }
    }

    fn generateInline(self: *Generator, node: ast.Node) !void {
        switch (node) {
            .text => |s| {
                try self.output.appendSlice(self.allocator, "h.text(\"");
                try self.writeEscaped(s);
                try self.output.appendSlice(self.allocator, "\")");
            },
            .bold => |b| {
                try self.output.appendSlice(self.allocator, "h.strong(.{}, \"");
                // For now, just use first text node
                for (b) |n| {
                    if (n == .text) {
                        try self.writeEscaped(n.text);
                    }
                }
                try self.output.appendSlice(self.allocator, "\")");
            },
            .italic => |i| {
                try self.output.appendSlice(self.allocator, "h.em(.{}, \"");
                for (i) |n| {
                    if (n == .text) {
                        try self.writeEscaped(n.text);
                    }
                }
                try self.output.appendSlice(self.allocator, "\")");
            },
            .code => |s| {
                try self.output.appendSlice(self.allocator, "h.code(.{}, \"");
                try self.writeEscaped(s);
                try self.output.appendSlice(self.allocator, "\")");
            },
            .link => |l| {
                try self.output.appendSlice(self.allocator, "h.a(.{ .href = \"");
                try self.output.appendSlice(self.allocator, l.url);
                try self.output.appendSlice(self.allocator, "\" }, \"");
                try self.output.appendSlice(self.allocator, l.text);
                try self.output.appendSlice(self.allocator, "\")");
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
