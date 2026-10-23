const config = @import("config.zig");
const std = @import("std");
const wurl = @import("wurl.zig");

fn spawn(io: std.Io, argv: []const []const u8) !void {
    _ = try std.process.spawn(io, .{
        .argv = argv,
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
        .create_no_window = true,
    });
}

pub fn ghidra(gpa: std.mem.Allocator, io: std.Io, ghidra_path: []const u8, config_file_ghidra: config.Ghidra, address: ?u64) !void {
    const project = config_file_ghidra.project;
    const program = config_file_ghidra.program;

    var url = try std.ArrayList(u8).initCapacity(gpa, 0x400);
    defer url.deinit(gpa);

    try url.print(gpa, "ghidra:/", .{});

    switch (project) {
        .shared => |shared| {
            const repository = shared.repository;
            try url.print(gpa, "/{s}", .{shared.host});
            if (shared.port) |port| {
                try url.print(gpa, ":{d}", .{port});
            }
            try url.print(gpa, "/{s}/{s}", .{ repository, program });
        },
        .non_shared => |non_shared| {
            try url.print(gpa, "{s}/{s}?/{s}", .{ non_shared.path, non_shared.name, program });
        },
    }

    if (address) |addr| {
        try url.print(gpa, "#0x{x}", .{addr});
    }

    const argv = [_][]const u8{ ghidra_path, url.items };
    try spawn(io, &argv);
}

pub fn imhex(gpa: std.mem.Allocator, io: std.Io, imhex_path: []const u8, open_path: []const u8, offset: ?u64) !void {
    var argv = try std.ArrayList([]const u8).initCapacity(gpa, 0x10);
    defer argv.deinit(gpa);

    try argv.appendSlice(gpa, &[_][]const u8{ imhex_path, "--open", open_path });

    var maybe_offset_str: ?[]const u8 = null;
    defer if (maybe_offset_str) |offset_str| gpa.free(offset_str);

    if (offset) |off| {
        const offset_str = try gpa.print("0x{x}", .{off});
        maybe_offset_str = offset_str;
        try argv.appendSlice(gpa, &[_][]const u8{ "--select", offset_str });
    }

    try spawn(io, argv.items);
}

pub fn vscode(gpa: std.mem.Allocator, io: std.Io, vscode_path: []const u8, open_path: []const u8, line_column: ?wurl.LineColumn) !void {
    var goto = try std.ArrayList(u8).initCapacity(gpa, 0x400);
    defer goto.deinit(gpa);

    try goto.appendSlice(gpa, open_path);

    if (line_column) |l_c| {
        try goto.print(gpa, ":{d}", .{l_c.line});
        if (l_c.column) |column| {
            try goto.print(gpa, ":{d}", .{column});
        }
    }

    const argv = [_][]const u8{ vscode_path, "--goto", goto.items };
    try spawn(io, &argv);
}
