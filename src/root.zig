const std = @import("std");
const mecha = @import("mecha");

pub const WurlLineColumn = struct {
    line: u64,
    column: ?u64,
};

pub const WurlLocation = union(enum) {
    address: ?u64,
    offset: ?u64,
    line_column: ?WurlLineColumn,
};

pub const Wurl = struct {
    hash: []const u8,
    location: ?WurlLocation,
    extensions: ?[]const u8,
};

const hash = mecha.intToken(.{
    .parse_sign = false,
    .base = 16,
    .max_digits = 64,
});

const hex_number = mecha.int(u64, .{
    .parse_sign = false,
    .base = 16,
});

const decimal_number = mecha.int(u64, .{
    .parse_sign = false,
    .base = 10,
});

const address_location = mecha.combine(.{
    mecha.ascii.char('@').discard(),
    hex_number.opt(),
}).map(mecha.unionInit(WurlLocation, WurlLocation.address));

const offset_location = mecha.combine(.{
    mecha.ascii.char('#').discard(),
    hex_number.opt(),
}).map(mecha.unionInit(WurlLocation, WurlLocation.offset));

const line_column_location = mecha.combine(.{
    mecha.ascii.char(':').discard(),
    mecha.combine(.{
        decimal_number,
        mecha.combine(.{
            mecha.ascii.char(':').discard(),
            decimal_number,
        }).opt(),
    }).map(mecha.toStruct(WurlLineColumn)).opt(),
}).map(mecha.unionInit(WurlLocation, WurlLocation.line_column));

const location = mecha.oneOf(.{
    address_location,
    offset_location,
    line_column_location,
}).opt();

const extensions = mecha.combine(.{
    mecha.ascii.char('?').discard(),
    mecha.rest,
}).opt();

const url = mecha.combine(.{ mecha.string("wurl://").discard(), hash, location, extensions, mecha.eos }).map(mecha.toStruct(Wurl));

pub fn parse(allocator: std.mem.Allocator, str: []const u8) mecha.Error!mecha.Result(Wurl) {
    return url.parse(allocator, str);
}

test "parser" {
    const testing = std.testing;
    const allocator = testing.allocator;

    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0@0")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = 0 }, .extensions = null });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0@0?")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = 0 }, .extensions = "" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0")).value.ok, Wurl{ .hash = "abcdef0", .location = null, .extensions = null });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0@0?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = 0 }, .extensions = "aaaaa" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0@?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = null }, .extensions = "aaaaa" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = null, .extensions = "aaaaa" });

    _ = (try url.parse(allocator, "")).value.err;
    _ = (try url.parse(allocator, "asdasds://abcdef0")).value.err;
    _ = (try url.parse(allocator, "wurl://")).value.err;
    _ = (try url.parse(allocator, "wurl://?")).value.err;
    _ = (try url.parse(allocator, "wurl://@0")).value.err;
    _ = (try url.parse(allocator, "wurl://abcdef0@#?")).value.err;
}

pub const ConfigFileGhidraProjectShared = struct {
    host: []const u8,
    port: ?u16 = null,
    repository: []const u8,
};

pub const ConfigFileGhidraProjectNonShared = struct {
    path: []const u8,
    name: []const u8,
};

pub const ConfigFileGhidraProject = union(enum) {
    shared: ConfigFileGhidraProjectShared,
    non_shared: ConfigFileGhidraProjectNonShared,
};

pub const ConfigFileGhidra = struct {
    project: ConfigFileGhidraProject,
    program: []const u8,
};

pub const ConfigFile = struct {
    hash: []const u8,
    path: ?[]const u8 = null,
    ghidra: ?ConfigFileGhidra = null,
};

pub const Config = struct {
    imhex: []const u8,
    vscode: []const u8,
    ghidra: []const u8,
    files: []const ConfigFile,
};

pub fn config(gpa: std.mem.Allocator, arena: std.mem.Allocator, source: [:0]const u8) !Config {
    var diagnostics: std.zon.parse.Diagnostics = undefined;
    return std.zon.parse.fromSlice(Config, .{ .gpa = gpa, .arena = arena, .source = source, .diagnostics = &diagnostics, .ignore_unknown_fields = false });
}

test "config" {
    const testing = std.testing;
    const gpa = testing.allocator;
    var arena_allocator: std.heap.ArenaAllocator = .init(gpa);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    _ = try config(gpa, arena, ".{ .imhex = \"imhex\", .vscode = \"code\", .ghidra = \"ghidra\", .files = .{ .{ .hash = \"aaaaa\", .path = \"blah\" }, .{ .hash = \"bbbbb\", .path = \"cry\", .ghidra = .{ .project = . { .non_shared = .{ .path = \"project\", .name = \"project\" } }, .program = \"program\" } } } }");
}
