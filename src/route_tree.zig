const std = @import("std");

/// Represents a node in the route tree
pub const RouteNode = struct {
    /// The path segment for this node (e.g., "deployment", "cloudflare", or "" for root/index)
    segment: []const u8,
    /// Full URL path (e.g., "/", "/deployment", "/deployment/cloudflare")
    path: []const u8,
    /// The zig file path (e.g., "app/deployment/cloudflare.zig") - null for intermediate nodes
    file_path: ?[]const u8,
    /// Child nodes (sub-routes)
    children: std.ArrayList(*RouteNode),
    /// Pointer to parent node (null for root)
    parent: ?*RouteNode,
    
    pub fn init(allocator: std.mem.Allocator, segment: []const u8, path: []const u8, file_path: ?[]const u8, parent: ?*RouteNode) !*RouteNode {
        const node = try allocator.create(RouteNode);
        node.* = .{
            .segment = try allocator.dupe(u8, segment),
            .path = try allocator.dupe(u8, path),
            .file_path = if (file_path) |fp| try allocator.dupe(u8, fp) else null,
            .children = .empty,
            .parent = parent,
        };
        return node;
    }
    
    pub fn deinit(self: *RouteNode, allocator: std.mem.Allocator) void {
        // Deinit all children first
        for (self.children.items) |child| {
            child.deinit(allocator);
        }
        self.children.deinit(allocator);
        
        // Free strings
        allocator.free(self.segment);
        allocator.free(self.path);
        if (self.file_path) |fp| allocator.free(fp);
        
        // Free self
        allocator.destroy(self);
    }
    
    /// Find a direct child by segment name
    pub fn findChild(self: *RouteNode, segment: []const u8) ?*RouteNode {
        for (self.children.items) |child| {
            if (std.mem.eql(u8, child.segment, segment)) {
                return child;
            }
        }
        return null;
    }
    
    /// Add a child node (takes ownership)
    pub fn addChild(self: *RouteNode, allocator: std.mem.Allocator, child: *RouteNode) !void {
        try self.children.append(allocator, child);
    }
    
    /// Check if this node has an associated file (is a leaf/actual route)
    pub fn hasFile(self: *RouteNode) bool {
        return self.file_path != null;
    }
    
    /// Get depth in the tree (0 for root)
    pub fn getDepth(self: *RouteNode) usize {
        var depth: usize = 0;
        var current = self.parent;
        while (current) |parent| {
            depth += 1;
            current = parent.parent;
        }
        return depth;
    }
};

/// RouteTree manages a hierarchical structure of routes
pub const RouteTree = struct {
    allocator: std.mem.Allocator,
    root: *RouteNode,
    
    pub fn init(allocator: std.mem.Allocator) !RouteTree {
        const root = try RouteNode.init(allocator, "", "/", null, null);
        return .{
            .allocator = allocator,
            .root = root,
        };
    }
    
    pub fn deinit(self: *RouteTree) void {
        self.root.deinit(self.allocator);
    }
    
    /// Insert a route into the tree
    /// file_path: the app/ path (e.g., "app/deployment/cloudflare.zig")
    /// url_path: the URL path (e.g., "/deployment/cloudflare")
    pub fn insert(self: *RouteTree, file_path: []const u8, url_path: []const u8) !void {
        // Parse URL path into segments
        var segments: std.ArrayList([]const u8) = .empty;
        defer segments.deinit(self.allocator);
        
        // Split URL path by '/'
        var iter = std.mem.splitScalar(u8, url_path, '/');
        while (iter.next()) |segment| {
            if (segment.len > 0) {
                try segments.append(self.allocator, segment);
            }
        }
        
        // Navigate/create tree structure
        var current = self.root;
        var current_path: std.ArrayList(u8) = .empty;
        defer current_path.deinit(self.allocator);
        try current_path.appendSlice(self.allocator, "/");
        
        for (segments.items, 0..) |segment, i| {
            // Update current path
            if (i > 0) {
                try current_path.appendSlice(self.allocator, "/");
            }
            try current_path.appendSlice(self.allocator, segment);
            
            // Find or create child
            var child = current.findChild(segment);
            if (child == null) {
                const is_last = (i == segments.items.len - 1);
                const child_file_path = if (is_last) file_path else null;
                child = try RouteNode.init(
                    self.allocator, 
                    segment, 
                    current_path.items,
                    child_file_path,
                    current
                );
                try current.addChild(self.allocator, child.?);
            } else if (i == segments.items.len - 1) {
                // Last segment but node already exists - update file_path
                if (child.?.file_path) |old_fp| {
                    self.allocator.free(old_fp);
                }
                child.?.file_path = try self.allocator.dupe(u8, file_path);
            }
            
            current = child.?;
        }
        
        // Handle root path ("/")
        if (segments.items.len == 0) {
            if (self.root.file_path) |old_fp| {
                self.allocator.free(old_fp);
            }
            self.root.file_path = try self.allocator.dupe(u8, file_path);
        }
    }
    
    /// Get all leaf nodes (nodes with file paths) in sorted order
    pub fn getAllRoutes(self: *RouteTree, list: *std.ArrayList(*RouteNode)) !void {
        try self.collectLeafNodes(self.root, list);
    }
    
    fn collectLeafNodes(self: *RouteTree, node: *RouteNode, list: *std.ArrayList(*RouteNode)) !void {
        if (node.hasFile()) {
            try list.append(self.allocator, node);
        }
        
        // Sort children by segment name for consistent ordering
        const CompareContext = struct {
            fn lessThan(_: void, a: *RouteNode, b: *RouteNode) bool {
                return std.mem.lessThan(u8, a.segment, b.segment);
            }
        };
        
        std.mem.sort(*RouteNode, node.children.items, {}, CompareContext.lessThan);
        
        for (node.children.items) |child| {
            try self.collectLeafNodes(child, list);
        }
    }
    
    /// Print tree structure for debugging
    pub fn printDebug(self: *RouteTree, writer: anytype) !void {
        try self.printNodeDebug(self.root, writer, 0);
    }
    
    fn printNodeDebug(_: *RouteTree, node: *RouteNode, writer: anytype, indent: usize) !void {
        for (0..indent) |_| {
            try writer.writeByteNTimes(' ', 2);
        }
        
        if (node.segment.len == 0) {
            try writer.print("- root (/{s})", .{if (node.file_path) |_| "" else " no file"});
        } else {
            try writer.print("- {s} ({s}){s}", .{
                node.segment,
                node.path,
                if (node.file_path) |_| "" else " [no file]",
            });
        }
        try writer.writeByte('\n');
        
        for (node.children.items) |child| {
            try printNodeDebugInternal(child, writer, indent + 1);
        }
    }
    
    fn printNodeDebugInternal(node: *RouteNode, writer: anytype, indent: usize) !void {
        for (0..indent) |_| {
            try writer.writeByteNTimes(' ', 2);
        }
        
        if (node.segment.len == 0) {
            try writer.print("- root (/{s})", .{if (node.file_path) |_| "" else " no file"});
        } else {
            try writer.print("- {s} ({s}){s}", .{
                node.segment,
                node.path,
                if (node.file_path) |_| "" else " [no file]",
            });
        }
        try writer.writeByte('\n');
        
        for (node.children.items) |child| {
            try printNodeDebugInternal(child, writer, indent + 1);
        }
    }
    
    /// Generate a tree representation into an ArrayList
    pub fn generateTreeView(self: *RouteTree, buf: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
        try generateNodeViewInternal(self.root, buf, allocator, 0, &[_]bool{});
    }
    
    fn generateNodeViewInternal(node: *RouteNode, buf: *std.ArrayList(u8), allocator: std.mem.Allocator, depth: usize, is_last_stack: []const bool) !void {
        // Skip root node in output (start with its children)
        if (depth == 0) {
            for (node.children.items, 0..) |child, i| {
                const is_last = i == node.children.items.len - 1;
                var new_stack: [32]bool = undefined;
                @memcpy(new_stack[0..is_last_stack.len], is_last_stack);
                if (is_last_stack.len < 32) {
                    new_stack[is_last_stack.len] = is_last;
                    try generateNodeViewInternal(child, buf, allocator, depth + 1, new_stack[0 .. is_last_stack.len + 1]);
                }
            }
            return;
        }
        
        // Print prefix
        for (0..depth - 1) |i| {
            if (i < is_last_stack.len - 1) {
                if (is_last_stack[i]) {
                    try buf.appendSlice(allocator, "   ");
                } else {
                    try buf.appendSlice(allocator, "│  ");
                }
            }
        }
        
        if (is_last_stack.len > 0) {
            if (is_last_stack[is_last_stack.len - 1]) {
                try buf.appendSlice(allocator, "└─ ");
            } else {
                try buf.appendSlice(allocator, "├─ ");
            }
        }
        
        // Print node info
        const display_name = if (std.mem.eql(u8, node.segment, "index")) 
            "index" 
        else 
            node.segment;
        
        try buf.appendSlice(allocator, display_name);
        
        if (node.file_path) |fp| {
            const arrow_text = try std.fmt.allocPrint(allocator, " → {s}", .{fp});
            defer allocator.free(arrow_text);
            try buf.appendSlice(allocator, arrow_text);
        }
        try buf.append(allocator, '\n');
        
        // Recursively print children
        const CompareContext = struct {
            fn lessThan(_: void, a: *RouteNode, b: *RouteNode) bool {
                return std.mem.lessThan(u8, a.segment, b.segment);
            }
        };
        std.mem.sort(*RouteNode, node.children.items, {}, CompareContext.lessThan);
        
        for (node.children.items, 0..) |child, i| {
            const is_last = i == node.children.items.len - 1;
            var new_stack: [32]bool = undefined;
            @memcpy(new_stack[0..is_last_stack.len], is_last_stack);
            if (is_last_stack.len < 32) {
                new_stack[is_last_stack.len] = is_last;
                try generateNodeViewInternal(child, buf, allocator, depth + 1, new_stack[0 .. is_last_stack.len + 1]);
            }
        }
    }
    
    /// Generate HTML for route tree sidebar
    /// current_path: the current page URL to highlight (e.g., "/deployment/cloudflare")
    pub fn generateSidebarHtml(self: *RouteTree, allocator: std.mem.Allocator, current_path: []const u8) ![]const u8 {
        var html: std.ArrayList(u8) = .empty;
        defer html.deinit(allocator);
        
        try html.appendSlice(allocator, "<nav class=\"route-sidebar\">\n");
        // Header - clickable link to home
        try html.appendSlice(allocator, "  <a href=\"/\" class=\"route-sidebar-header\">Nuri</a>\n");
        try html.appendSlice(allocator, "  <ul class=\"route-tree\">\n");
        
        // Sort children alphabetically
        const CompareContext = struct {
            fn lessThan(_: void, a: *RouteNode, b: *RouteNode) bool {
                return std.mem.lessThan(u8, a.segment, b.segment);
            }
        };
        std.mem.sort(*RouteNode, self.root.children.items, {}, CompareContext.lessThan);
        
        for (self.root.children.items) |child| {
            try self.generateSidebarNodeHtml(child, allocator, current_path, &html, 1);
        }
        
        try html.appendSlice(allocator, "  </ul>\n");
        try html.appendSlice(allocator, "</nav>\n");
        
        return try html.toOwnedSlice(allocator);
    }

    fn generateSidebarNodeHtml(self: *RouteTree, node: *RouteNode, allocator: std.mem.Allocator, current_path: []const u8, html: *std.ArrayList(u8), depth: usize) !void {
        const is_active = std.mem.eql(u8, node.path, current_path);
        const is_ancestor_of_current = isAncestorOf(node, current_path);
        
        // Calculate indent based on depth
        const indent = try allocator.alloc(u8, depth * 2);
        defer allocator.free(indent);
        @memset(indent, ' ');
        
        // Check if this node has children
        const has_children = node.children.items.len > 0;
        
        // Check if this node has an index.md child (for section headers that should be links)
        const index_child = if (has_children) self.findIndexChild(node) else null;
        const has_index_child = index_child != null;
        
        if (node.file_path != null or has_children) {
            // Start list item
            try html.appendSlice(allocator, indent);
            try html.appendSlice(allocator, "<li");
            
            if (is_active) {
                try html.appendSlice(allocator, " class=\"active\"");
            } else if (is_ancestor_of_current) {
                try html.appendSlice(allocator, " class=\"expanded\"");
            }
            try html.appendSlice(allocator, ">\n");
            
            // Add link if this is a route node (has file) or has index.md child
            if (node.file_path != null or has_index_child) {
                try html.appendSlice(allocator, indent);
                try html.appendSlice(allocator, "  <a href=\"");
                
                // If this node has its own file, use its path; otherwise use index child's path
                const href_path = if (node.file_path != null) node.path else index_child.?.path;
                try html.appendSlice(allocator, href_path);
                
                try html.appendSlice(allocator, "\"");
                if (is_active) {
                    try html.appendSlice(allocator, " class=\"active\"");
                }
                try html.appendSlice(allocator, ">");
                
                // Root index gets a home icon, otherwise use segment name
                const is_root_index = std.mem.eql(u8, node.path, "/");
                if (is_root_index) {
                    // Lucide-style home icon SVG
                    try html.appendSlice(allocator, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" class=\"home-icon\"><path d=\"m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z\"></path><polyline points=\"9 22 9 12 15 12 15 22\"></polyline></svg>");
                } else {
                    const display_name = try capitalizeFirst(allocator, node.segment);
                    defer allocator.free(display_name);
                    try html.appendSlice(allocator, display_name);
                }
                
                try html.appendSlice(allocator, "</a>\n");
            } else {
                // Section header without link (no index.md)
                try html.appendSlice(allocator, indent);
                try html.appendSlice(allocator, "  <span class=\"section-header\">");
                const display_name = try capitalizeFirst(allocator, node.segment);
                defer allocator.free(display_name);
                try html.appendSlice(allocator, display_name);
                try html.appendSlice(allocator, "</span>\n");
            }
            
            // Recursively render children (but skip the index child since we already used it)
            if (has_children) {
                // Sort children
                const CompareContext = struct {
                    fn lessThan(_: void, a: *RouteNode, b: *RouteNode) bool {
                        return std.mem.lessThan(u8, a.segment, b.segment);
                    }
                };
                std.mem.sort(*RouteNode, node.children.items, {}, CompareContext.lessThan);
                
                try html.appendSlice(allocator, indent);
                try html.appendSlice(allocator, "  <ul class=\"route-children\">\n");
                
                for (node.children.items) |child| {
                    // Skip index nodes - they're represented by the parent link
                    if (!std.mem.eql(u8, child.segment, "index")) {
                        try self.generateSidebarNodeHtml(child, allocator, current_path, html, depth + 1);
                    }
                }
                
                try html.appendSlice(allocator, indent);
                try html.appendSlice(allocator, "  </ul>\n");
            }
            
            try html.appendSlice(allocator, indent);
            try html.appendSlice(allocator, "</li>\n");
        }
    }
    
    fn findIndexChild(_: *RouteTree, node: *RouteNode) ?*RouteNode {
        for (node.children.items) |child| {
            if (std.mem.eql(u8, child.segment, "index")) {
                return child;
            }
        }
        return null;
    }
};

fn isAncestorOf(node: *RouteNode, path: []const u8) bool {
    // Check if the current path starts with this node's path
    // and the path is longer (meaning it's a child or deeper)
    if (node.path.len == 1) return false; // Root is ancestor of everything
    
    if (std.mem.startsWith(u8, path, node.path)) {
        // Make sure it's not the same path
        return !std.mem.eql(u8, path, node.path);
    }
    return false;
}

fn capitalizeFirst(allocator: std.mem.Allocator, s: []const u8) ![]const u8 {
    if (s.len == 0) return allocator.dupe(u8, s);
    
    var result = try allocator.dupe(u8, s);
    if (result[0] >= 'a' and result[0] <= 'z') {
        result[0] = result[0] - 'a' + 'A';
    }
    return result;
}

// Helper functions for route generation

/// Convert file path (app/deployment.zig) to identifier (app_deployment)
pub fn toIdent(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const without_ext = if (std.mem.endsWith(u8, path, ".zig")) path[0 .. path.len - 4] else path;
    const buf = try allocator.dupe(u8, without_ext);
    for (buf) |*c| {
        if (c.* != '_' and (c.* < 'a' or c.* > 'z') and (c.* < 'A' or c.* > 'Z') and (c.* < '0' or c.* > '9')) {
            c.* = '_';
        }
    }
    return buf;
}

/// Convert file path (app/deployment/cloudflare.zig) to URL path (/deployment/cloudflare)
pub fn toUrl(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
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

/// Build a route tree from a list of file paths
pub fn buildRouteTree(allocator: std.mem.Allocator, file_paths: []const []const u8) !RouteTree {
    var tree = try RouteTree.init(allocator);
    
    for (file_paths) |file_path| {
        const url_path = try toUrl(allocator, file_path);
        defer allocator.free(url_path);
        try tree.insert(file_path, url_path);
    }
    
    return tree;
}

// Tests
const testing = std.testing;

test "RouteTree basic insertion" {
    const allocator = testing.allocator;
    
    var tree = try RouteTree.init(allocator);
    defer tree.deinit();
    
    try tree.insert("app/index.zig", "/");
    try tree.insert("app/about.zig", "/about");
    try tree.insert("app/deployment/cloudflare.zig", "/deployment/cloudflare");
    
    // Check root has children
    try testing.expect(tree.root.children.items.len > 0);
    
    // Check we can find the about node
    const about = tree.root.findChild("about");
    try testing.expect(about != null);
    try testing.expect(std.mem.eql(u8, about.?.path, "/about"));
}

test "RouteTree nested structure" {
    const allocator = testing.allocator;
    
    var tree = try RouteTree.init(allocator);
    defer tree.deinit();
    
    try tree.insert("app/index.zig", "/");
    try tree.insert("app/deployment/index.zig", "/deployment");
    try tree.insert("app/deployment/cloudflare.zig", "/deployment/cloudflare");
    try tree.insert("app/deployment/vercel.zig", "/deployment/vercel");
    
    // Find deployment node
    const deployment = tree.root.findChild("deployment");
    try testing.expect(deployment != null);
    try testing.expect(deployment.?.children.items.len == 2); // cloudflare and vercel
}

test "toIdent conversion" {
    const allocator = testing.allocator;
    
    const ident1 = try toIdent(allocator, "app/index.zig");
    defer allocator.free(ident1);
    try testing.expect(std.mem.eql(u8, ident1, "app_index"));
    
    const ident2 = try toIdent(allocator, "app/deployment/cloudflare.zig");
    defer allocator.free(ident2);
    try testing.expect(std.mem.eql(u8, ident2, "app_deployment_cloudflare"));
}

test "toUrl conversion" {
    const allocator = testing.allocator;
    
    const url1 = try toUrl(allocator, "app/index.zig");
    defer allocator.free(url1);
    try testing.expect(std.mem.eql(u8, url1, "/"));
    
    const url2 = try toUrl(allocator, "app/about.zig");
    defer allocator.free(url2);
    try testing.expect(std.mem.eql(u8, url2, "/about"));
    
    const url3 = try toUrl(allocator, "app/deployment/cloudflare.zig");
    defer allocator.free(url3);
    try testing.expect(std.mem.eql(u8, url3, "/deployment/cloudflare"));
}
