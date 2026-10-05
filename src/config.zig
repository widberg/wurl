const std = @import("std");

pub const GhidraProjectShared = struct {
    host: []const u8,
    port: ?u16 = null,
    repository: []const u8,
};

pub const GhidraProjectNonShared = struct {
    path: []const u8,
    name: []const u8,
};

pub const GhidraProject = union(enum) {
    shared: GhidraProjectShared,
    non_shared: GhidraProjectNonShared,
};

pub const Ghidra = struct {
    project: GhidraProject,
    program: []const u8,
};

pub const File = struct {
    hash: []const u8,
    path: ?[]const u8 = null,
    ghidra: ?Ghidra = null,
};

pub const Config = struct {
    imhex: ?[]const u8 = null,
    vscode: ?[]const u8 = null,
    ghidra: ?[]const u8 = null,
    files: []const File,
};

pub fn parse(gpa: std.mem.Allocator, arena: std.mem.Allocator, source: [:0]const u8) !Config {
    var diagnostics: std.zon.parse.Diagnostics = undefined;
    return std.zon.parse.fromSlice(Config, .{ .gpa = gpa, .arena = arena, .source = source, .diagnostics = &diagnostics, .ignore_unknown_fields = false });
}

test "config" {
    const testing = std.testing;
    const gpa = testing.allocator;
    var arena_allocator: std.heap.ArenaAllocator = .init(gpa);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    _ = try parse(gpa, arena, ".{ .imhex = \"imhex\", .vscode = \"code\", .ghidra = \"ghidra\", .files = .{ .{ .hash = \"aaaaa\", .path = \"blah\" }, .{ .hash = \"bbbbb\", .path = \"cry\", .ghidra = .{ .project = . { .non_shared = .{ .path = \"project\", .name = \"project\" } }, .program = \"program\" } } } }");
}
