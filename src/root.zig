const std = @import("std");
const mecha = @import("mecha");

pub const WurlAddressLocation = struct {
    address: ?u64,
};

pub const WurlOffsetLocation = struct {
    offset: ?u64,
};

pub const WurlLineColumn = struct {
    line: u64,
    column: ?u64,
};

pub const WurlLineColumnLocation = struct {
    line_column: ?WurlLineColumn,
};

pub const WurlLocation = union(enum) {
    address: WurlAddressLocation,
    offset: WurlOffsetLocation,
    line_column: WurlLineColumnLocation,
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
    return url.parse(allocator, str);
}

test "parser" {
    const testing = std.testing;
    const allocator = testing.allocator;

    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0@0")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = .{ .address = 0 } }, .extensions = null });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0@0?")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = .{ .address = 0 } }, .extensions = "" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0")).value.ok, Wurl{ .hash = "abcdef0", .location = null, .extensions = null });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0@0?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = .{ .address = 0 } }, .extensions = "aaaaa" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0@?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = .{ .address = null } }, .extensions = "aaaaa" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl://abcdef0?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = null, .extensions = "aaaaa" });

    _ = (try url.parse(allocator, "")).value.err;
    _ = (try url.parse(allocator, "asdasds://abcdef0")).value.err;
    _ = (try url.parse(allocator, "wurl://")).value.err;
    _ = (try url.parse(allocator, "wurl://?")).value.err;
    _ = (try url.parse(allocator, "wurl://abcdef0@#?")).value.err;
}
