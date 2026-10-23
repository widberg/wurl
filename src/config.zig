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

    pub fn findFileByHashPrefix(self: *const Config, hash: []const u8) error{ DuplicateHash, NoHash }!*const File {
        var result: ?*const File = null;

        for (self.files) |*file| {
            if (std.ascii.startsWithIgnoreCase(file.hash, hash)) {
                if (result != null) {
                    return error.DuplicateHash;
                }
                result = file;
            }
        }

        return result orelse error.NoHash;
    }
};

pub fn parse(gpa: std.mem.Allocator, arena: std.mem.Allocator, source: [:0]const u8, diagnostics: *std.zon.parse.Diagnostics) !Config {
    return std.zon.parse.fromSlice(Config, .{ .gpa = gpa, .arena = arena, .source = source, .diagnostics = diagnostics, .ignore_unknown_fields = false });
}

test "config" {
    const testing = std.testing;
    const gpa = testing.allocator;
    var arena_allocator: std.heap.ArenaAllocator = .init(gpa);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    var diagnostics: std.zon.parse.Diagnostics = undefined;

    const source =
        \\.{
        \\  .imhex = "imhex",
        \\  .vscode = "code",
        \\  .ghidra = "C:\\Users\\widberg\\AppData\\Local\\gvm\\ghidra_12.1.4_PUBLIC\\support\\GhidraGo\\GhidraGo.bat",
        \\  .files = .{
        \\    .{
        \\      .hash = "abcdef0756152162531abcd",
        \\      .path = "D:\\programming\\widberg\\wurl\\zig-out\\bin\\wurl.exe",
        \\      .ghidra = .{
        \\        .project = .{
        \\          .non_shared = .{
        \\            .path = "C:/Users/widberg/Downloads/cars",
        \\            .name = "cars"
        \\          }
        \\        },
        \\        .program = "default.xex"
        \\      }
        \\    }
        \\  }
        \\}
        \\
    ;

    _ = try parse(gpa, arena, source, &diagnostics);
    _ = try std.testing.expectError(error.ParseZon, parse(gpa, arena, "", &diagnostics));
}
