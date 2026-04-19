const std = @import("std");
const ast = @import("ast.zig");

pub const Parser = struct {
    allocator: std.mem.Allocator,
    lines: [][]const u8,
    current: usize,
    heading_ids: std.StringHashMap(u32),

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Parser {
        // Split into lines
        var lines: std.ArrayList([]const u8) = .empty;
        errdefer lines.deinit(allocator);

        var iter = std.mem.splitScalar(u8, source, '\n');
        while (iter.next()) |line| {
            try lines.append(allocator, line);
        }

        return .{
            .allocator = allocator,
            .lines = try lines.toOwnedSlice(allocator),
            .current = 0,
            .heading_ids = std.StringHashMap(u32).init(allocator),
        };
    }

    pub fn deinit(self: *Parser) void {
        // Don't free heading_id keys here - they're owned by AST nodes
        self.heading_ids.deinit();
        self.allocator.free(self.lines);
    }

    pub fn parse(self: *Parser) !ast.Document {
        // Parse frontmatter first
        const meta = try self.parseFrontmatter();

        // Parse content blocks
        var blocks: std.ArrayList(ast.Node) = .empty;
        errdefer {
            for (blocks.items) |node| {
                node.deinit(self.allocator);
            }
            blocks.deinit(self.allocator);
        }

        while (self.current < self.lines.len) {
            const line = self.lines[self.current];

            if (line.len == 0 or std.mem.trim(u8, line, " \t").len == 0) {
                self.current += 1;
                continue;
            }

            // Try to parse different block types
            if (try self.parseHeading()) |heading| {
                try blocks.append(self.allocator, heading);
            } else if (try self.parseCodeBlock()) |code_block| {
                try blocks.append(self.allocator, code_block);
            } else if (try self.parseTable()) |table| {
                try blocks.append(self.allocator, table);
            } else if (try self.parseList()) |list| {
                try blocks.append(self.allocator, list);
            } else if (try self.parseParagraph()) |paragraph| {
                try blocks.append(self.allocator, paragraph);
            } else {
                self.current += 1;
            }
        }

        return .{
            .meta = meta,
            .content = try blocks.toOwnedSlice(self.allocator),
        };
    }

    fn parseFrontmatter(self: *Parser) !ast.Meta {
        if (self.lines.len < 2) {
            return .{ .title = null, .description = null };
        }

        const first_line = std.mem.trim(u8, self.lines[0], " \t");
        if (!std.mem.eql(u8, first_line, "---")) {
            return .{ .title = null, .description = null };
        }

        // Find closing ---
        var end_idx: usize = 1;
        while (end_idx < self.lines.len) : (end_idx += 1) {
            const line = std.mem.trim(u8, self.lines[end_idx], " \t");
            if (std.mem.eql(u8, line, "---")) {
                break;
            }
        }

        if (end_idx >= self.lines.len) {
            return .{ .title = null, .description = null };
        }

        // Parse frontmatter lines
        var title: ?[]const u8 = null;
        var description: ?[]const u8 = null;

        var i: usize = 1;
        while (i < end_idx) : (i += 1) {
            const line = self.lines[i];
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                const key = std.mem.trim(u8, line[0..colon_idx], " \t");
                const value = std.mem.trim(u8, line[colon_idx + 1 ..], " \t");

                if (std.mem.eql(u8, key, "title")) {
                    title = try self.allocator.dupe(u8, value);
                } else if (std.mem.eql(u8, key, "description")) {
                    description = try self.allocator.dupe(u8, value);
                }
            }
        }

        self.current = end_idx + 1;

        return .{ .title = title, .description = description };
    }

    fn parseHeading(self: *Parser) !?ast.Node {
        const line = self.lines[self.current];
        const trimmed = std.mem.trim(u8, line, " \t");

        if (trimmed.len < 2 or trimmed[0] != '#') {
            return null;
        }

        // Count # characters
        var level: u8 = 0;
        while (level < trimmed.len and trimmed[level] == '#') {
            level += 1;
        }

        if (level > 6 or level >= trimmed.len) {
            return null;
        }

        // Skip # and space
        const content_start = if (trimmed[level] == ' ') level + 1 else level;
        const content = std.mem.trim(u8, trimmed[content_start..], " \t");

        self.current += 1;

        // Parse inline elements in heading
        const inline_nodes = try self.parseInline(content);
        
        // Generate ID from heading text
        const id = try self.generateHeadingId(inline_nodes);

        return .{ .heading = .{
            .level = level,
            .id = id,
            .content = inline_nodes,
        } };
    }
    
    fn generateHeadingId(self: *Parser, content: []const ast.Node) !?[]const u8 {
        // Extract plain text from inline content
        var text_buf: std.ArrayList(u8) = .empty;
        defer text_buf.deinit(self.allocator);
        
        for (content) |node| {
            try self.extractText(node, &text_buf);
        }
        
        const text = std.mem.trim(u8, text_buf.items, " \t");
        if (text.len == 0) return null;
        
        // Slugify the text
        const slug = try slugify(self.allocator, text);
        
        // Check for duplicates and append number if needed
        var unique_slug = try self.allocator.dupe(u8, slug);
        defer self.allocator.free(slug);
        
        var counter: u32 = 1;
        while (self.heading_ids.get(unique_slug)) |_| {
            self.allocator.free(unique_slug);
            const new_slug = try std.fmt.allocPrint(self.allocator, "{s}-{d}", .{ slug, counter });
            unique_slug = new_slug;
            counter += 1;
        }
        
        // Store in hashmap to track usage
        try self.heading_ids.put(unique_slug, counter);
        
        return unique_slug;
    }
    
    fn extractText(self: *Parser, node: ast.Node, buf: *std.ArrayList(u8)) !void {
        switch (node) {
            .text => |s| try buf.appendSlice(self.allocator, s),
            .bold => |b| {
                for (b) |n| try self.extractText(n, buf);
            },
            .italic => |i| {
                for (i) |n| try self.extractText(n, buf);
            },
            .code => |s| try buf.appendSlice(self.allocator, s),
            .link => |l| try buf.appendSlice(self.allocator, l.text),
            else => {},
        }
    }

    fn parseCodeBlock(self: *Parser) !?ast.Node {
        const line = self.lines[self.current];
        const trimmed = std.mem.trim(u8, line, " \t");

        if (!std.mem.startsWith(u8, trimmed, "```")) {
            return null;
        }

        // Extract language if specified
        const lang = if (trimmed.len > 3)
            std.mem.trim(u8, trimmed[3..], " \t")
        else
            null;

        self.current += 1;

        // Collect code lines
        var code_lines: std.ArrayList([]const u8) = .empty;
        defer code_lines.deinit(self.allocator);

        while (self.current < self.lines.len) {
            const code_line = self.lines[self.current];
            const code_trimmed = std.mem.trim(u8, code_line, " \t");

            if (std.mem.eql(u8, code_trimmed, "```")) {
                self.current += 1;
                break;
            }

            try code_lines.append(self.allocator, code_line);
            self.current += 1;
        }

        // Join code lines
        const code_content = try std.mem.join(self.allocator, "\n", code_lines.items);

        return .{ .code_block = .{
            .language = if (lang) |l| try self.allocator.dupe(u8, l) else null,
            .content = code_content,
        } };
    }

    fn parseTable(self: *Parser) !?ast.Node {
        const line = self.lines[self.current];
        const trimmed = std.mem.trim(u8, line, " \t");

        // Check if line starts with |
        if (!std.mem.startsWith(u8, trimmed, "|")) {
            return null;
        }

        // Parse header row
        const header_cells = try self.parseTableRow(trimmed);
        if (header_cells.len == 0) {
            return null;
        }

        self.current += 1;

        // Check for separator row (| --- | --- |)
        if (self.current >= self.lines.len) {
            return null;
        }

        const sep_line = std.mem.trim(u8, self.lines[self.current], " \t");
        if (!std.mem.startsWith(u8, sep_line, "|") or !isTableSeparator(sep_line)) {
            return null;
        }

        self.current += 1;

        // Parse data rows
        var rows: std.ArrayList([]const []const u8) = .empty;
        errdefer {
            for (rows.items) |row| {
                for (row) |cell| self.allocator.free(cell);
                self.allocator.free(row);
            }
            rows.deinit(self.allocator);
        }

        while (self.current < self.lines.len) {
            const data_line = std.mem.trim(u8, self.lines[self.current], " \t");
            if (!std.mem.startsWith(u8, data_line, "|")) {
                break;
            }

            // Check if it's a separator (invalid in data rows)
            if (isTableSeparator(data_line)) {
                break;
            }

            const cells = try self.parseTableRow(data_line);
            if (cells.len == 0) {
                break;
            }

            try rows.append(self.allocator, cells);
            self.current += 1;
        }

        return .{ .table = .{
            .headers = header_cells,
            .rows = try rows.toOwnedSlice(self.allocator),
        } };
    }

    fn parseTableRow(self: *Parser, line: []const u8) ![]const []const u8 {
        var cells: std.ArrayList([]const u8) = .empty;
        defer cells.deinit(self.allocator);

        var i: usize = 0;
        // Skip leading |
        if (i < line.len and line[i] == '|') {
            i += 1;
        }

        while (i < line.len) {
            // Find end of cell (next |)
            const start = i;
            while (i < line.len and line[i] != '|') {
                i += 1;
            }

            if (i > start) {
                const cell_content = std.mem.trim(u8, line[start..i], " \t");
                if (cell_content.len > 0) {
                    const cell = try self.allocator.dupe(u8, cell_content);
                    try cells.append(self.allocator, cell);
                }
            }

            // Skip the |
            if (i < line.len and line[i] == '|') {
                i += 1;
            }
        }

        // Handle trailing empty cells (if line ends with |)
        if (line.len > 0 and line[line.len - 1] == '|') {
            // Check if we need to add an empty cell
            // This handles cases like "| A | B |" where there's a trailing |
        }

        return try cells.toOwnedSlice(self.allocator);
    }

    fn isTableSeparator(line: []const u8) bool {
        // Check if line contains only |, -, :, and spaces
        // Example: | --- | ---: | :---: |
        var has_dash = false;
        var i: usize = 0;

        while (i < line.len) : (i += 1) {
            const c = line[i];
            if (c == '|' or c == ' ' or c == '\t' or c == ':') {
                continue;
            }
            if (c == '-') {
                has_dash = true;
                continue;
            }
            // Found a non-separator character
            return false;
        }

        return has_dash;
    }

    fn parseList(self: *Parser) !?ast.Node {
        const line = self.lines[self.current];
        const trimmed = std.mem.trim(u8, line, " \t");

        // Check for unordered list item
        const is_unordered = std.mem.startsWith(u8, trimmed, "- ") or
            std.mem.startsWith(u8, trimmed, "* ");

        // Check for ordered list item (e.g., "1. ")
        var is_ordered = false;
        if (!is_unordered and trimmed.len >= 3) {
            if (std.ascii.isDigit(trimmed[0])) {
                var idx: usize = 1;
                while (idx < trimmed.len and std.ascii.isDigit(trimmed[idx])) {
                    idx += 1;
                }
                if (idx < trimmed.len and trimmed[idx] == '.' and trimmed[idx + 1] == ' ') {
                    is_ordered = true;
                }
            }
        }

        if (!is_unordered and !is_ordered) {
            return null;
        }

        var items: std.ArrayList(ast.Node) = .empty;
        errdefer {
            for (items.items) |item| {
                item.deinit(self.allocator);
            }
            items.deinit(self.allocator);
        }

        // Parse all consecutive list items
        while (self.current < self.lines.len) {
            const current_line = self.lines[self.current];
            const current_trimmed = std.mem.trim(u8, current_line, " \t");

            const is_current_unordered = std.mem.startsWith(u8, current_trimmed, "- ") or
                std.mem.startsWith(u8, current_trimmed, "* ");

            var is_current_ordered = false;
            if (!is_current_unordered and current_trimmed.len >= 3) {
                if (std.ascii.isDigit(current_trimmed[0])) {
                    var idx: usize = 1;
                    while (idx < current_trimmed.len and std.ascii.isDigit(current_trimmed[idx])) {
                        idx += 1;
                    }
                    if (idx < current_trimmed.len and current_trimmed[idx] == '.' and
                        idx + 1 < current_trimmed.len and current_trimmed[idx + 1] == ' ')
                    {
                        is_current_ordered = true;
                    }
                }
            }

            if (!is_current_unordered and !is_current_ordered) {
                break;
            }

            // Extract content after marker
            var content_start: usize = 0;
            if (is_current_unordered) {
                content_start = 2;
            } else {
                // Skip digits and ". "
                content_start = 0;
                while (content_start < current_trimmed.len and std.ascii.isDigit(current_trimmed[content_start])) {
                    content_start += 1;
                }
                content_start += 2; // Skip ". "
            }

            const item_content = current_trimmed[content_start..];
            const inline_nodes = try self.parseInline(item_content);

            try items.append(self.allocator, .{ .list_item = inline_nodes });
            self.current += 1;
        }

        return .{ .list = .{
            .ordered = is_ordered,
            .items = try items.toOwnedSlice(self.allocator),
        } };
    }

    fn parseParagraph(self: *Parser) !?ast.Node {
        var lines: std.ArrayList([]const u8) = .empty;
        defer lines.deinit(self.allocator);

        // Collect lines until blank line or new block
        while (self.current < self.lines.len) {
            const line = self.lines[self.current];
            const trimmed = std.mem.trim(u8, line, " \t");

            if (trimmed.len == 0) {
                break;
            }

            // Stop at block markers
            if (std.mem.startsWith(u8, trimmed, "#") or
                std.mem.startsWith(u8, trimmed, "```") or
                std.mem.startsWith(u8, trimmed, "- ") or
                std.mem.startsWith(u8, trimmed, "* ") or
                std.mem.eql(u8, trimmed, "---"))
            {
                break;
            }

            // Check for ordered list
            if (trimmed.len >= 3 and std.ascii.isDigit(trimmed[0])) {
                var idx: usize = 1;
                while (idx < trimmed.len and std.ascii.isDigit(trimmed[idx])) {
                    idx += 1;
                }
                if (idx < trimmed.len and trimmed[idx] == '.' and idx + 1 < trimmed.len and trimmed[idx + 1] == ' ') {
                    break;
                }
            }

            try lines.append(self.allocator, trimmed);
            self.current += 1;
        }

        if (lines.items.len == 0) {
            return null;
        }

        // Join lines and parse inline
        const content = try std.mem.join(self.allocator, " ", lines.items);
        defer self.allocator.free(content);

        const inline_nodes = try self.parseInline(content);

        return .{ .paragraph = inline_nodes };
    }

    fn parseInline(self: *Parser, text: []const u8) ![]const ast.Node {
        var nodes: std.ArrayList(ast.Node) = .empty;
        errdefer {
            for (nodes.items) |node| {
                node.deinit(self.allocator);
            }
            nodes.deinit(self.allocator);
        }

        var i: usize = 0;
        while (i < text.len) {
            // Try to match inline patterns
            if (try self.parseCodeInline(text, &i, &nodes)) continue;
            if (try self.parseLink(text, &i, &nodes)) continue;
            if (try self.parseBold(text, &i, &nodes)) continue;
            if (try self.parseItalic(text, &i, &nodes)) continue;

            // Regular text
            const start = i;
            while (i < text.len and text[i] != '*' and text[i] != '`' and text[i] != '[') {
                i += 1;
            }

            if (i > start) {
                const text_content = try self.allocator.dupe(u8, text[start..i]);
                try nodes.append(self.allocator, .{ .text = text_content });
            }
        }

        return try nodes.toOwnedSlice(self.allocator);
    }

    fn parseCodeInline(self: *Parser, text: []const u8, i: *usize, nodes: *std.ArrayList(ast.Node)) !bool {
        if (i.* >= text.len or text[i.*] != '`') {
            return false;
        }

        const start = i.* + 1;
        var end = start;

        while (end < text.len and text[end] != '`') {
            end += 1;
        }

        if (end >= text.len) {
            return false;
        }

        const code_content = try self.allocator.dupe(u8, text[start..end]);
        try nodes.append(self.allocator, .{ .code = code_content });

        i.* = end + 1;
        return true;
    }

    fn parseLink(self: *Parser, text: []const u8, i: *usize, nodes: *std.ArrayList(ast.Node)) !bool {
        if (i.* >= text.len or text[i.*] != '[') {
            return false;
        }

        // Find closing ]
        const text_start = i.* + 1;
        var text_end = text_start;

        while (text_end < text.len and text[text_end] != ']') {
            text_end += 1;
        }

        if (text_end >= text.len or text_end + 1 >= text.len or text[text_end + 1] != '(') {
            return false;
        }

        // Find closing )
        const url_start = text_end + 2;
        var url_end = url_start;

        while (url_end < text.len and text[url_end] != ')') {
            url_end += 1;
        }

        if (url_end >= text.len) {
            return false;
        }

        const link_text = try self.allocator.dupe(u8, text[text_start..text_end]);
        const url = try self.allocator.dupe(u8, text[url_start..url_end]);

        // Transform URL (remove .md extension, convert to absolute path)
        const transformed_url = try transformLinkUrl(self.allocator, url);
        self.allocator.free(url);

        try nodes.append(self.allocator, .{ .link = .{
            .text = link_text,
            .url = transformed_url,
        } });

        i.* = url_end + 1;
        return true;
    }

    fn parseBold(self: *Parser, text: []const u8, i: *usize, nodes: *std.ArrayList(ast.Node)) !bool {
        if (i.* + 1 >= text.len or !std.mem.startsWith(u8, text[i.*..], "**")) {
            return false;
        }

        const start = i.* + 2;
        var end = start;

        while (end + 1 < text.len and !(text[end] == '*' and text[end + 1] == '*')) {
            end += 1;
        }

        if (end + 1 >= text.len) {
            return false;
        }

        const content = text[start..end];
        const text_node = try self.allocator.dupe(u8, content);
        const inline_nodes = try self.allocator.alloc(ast.Node, 1);
        inline_nodes[0] = .{ .text = text_node };

        try nodes.append(self.allocator, .{ .bold = inline_nodes });

        i.* = end + 2;
        return true;
    }

    fn parseItalic(self: *Parser, text: []const u8, i: *usize, nodes: *std.ArrayList(ast.Node)) !bool {
        if (i.* >= text.len or text[i.*] != '*') {
            return false;
        }

        // Don't match ** (bold)
        if (i.* + 1 < text.len and text[i.* + 1] == '*') {
            return false;
        }

        const start = i.* + 1;
        var end = start;

        while (end < text.len and text[end] != '*') {
            end += 1;
        }

        if (end >= text.len) {
            return false;
        }

        const content = text[start..end];
        const text_node = try self.allocator.dupe(u8, content);
        const inline_nodes = try self.allocator.alloc(ast.Node, 1);
        inline_nodes[0] = .{ .text = text_node };

        try nodes.append(self.allocator, .{ .italic = inline_nodes });

        i.* = end + 1;
        return true;
    }
};

fn transformLinkUrl(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    // Check if external link
    if (std.mem.startsWith(u8, url, "http://") or std.mem.startsWith(u8, url, "https://")) {
        return try allocator.dupe(u8, url);
    }

    // Remove .md extension
    const without_ext = if (std.mem.endsWith(u8, url, ".md"))
        url[0 .. url.len - 3]
    else
        url;

    // Remove ./ prefix
    const without_prefix = if (std.mem.startsWith(u8, without_ext, "./"))
        without_ext[2..]
    else
        without_ext;

    // "index" → "/"
    if (std.mem.eql(u8, without_prefix, "index")) {
        return try allocator.dupe(u8, "/");
    }

    // Ensure leading /
    if (without_prefix.len > 0 and without_prefix[0] == '/') {
        return try allocator.dupe(u8, without_prefix);
    } else {
        const result = try allocator.alloc(u8, without_prefix.len + 1);
        result[0] = '/';
        @memcpy(result[1..], without_prefix);
        return result;
    }
}

fn slugify(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(allocator);
    
    var prev_dash = true; // Start true to avoid leading dashes
    
    for (text) |c| {
        var lower_c = c;
        // Convert to lowercase
        if (c >= 'A' and c <= 'Z') {
            lower_c = c - 'A' + 'a';
        }
        
        // Keep alphanumeric and spaces
        if ((lower_c >= 'a' and lower_c <= 'z') or 
            (lower_c >= '0' and lower_c <= '9')) {
            try result.append(allocator, lower_c);
            prev_dash = false;
        } else if (lower_c == ' ' or lower_c == '-' or lower_c == '_') {
            // Convert spaces to dashes, but avoid consecutive dashes
            if (!prev_dash) {
                try result.append(allocator, '-');
                prev_dash = true;
            }
        }
        // Skip other characters (punctuation, etc.)
    }
    
    // Remove trailing dash
    if (result.items.len > 0 and result.items[result.items.len - 1] == '-') {
        _ = result.pop();
    }
    
    return try result.toOwnedSlice(allocator);
}

pub fn parse(allocator: std.mem.Allocator, source: []const u8) !ast.Document {
    var parser = try Parser.init(allocator, source);
    defer parser.deinit();
    return try parser.parse();
}
