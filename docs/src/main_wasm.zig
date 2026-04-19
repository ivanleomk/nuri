const std = @import("std");
const mer = @import("mer");

// Simple WASM allocator
const WasmAllocator = struct {
    pub fn alloc(_: @This(), len: usize, _: u8) ?[*]u8 {
        return @ptrCast(std.heap.c_allocator.alloc(u8, len) catch null);
    }
    
    pub fn free(_: @This(), ptr: [*]u8, _: usize, _: u8) void {
        std.heap.c_allocator.free(ptr[0..0]);
    }
};

var gpa: WasmAllocator = .{};

// Export allocator functions for WASM
export fn alloc(size: usize) ?[*]u8 {
    return gpa.alloc(size, 1);
}

export fn free(ptr: [*]u8, size: usize) void {
    gpa.free(ptr, size, 1);
}

// Main request handler
export fn handleRequest(ptr: [*]const u8, len: usize, out_len: *usize) [*]const u8 {
    const alloc = std.heap.page_allocator;
    
    // Parse request data
    const req_data = ptr[0..len];
    
    // Initialize router
    var router = mer.Router.fromGenerated(alloc, @import("routes"));
    defer router.deinit();
    
    // Create request and dispatch
    const req = mer.Request.init(alloc, .GET, "/");
    const response = mer.dispatch(router, req);
    
    // Allocate and copy response
    const out = alloc.alloc(u8, response.body.len) catch return null;
    @memcpy(out, response.body);
    out_len.* = response.body.len;
    
    return out.ptr;
}

// Required WASM entry point
export fn _start() void {}
