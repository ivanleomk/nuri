# Writing Zig - Practical Patterns & Best Practices

## Overview

Zig is a systems programming language focused on explicit control, compile-time computation, and error handling. Key principles: no hidden allocations, explicit error handling, and compile-time code execution.

## Memory Management

### Allocators - Explicit Control

Zig requires explicit allocators. Never use `std.heap.page_allocator` directly in production.

**Basic Pattern:**
```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Use allocator throughout
    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);
}
```

**Arena Allocator for Temp Work:**
```zig
// Great for short-lived allocations in a function
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
const temp_allocator = arena.allocator();

// All allocations freed at once when arena deinits
```

### String Building with ArrayList

**The Right Way:**
```zig
var result: std.ArrayList(u8) = .empty;
defer result.deinit(allocator);

try result.appendSlice(allocator, "Hello");
try result.append(allocator, ' ');
try result.appendSlice(allocator, "World");

const final_string = try result.toOwnedSlice(allocator);
defer allocator.free(final_string);
```

**Common Gotcha:** `ArrayList` methods take allocator as first param
```zig
// WRONG
buf.appendSlice(some_string);  // Compile error!

// RIGHT  
buf.appendSlice(allocator, some_string);
```

## Error Handling

### Error Unions

Every function that can fail returns an error union: `T!Error`

```zig
fn parseNumber(s: []const u8) !u32 {
    return try std.fmt.parseInt(u32, s, 10);
}

// Usage
const num = try parseNumber("42");  // Propagate error
const num = parseNumber("42") catch |e| {  // Handle error
    std.log.err("Failed to parse: {}", .{e});
    return e;
};
```

### The `errdefer` Pattern

Use `errdefer` for cleanup on failure (only runs if function returns error):

```zig
fn allocateAndProcess(allocator: std.mem.Allocator) ![]u8 {
    const data = try allocator.alloc(u8, 100);
    errdefer allocator.free(data);  // Only runs on error
    
    // Do processing that might fail
    try process(data);
    
    return data;  // errdefer doesn't run on success
}
```

**Note:** Regular `defer` runs on both success and error.

### Optional Types

```zig
// Optional values (can be null)
var maybe_value: ?u32 = null;
maybe_value = 42;

// Unwrap with if
if (maybe_value) |value| {
    std.debug.print("Value: {d}\n", .{value});
} else {
    std.debug.print("No value\n");
}

// Unwrap with orelse (default value)
const value = maybe_value orelse 0;

// Unwrap with try (if null, return error)
const value = maybe_value orelse return error.NoValue;
```

## Comptime Programming

### Compile-Time Execution

Zig evaluates `comptime` code at build time:

```zig
// Type as parameter
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

const result = max(i32, 5, 10);  // T is i32 at compile time
```

### Generating Code at Compile Time

```zig
const std = @import("std");

// Generate switch arms for all enum values
const Command = enum { init, build, dev, help };

fn generateSwitchBody() []const u8 {
    comptime {
        var result: []const u8 = "";
        for (@typeInfo(Command).Enum.fields) |field| {
            result = result ++ std.fmt.comptimePrint(
                ".{s} => handle{s}(),\n",
                .{ field.name, field.name }
            );
        }
        return result;
    }
}
```

### Type Info

```zig
const MyStruct = struct { x: i32, y: i32 };

// Get type information at compile time
const info = @typeInfo(MyStruct);

// Check if struct
if (info == .Struct) {
    inline for (info.Struct.fields) |field| {
        std.debug.print("Field: {s}, type: {s}\n", .{
            field.name,
            @typeName(field.type)
        });
    }
}
```

## Working with Slices and Strings

### String Literals vs Slices

```zig
// String literal (null-terminated, comptime-known)
const literal = "Hello";

// Slice (ptr + length)
const slice: []const u8 = "Hello";

// Creating a slice from literal
const slice2 = "Hello"[0..2];  // "He"
```

### Splitting and Joining

```zig
// Splitting
var iter = std.mem.splitScalar(u8, text, '\n');
while (iter.next()) |line| {
    // Process each line
}

// Joining slices
const parts = &[_][]const u8 { "Hello", "World" };
const joined = try std.mem.join(allocator, " ", parts);
defer allocator.free(joined);
```

### String Duplication

```zig
// Duplicate a string (new allocation)
const copy = try allocator.dupe(u8, original);
defer allocator.free(copy);

// Duplicate with sentinel (null-terminated)
const copy_sentinel = try allocator.dupeZ(u8, original);
defer allocator.free(copy_sentinel);
```

## Structs and Methods

### Basic Struct

```zig
const Person = struct {
    name: []const u8,
    age: u32,
    
    // Method
    pub fn greet(self: Person) void {
        std.debug.print("Hello, I'm {s}!\n", .{self.name});
    }
};

// Usage
const person = Person{ .name = "Alice", .age = 30 };
person.greet();
```

### Generic Structs

```zig
fn Queue(comptime T: type) type {
    return struct {
        items: []T,
        capacity: usize,
        allocator: std.mem.Allocator,
        
        const Self = @This();
        
        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .items = &[_]T{},
                .capacity = 0,
                .allocator = allocator,
            };
        }
        
        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }
        
        pub fn push(self: *Self, item: T) !void {
            if (self.capacity == self.items.len) {
                // Grow array
            }
            self.items[self.capacity] = item;
            self.capacity += 1;
        }
    };
}

// Usage
var int_queue = Queue(i32).init(allocator);
defer int_queue.deinit();
try int_queue.push(42);
```

## Testing

### Test Blocks

```zig
test "basic arithmetic" {
    try std.testing.expectEqual(2 + 2, 4);
}

test "allocation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const slice = try allocator.alloc(u8, 10);
    defer allocator.free(slice);
    
    try std.testing.expectEqual(slice.len, 10);
}
```

### Custom Test Runner

```zig
// In build.zig
const test_step = b.step("test", "Run all tests");

const parser_tests = b.addTest(.{
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/parser_test.zig"),
    }),
});

parser_tests.root_module.addImport("parser", b.createModule(.{
    .root_source_file = b.path("src/parser.zig"),
}));

test_step.dependOn(&b.addRunArtifact(parser_tests).step);
```

## Common Patterns

### Result Type (Error or Value)

```zig
const Result = union(enum) {
    ok: []const u8,
    err: ParseError,
};

fn parseMaybe(input: []const u8) Result {
    if (input.len == 0) {
        return .{ .err = .EmptyInput };
    }
    return .{ .ok = input };
}
```

### Hash Maps

```zig
var map = std.StringHashMap(u32).init(allocator);
defer {
    var it = map.keyIterator();
    while (it.next()) |key| {
        allocator.free(key.*);  // If you allocated keys
    }
    map.deinit();
}

try map.put("key", 42);
const value = map.get("key");
```

### Iterating

```zig
// Over array
const items = &[_]i32{ 1, 2, 3, 4, 5 };
for (items) |item| {
    std.debug.print("{d}\n", .{item});
}

// With index
for (items, 0..) |item, index| {
    std.debug.print("[{d}] = {d}\n", .{ index, item });
}

// Over range
for (0..10) |i| {
    std.debug.print("{d}\n", .{i});
}

// While with error handling
while (try reader.readLine()) |line| {
    // Process line
}
```

## File I/O

### Reading Files

```zig
// Read entire file
const contents = try std.fs.cwd().readFileAlloc(
    allocator,
    "input.txt",
    1024 * 1024,  // max size
);
defer allocator.free(contents);

// Read line by line
const file = try std.fs.cwd().openFile("input.txt", .{});
defer file.close();

var buf_reader = std.io.bufferedReader(file.reader());
var in_stream = buf_reader.reader();

var buf: [1024]u8 = undefined;
while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    // Process line
}
```

### Writing Files

```zig
const file = try std.fs.cwd().createFile("output.txt", .{});
defer file.close();

try file.writeAll("Hello, World!\n");
try file.writer().print("Number: {d}\n", .{42});
```

## Build System

### Basic build.zig

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Executable
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    
    b.installArtifact(exe);
    
    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
    
    // Tests
    const unit_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
```

### Dependencies (build.zig.zon)

```zig
.{
    .name = .myproject,
    .version = "0.1.0",
    .dependencies = .{
        .merjs = .{
            .url = "git+https://github.com/justrach/merjs.git#v0.2.5",
            .hash = "merjs-0.2.5-qL9LkhRVZABuCKYsftrbz81_-4FGVeJMskrxGEw5obBo",
        },
    },
}
```

## Common Gotchas

1. **ArrayList needs allocator param** - Always pass allocator to ArrayList methods

2. **defer runs at end of scope** - Not end of function:
   ```zig
   {
       const mem = try allocator.alloc(u8, 10);
       defer allocator.free(mem);  // Frees at closing brace
   }  // mem freed here
   ```

3. **Slices don't own memory** - They just point to data:
   ```zig
   const slice = some_array[0..5];
   // slice doesn't need freeing - it's borrowing
   ```

4. **Strings are []const u8, not null-terminated** - Use `dupeZ` for C interop

5. **Error unions with !** - Functions that can fail must use `!Type`:
   ```zig
   fn foo() !u32 { ... }  // Can return error
   fn bar() u32 { ... }   // Cannot fail
   ```

6. **Comptime vs Runtime** - Code must be explicit about when it runs:
   ```zig
   var x = comptime calculate();  // Evaluated at build time
   var y = calculate();          // Evaluated at runtime
   ```

## Debugging Tips

```zig
// Print values
std.debug.print("Value: {any}\n", .{value});

// Print type
std.debug.print("Type: {s}\n", .{@typeName(@TypeOf(value))});

// Assert
std.debug.assert(x > 0);

// Panic on unreachable
unreachable;  // Compiler will tell you this code shouldn't run

// Compile error message
@compileError("Not implemented");
```

## Resources

- [Zig Documentation](https://ziglang.org/documentation/master/)
- [Zig Learn](https://ziglearn.org/)
- [Standard Library](https://ziglang.org/documentation/master/std/)
- Community: ziglang.org/community