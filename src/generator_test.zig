const std = @import("std");
const ast = @import("ast.zig");
const generator = @import("generator.zig");

test "generate empty document" {
    const allocator = std.testing.allocator;
    
    const doc = ast.Document{
        .meta = .{ .title = null, .description = null },
        .content = &[_]ast.Node{},
    };
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "const mer = @import(\"mer\");"));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "const h = mer.h;"));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "pub fn render(req: mer.Request) mer.Response"));
}

test "generate document with title" {
    const allocator = std.testing.allocator;
    
    const title = try allocator.dupe(u8, "My Page");
    
    const doc = ast.Document{
        .meta = .{ .title = title, .description = null },
        .content = &[_]ast.Node{},
    };
    defer doc.meta.deinit(allocator);
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "pub const meta: mer.Meta"));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "My Page"));
}

test "generate heading" {
    const allocator = std.testing.allocator;
    
    const text = try allocator.dupe(u8, "Hello");
    const heading_content = try allocator.alloc(ast.Node, 1);
    heading_content[0] = .{ .text = text };
    
    var content = try allocator.alloc(ast.Node, 1);
    content[0] = .{ .heading = .{ .level = 1, .id = null, .content = heading_content } };
    
    const doc = ast.Document{
        .meta = .{ .title = null, .description = null },
        .content = content,
    };
    defer doc.deinit(allocator);
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.h1"));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "Hello"));
}

test "generate paragraph" {
    const allocator = std.testing.allocator;
    
    const text = try allocator.dupe(u8, "This is text");
    const para_content = try allocator.alloc(ast.Node, 1);
    para_content[0] = .{ .text = text };
    
    var content = try allocator.alloc(ast.Node, 1);
    content[0] = .{ .paragraph = para_content };
    
    const doc = ast.Document{
        .meta = .{ .title = null, .description = null },
        .content = content,
    };
    defer doc.deinit(allocator);
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.p"));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.text"));
}

test "generate bold text" {
    const allocator = std.testing.allocator;
    
    const text = try allocator.dupe(u8, "bold");
    const bold_content = try allocator.alloc(ast.Node, 1);
    bold_content[0] = .{ .text = text };
    
    const para_content = try allocator.alloc(ast.Node, 1);
    para_content[0] = .{ .bold = bold_content };
    
    var content = try allocator.alloc(ast.Node, 1);
    content[0] = .{ .paragraph = para_content };
    
    const doc = ast.Document{
        .meta = .{ .title = null, .description = null },
        .content = content,
    };
    defer doc.deinit(allocator);
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.strong"));
}

test "generate link" {
    const allocator = std.testing.allocator;
    
    const link_text = try allocator.dupe(u8, "Click here");
    const link_url = try allocator.dupe(u8, "/page");
    
    const para_content = try allocator.alloc(ast.Node, 1);
    para_content[0] = .{ .link = .{ .text = link_text, .url = link_url } };
    
    var content = try allocator.alloc(ast.Node, 1);
    content[0] = .{ .paragraph = para_content };
    
    const doc = ast.Document{
        .meta = .{ .title = null, .description = null },
        .content = content,
    };
    defer doc.deinit(allocator);
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.a(.{ .href = \"/page\" }"));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "Click here"));
}

test "generate unordered list" {
    const allocator = std.testing.allocator;
    
    const text1 = try allocator.dupe(u8, "Item 1");
    const item1_content = try allocator.alloc(ast.Node, 1);
    item1_content[0] = .{ .text = text1 };
    
    const text2 = try allocator.dupe(u8, "Item 2");
    const item2_content = try allocator.alloc(ast.Node, 1);
    item2_content[0] = .{ .text = text2 };
    
    const items = try allocator.alloc(ast.Node, 2);
    items[0] = .{ .list_item = item1_content };
    items[1] = .{ .list_item = item2_content };
    
    var content = try allocator.alloc(ast.Node, 1);
    content[0] = .{ .list = .{ .ordered = false, .items = items } };
    
    const doc = ast.Document{
        .meta = .{ .title = null, .description = null },
        .content = content,
    };
    defer doc.deinit(allocator);
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.ul"));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.li"));
}

test "generate code block" {
    const allocator = std.testing.allocator;
    
    const lang = try allocator.dupe(u8, "zig");
    const code = try allocator.dupe(u8, "const x = 42;");
    
    var content = try allocator.alloc(ast.Node, 1);
    content[0] = .{ .code_block = .{ .language = lang, .content = code } };
    
    const doc = ast.Document{
        .meta = .{ .title = null, .description = null },
        .content = content,
    };
    defer doc.deinit(allocator);
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.pre"));
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "h.code"));
}

test "escapes quotes in output" {
    const allocator = std.testing.allocator;
    
    const text = try allocator.dupe(u8, "Say \"hello\"");
    const para_content = try allocator.alloc(ast.Node, 1);
    para_content[0] = .{ .text = text };
    
    var content = try allocator.alloc(ast.Node, 1);
    content[0] = .{ .paragraph = para_content };
    
    const doc = ast.Document{
        .meta = .{ .title = null, .description = null },
        .content = content,
    };
    defer doc.deinit(allocator);
    
    const output = try generator.generate(allocator, doc, "");
    defer allocator.free(output);
    
    try std.testing.expect(std.mem.containsAtLeast(u8, output, 1, "\\\""));
}
