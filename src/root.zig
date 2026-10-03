//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

const mecha = @import("mecha");
const clap = @import("clap");

/// This is a documentation comment to explain the `printAnotherMessage` function below.
///
/// Accepting an `Io.Writer` instance is a handy way to write reusable code.
pub fn printAnotherMessage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.print("Run `zig build test` to run the tests.\n", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}

const WurlAddressLocation = struct {
    address: u64,
};

const WurlOffsetLocation = struct {
    offset: u64,
};

const WurlLineColumnLocation = struct {
    line: u64,
    column: u64,
};

const WurlLocation = union {
    address: WurlAddressLocation,
    offset: WurlOffsetLocation,
    line_column: WurlLineColumnLocation,
};

const Wurl = struct {
    hash: u256,
    location: WurlLocation,
};

const protocol = mecha.string("wurl://").discard();

const hash = mecha.int(u256, .{
    .parse_sign = false,
    .base = 16,
}).discard();

const address_separator = mecha.ascii.char('@').discard();
const offset_separator = mecha.ascii.char('#').discard();

const hex_location = mecha.int(u64, .{
    .parse_sign = false,
    .base = 16,
}).discard();

const address_location = mecha.combine(.{
    address_separator,
    hex_location,
}).discard();

const offset_location = mecha.combine(.{
    offset_separator,
    hex_location,
}).discard();

const line_column_separator = mecha.ascii.char(':').discard();

const decimal_location = mecha.int(u64, .{
    .parse_sign = false,
    .base = 10,
}).discard();

const line_column_location = mecha.combine(.{
    line_column_separator,
    decimal_location,
    line_column_separator,
    decimal_location,
}).discard();

const location = mecha.oneOf(.{
    address_location,
    offset_location,
    line_column_location,
}).opt().discard();

const extension_separator = mecha.ascii.char('?').discard();

const rest = mecha.rest.discard();

const extensions = mecha.combine(.{
    extension_separator,
    rest,
}).opt().discard();

const eos = mecha.eos.discard();

const url = mecha.combine(.{ protocol, hash, location, extensions, eos }).discard();

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
