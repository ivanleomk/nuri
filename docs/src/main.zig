const std = @import("std");
const mer = @import("mer");
const runtime = @import("runtime");

pub fn main() void {
    // WASM entry point for Cloudflare Workers
}

// Export the request handler for the JS wrapper
export fn handleRequest(ptr: [*]const u8, len: usize, out_len: *usize) [*]const u8 {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    
    runtime.init(alloc) catch return null;
    defer runtime.deinit();
    
    var router = mer.Router.fromGenerated(alloc, @import("routes"));
    defer router.deinit();
    
    // Parse the request from shared memory
    const req_data = ptr[0..len];
    
    // Create a simple request and dispatch
    const req = mer.Request.init(alloc, .GET, "/");
    const response = mer.dispatch(router, req);
    
    // Allocate output buffer
    const out = alloc.alloc(u8, response.body.len) catch return null;
    @memcpy(out, response.body);
    out_len.* = response.body.len;
    
    return out.ptr;
}
