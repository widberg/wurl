const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mecha = b.dependency("mecha", .{});
    const mecha_mod = mecha.module("mecha");

    const clap = b.dependency("clap", .{});
    const clap_mod = clap.module("clap");

    const mod = b.addModule("wurl", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "mecha", .module = mecha_mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = "wurl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "wurl", .module = mod },
                .{ .name = "clap", .module = clap_mod },
            },
        }),
    });
    if (target.result.os.tag == .windows) {
        exe.subsystem = .windows;
    }

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    const zlinter = @import("zlinter");
    const lint_cmd = b.step("lint", "Lint source code.");
    lint_cmd.dependOn(step: {
        var builder = zlinter.builder(b, .{});
        builder.addPaths(.{
            .exclude_dirs = &.{b.path("vendor")},
        });
        inline for (@typeInfo(zlinter.BuiltinLintRule).@"enum".field_values) |field_value| {
            const rule: zlinter.BuiltinLintRule = @fromBackingInt(@intCast(field_value));
            switch (rule) {
                .no_inferred_error_unions, .require_doc_comment => {},
                else => builder.addRule(.{ .builtin = rule }, .{}),
            }
        }
        break :step builder.build();
    });
}
