const mecha = @import("mecha");
const std = @import("std");

pub const LineColumn = struct {
    line: u64,
    column: ?u64,
};

pub const Location = union(enum) {
    address: ?u64,
    line_column: ?LineColumn,
    offset: ?u64,
};

pub const Wurl = struct {
    hash: []const u8,
    location: ?Location,
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
}).map(mecha.unionInit(Location, Location.address));

const offset_location = mecha.combine(.{
    mecha.ascii.char('#').discard(),
    hex_number.opt(),
}).map(mecha.unionInit(Location, Location.offset));

const line_column_location = mecha.combine(.{
    mecha.ascii.char(':').discard(),
    mecha.combine(.{
        decimal_number,
        mecha.combine(.{
            mecha.ascii.char(':').discard(),
            decimal_number,
        }).opt(),
    }).map(mecha.toStruct(LineColumn)).opt(),
}).map(mecha.unionInit(Location, Location.line_column));

const location = mecha.oneOf(.{
    address_location,
    offset_location,
    line_column_location,
}).opt();

const extensions = mecha.combine(.{
    mecha.ascii.char('?').discard(),
    mecha.rest,
}).opt();

const url = mecha.combine(.{ mecha.string("wurl:").opt().discard(), hash, location, extensions, mecha.eos }).map(mecha.toStruct(Wurl));

pub fn parse(allocator: std.mem.Allocator, str: []const u8) mecha.Error!mecha.Result(Wurl) {
    return url.parse(allocator, str);
}

test "parser" {
    const testing = std.testing;
    const allocator = testing.allocator;

    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl:abcdef0@0")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = 0 }, .extensions = null });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "abcdef0@0")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = 0 }, .extensions = null });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl:abcdef0@0?")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = 0 }, .extensions = "" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl:abcdef0")).value.ok, Wurl{ .hash = "abcdef0", .location = null, .extensions = null });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl:abcdef0@0?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = 0 }, .extensions = "aaaaa" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "abcdef0@0?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = 0 }, .extensions = "aaaaa" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl:abcdef0@?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = .{ .address = null }, .extensions = "aaaaa" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "wurl:abcdef0?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = null, .extensions = "aaaaa" });
    _ = try testing.expectEqualDeep((try url.parse(allocator, "abcdef0?aaaaa")).value.ok, Wurl{ .hash = "abcdef0", .location = null, .extensions = "aaaaa" });

    _ = (try url.parse(allocator, "")).value.err;
    _ = (try url.parse(allocator, "asdasds://abcdef0")).value.err;
    _ = (try url.parse(allocator, "wurl:")).value.err;
    _ = (try url.parse(allocator, "wurl:?")).value.err;
    _ = (try url.parse(allocator, "?")).value.err;
    _ = (try url.parse(allocator, "wurl:@0")).value.err;
    _ = (try url.parse(allocator, "@0")).value.err;
    _ = (try url.parse(allocator, "wurl:abcdef0@#?")).value.err;
    _ = (try url.parse(allocator, "abcdef0@#?")).value.err;
}
