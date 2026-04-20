const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create modules
    const ast_mod = b.createModule(.{
        .root_source_file = b.path("src/ast.zig"),
    });
    
    const parser_mod = b.createModule(.{
        .root_source_file = b.path("src/parser.zig"),
    });
    parser_mod.addImport("ast", ast_mod);
    
    const generator_mod = b.createModule(.{
        .root_source_file = b.path("src/generator.zig"),
    });
    generator_mod.addImport("ast", ast_mod);
    
    const route_tree_mod = b.createModule(.{
        .root_source_file = b.path("src/route_tree.zig"),
    });

    // Main executable
    const exe = b.addExecutable(.{
        .name = "nuri",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("ast", ast_mod);
    exe.root_module.addImport("parser", parser_mod);
    exe.root_module.addImport("generator", generator_mod);
    exe.root_module.addImport("route_tree", route_tree_mod);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Parser tests
    const parser_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/parser_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    parser_tests.root_module.addImport("parser", parser_mod);
    parser_tests.root_module.addImport("ast", ast_mod);

    const run_parser_tests = b.addRunArtifact(parser_tests);

    // Generator tests
    const generator_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/generator_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    generator_tests.root_module.addImport("ast", ast_mod);
    generator_tests.root_module.addImport("generator", generator_mod);

    const run_generator_tests = b.addRunArtifact(generator_tests);

    // Route tree tests
    const route_tree_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/route_tree.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_route_tree_tests = b.addRunArtifact(route_tree_tests);

    // Main test step
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_parser_tests.step);
    test_step.dependOn(&run_generator_tests.step);
    test_step.dependOn(&run_route_tree_tests.step);
}
