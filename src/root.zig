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
}).map(mecha.toStruct(WurlAddressLocation)).map(mecha.unionInit(WurlLocation, WurlLocation.address));

const offset_location = mecha.combine(.{
    mecha.ascii.char('#').discard(),
    hex_number.opt(),
}).map(mecha.toStruct(WurlOffsetLocation)).map(mecha.unionInit(WurlLocation, WurlLocation.offset));

const line_column_location = mecha.combine(.{
    mecha.ascii.char(':').discard(),
    mecha.combine(.{
        decimal_number,
        mecha.combine(.{
            mecha.ascii.char(':').discard(),
            decimal_number,
        }).opt(),
    }).map(mecha.toStruct(WurlLineColumn)).opt(),
}).map(mecha.toStruct(WurlLineColumnLocation)).map(mecha.unionInit(WurlLocation, WurlLocation.line_column));

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
