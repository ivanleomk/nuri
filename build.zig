const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "nuri",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

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
    parser_tests.root_module.addImport("parser", b.createModule(.{
        .root_source_file = b.path("src/parser.zig"),
    }));
    parser_tests.root_module.addImport("ast", b.createModule(.{
        .root_source_file = b.path("src/ast.zig"),
    }));

    const run_parser_tests = b.addRunArtifact(parser_tests);

    // Generator tests
    const generator_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/generator_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    generator_tests.root_module.addImport("ast", b.createModule(.{
        .root_source_file = b.path("src/ast.zig"),
    }));
    generator_tests.root_module.addImport("generator", b.createModule(.{
        .root_source_file = b.path("src/generator.zig"),
    }));

    const run_generator_tests = b.addRunArtifact(generator_tests);

    // Main test step
    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_parser_tests.step);
    test_step.dependOn(&run_generator_tests.step);
}
