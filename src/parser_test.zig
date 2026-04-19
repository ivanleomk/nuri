const std = @import("std");
const parser = @import("parser.zig");
const ast = @import("ast.zig");

test "parse empty document" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "");
    defer doc.deinit(allocator);
    
    try std.testing.expect(doc.meta.title == null);
    try std.testing.expect(doc.meta.description == null);
    try std.testing.expectEqual(@as(usize, 0), doc.content.len);
}

test "parse heading" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "# Hello World\n");
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    
    const heading = doc.content[0];
    try std.testing.expectEqual(@as(u8, 1), heading.heading.level);
    try std.testing.expectEqual(@as(usize, 1), heading.heading.content.len);
    try std.testing.expectEqualStrings("Hello World", heading.heading.content[0].text);
}

test "parse multiple headings" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\# H1
        \\## H2
        \\### H3
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 3), doc.content.len);
    try std.testing.expectEqual(@as(u8, 1), doc.content[0].heading.level);
    try std.testing.expectEqual(@as(u8, 2), doc.content[1].heading.level);
    try std.testing.expectEqual(@as(u8, 3), doc.content[2].heading.level);
}

test "parse paragraph" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "This is a paragraph.\n");
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    // Check it's a paragraph by checking the tag type
    try std.testing.expect(doc.content[0] == .paragraph);
    try std.testing.expectEqual(@as(usize, 1), doc.content[0].paragraph.len);
    try std.testing.expectEqualStrings("This is a paragraph.", doc.content[0].paragraph[0].text);
}

test "parse frontmatter" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\---
        \\title: My Page
        \\description: A description
        \\---
        \\
        \\# Content
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expect(doc.meta.title != null);
    try std.testing.expectEqualStrings("My Page", doc.meta.title.?);
    try std.testing.expect(doc.meta.description != null);
    try std.testing.expectEqualStrings("A description", doc.meta.description.?);
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
}

test "parse bold text" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "**bold text**\n");
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    const para = doc.content[0].paragraph;
    try std.testing.expectEqual(@as(usize, 1), para.len);
    try std.testing.expectEqual(@as(usize, 1), para[0].bold.len);
    try std.testing.expectEqualStrings("bold text", para[0].bold[0].text);
}

test "parse italic text" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "*italic text*\n");
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    const para = doc.content[0].paragraph;
    try std.testing.expectEqual(@as(usize, 1), para.len);
    try std.testing.expectEqual(@as(usize, 1), para[0].italic.len);
    try std.testing.expectEqualStrings("italic text", para[0].italic[0].text);
}

test "parse inline code" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "`code`\n");
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    const para = doc.content[0].paragraph;
    try std.testing.expectEqual(@as(usize, 1), para.len);
    try std.testing.expectEqualStrings("code", para[0].code);
}

test "parse link" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "[link text](http://example.com)\n");
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    const para = doc.content[0].paragraph;
    try std.testing.expectEqual(@as(usize, 1), para.len);
    const link = para[0].link;
    try std.testing.expectEqualStrings("link text", link.text);
    try std.testing.expectEqualStrings("http://example.com", link.url);
}

test "parse unordered list" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\- Item 1
        \\- Item 2
        \\- Item 3
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    const list = doc.content[0].list;
    try std.testing.expect(!list.ordered);
    try std.testing.expectEqual(@as(usize, 3), list.items.len);
}

test "parse ordered list" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\1. Item 1
        \\2. Item 2
        \\3. Item 3
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    const list = doc.content[0].list;
    try std.testing.expect(list.ordered);
    try std.testing.expectEqual(@as(usize, 3), list.items.len);
}

test "parse code block" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\```zig
        \\const x = 42;
        \\```
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    const code = doc.content[0].code_block;
    try std.testing.expect(code.language != null);
    try std.testing.expectEqualStrings("zig", code.language.?);
}

test "link transformation removes .md extension" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "[link](./page.md)\n");
    defer doc.deinit(allocator);
    
    const para = doc.content[0].paragraph;
    const link = para[0].link;
    try std.testing.expectEqualStrings("/page", link.url);
}

test "link transformation handles external URLs" {
    const allocator = std.testing.allocator;
    
    var doc = try parser.parse(allocator, "[link](https://example.com)\n");
    defer doc.deinit(allocator);
    
    const para = doc.content[0].paragraph;
    const link = para[0].link;
    try std.testing.expectEqualStrings("https://example.com", link.url);
}

test "complex document" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\---
        \\title: Test Page
        \\---
        \\
        \\# Welcome
        \\
        \\This is **bold** and *italic* text with a [link](./test.md).
        \\
        \\- Item 1
        \\- Item 2
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expect(doc.meta.title != null);
    try std.testing.expectEqualStrings("Test Page", doc.meta.title.?);
    try std.testing.expectEqual(@as(usize, 3), doc.content.len); // heading, paragraph, list
}

test "parse simple table" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\| Name | Age |
        \\|------|-----|
        \\| Alice | 25 |
        \\| Bob | 30 |
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    try std.testing.expect(doc.content[0] == .table);
    
    const table = doc.content[0].table;
    try std.testing.expectEqual(@as(usize, 2), table.headers.len);
    try std.testing.expectEqualStrings("Name", table.headers[0]);
    try std.testing.expectEqualStrings("Age", table.headers[1]);
    
    try std.testing.expectEqual(@as(usize, 2), table.rows.len);
    try std.testing.expectEqual(@as(usize, 2), table.rows[0].len);
    try std.testing.expectEqualStrings("Alice", table.rows[0][0]);
    try std.testing.expectEqualStrings("25", table.rows[0][1]);
    try std.testing.expectEqualStrings("Bob", table.rows[1][0]);
    try std.testing.expectEqualStrings("30", table.rows[1][1]);
}

test "parse table with alignment indicators" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\| Item | Price | Count |
        \\|:-----|------:|------:|
        \\| Apple | 1.00 | 5 |
        \\| Orange | 0.75 | 10 |
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 1), doc.content.len);
    try std.testing.expect(doc.content[0] == .table);
    
    const table = doc.content[0].table;
    try std.testing.expectEqual(@as(usize, 3), table.headers.len);
    try std.testing.expectEqualStrings("Item", table.headers[0]);
    try std.testing.expectEqualStrings("Price", table.headers[1]);
    try std.testing.expectEqualStrings("Count", table.headers[2]);
    
    try std.testing.expectEqual(@as(usize, 2), table.rows.len);
}

test "parse table mixed with other content" {
    const allocator = std.testing.allocator;
    
    const markdown = 
        \\# Products
        \\
        \\| SKU | Name |
        \\|-----|------|
        \\| A123 | Widget |
        \\
        \\Some text after table.
    ;
    
    var doc = try parser.parse(allocator, markdown);
    defer doc.deinit(allocator);
    
    try std.testing.expectEqual(@as(usize, 3), doc.content.len);
    try std.testing.expect(doc.content[0] == .heading);
    try std.testing.expect(doc.content[1] == .table);
    try std.testing.expect(doc.content[2] == .paragraph);
}
