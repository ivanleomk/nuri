const std = @import("std");

pub const Node = union(enum) {
    document: []const Node,
    heading: struct {
        level: u8,
        id: ?[]const u8,
        content: []const Node,
    },
    paragraph: []const Node,
    list: struct {
        ordered: bool,
        items: []const Node,
    },
    list_item: []const Node,
    code_block: struct {
        language: ?[]const u8,
        content: []const u8,
    },
    table: struct {
        headers: []const []const u8,
        rows: []const []const []const u8,
    },
    text: []const u8,
    bold: []const Node,
    italic: []const Node,
    code: []const u8,
    link: struct {
        text: []const u8,
        url: []const u8,
    },
    line_break,

    pub fn deinit(self: Node, allocator: std.mem.Allocator) void {
        switch (self) {
            .document => |nodes| deinitNodes(nodes, allocator),
            .heading => |h| {
                if (h.id) |id| allocator.free(id);
                deinitNodes(h.content, allocator);
            },
            .paragraph => |nodes| deinitNodes(nodes, allocator),
            .list => |l| deinitNodes(l.items, allocator),
            .list_item => |nodes| deinitNodes(nodes, allocator),
            .bold => |nodes| deinitNodes(nodes, allocator),
            .italic => |nodes| deinitNodes(nodes, allocator),
            .code_block => |cb| {
                if (cb.language) |lang| allocator.free(lang);
                allocator.free(cb.content);
            },
            .table => |t| {
                for (t.headers) |h| allocator.free(h);
                allocator.free(t.headers);
                for (t.rows) |row| {
                    for (row) |cell| allocator.free(cell);
                    allocator.free(row);
                }
                allocator.free(t.rows);
            },
            .text => |s| allocator.free(s),
            .code => |s| allocator.free(s),
            .link => |l| {
                allocator.free(l.text);
                allocator.free(l.url);
            },
            else => {},
        }
    }

    fn deinitNodes(nodes: []const Node, allocator: std.mem.Allocator) void {
        for (nodes) |node| {
            node.deinit(allocator);
        }
        allocator.free(nodes);
    }
};

pub const Document = struct {
    meta: Meta,
    content: []const Node,

    pub fn deinit(self: Document, allocator: std.mem.Allocator) void {
        self.meta.deinit(allocator);
        for (self.content) |node| {
            node.deinit(allocator);
        }
        allocator.free(self.content);
    }
};

pub const Meta = struct {
    title: ?[]const u8,
    description: ?[]const u8,

    pub fn deinit(self: Meta, allocator: std.mem.Allocator) void {
        if (self.title) |t| allocator.free(t);
        if (self.description) |d| allocator.free(d);
    }
};
