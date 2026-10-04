//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

const mecha = @import("mecha");

const WurlAddressLocation = struct {
    address: ?u64,
};

const WurlOffsetLocation = struct {
    offset: ?u64,
};

const WurlLineColumn = struct {
    line: u64,
    column: ?u64,
};

const WurlLineColumnLocation = struct {
    line_column: ?WurlLineColumn,
};

const WurlLocation = union(enum) {
    address: WurlAddressLocation,
    offset: WurlOffsetLocation,
    line_column: WurlLineColumnLocation,
};

const Wurl = struct {
    hash: []const u8,
    location: ?WurlLocation,
    extensions: ?[]const u8,
};

const protocol = mecha.string("wurl://").discard();

const hash = mecha.intToken(.{
    .parse_sign = false,
    .base = 16,
    .max_digits = 64,
});

const address_separator = mecha.ascii.char('@').discard();
const offset_separator = mecha.ascii.char('#').discard();

const hex_location = mecha.int(u64, .{
    .parse_sign = false,
    .base = 16,
}).opt();

const address_location = mecha.combine(.{
    address_separator,
    hex_location,
}).map(mecha.toStruct(WurlAddressLocation)).map(mecha.unionInit(WurlLocation, WurlLocation.address));

const offset_location = mecha.combine(.{
    offset_separator,
    hex_location,
}).map(mecha.toStruct(WurlOffsetLocation)).map(mecha.unionInit(WurlLocation, WurlLocation.offset));

const line_column_separator = mecha.ascii.char(':').discard();

const decimal_location = mecha.int(u64, .{
    .parse_sign = false,
    .base = 10,
});

const column_location = mecha.combine(.{
    line_column_separator,
    decimal_location,
}).opt();

const line_column_location_inner = mecha.combine(.{
    decimal_location,
    column_location,
}).map(mecha.toStruct(WurlLineColumn)).opt();

const line_column_location = mecha.combine(.{
    line_column_separator,
    line_column_location_inner,
}).map(mecha.toStruct(WurlLineColumnLocation)).map(mecha.unionInit(WurlLocation, WurlLocation.line_column));

const location = mecha.oneOf(.{
    address_location,
    offset_location,
    line_column_location,
}).opt();

const extension_separator = mecha.ascii.char('?').discard();

const rest = mecha.rest;

const extensions = mecha.combine(.{
    extension_separator,
    rest,
}).opt();

const eos = mecha.eos.discard();

const url = mecha.combine(.{ protocol, hash, location, extensions, eos }).map(mecha.toStruct(Wurl));

pub fn parse(allocator: std.mem.Allocator, str: []const u8) mecha.Error!mecha.Result(Wurl) {
    return try url.parse(allocator, str);
}

test "parser" {
    const testing = std.testing;
    const allocator = testing.allocator;

    _ = (try url.parse(allocator, "wurl://abcdef0@0")).value.ok;
    _ = (try url.parse(allocator, "wurl://abcdef0@0?")).value.ok;
    _ = (try url.parse(allocator, "wurl://abcdef0")).value.ok;
    _ = (try url.parse(allocator, "wurl://abcdef0@0?aaaaa")).value.ok;
    _ = (try url.parse(allocator, "wurl://abcdef0?aaaaa")).value.ok;
    _ = (try url.parse(allocator, "")).value.err;
}
