pub const config = @import("config.zig");
pub const tool = @import("tool.zig");
pub const wurl = @import("wurl.zig");

test {
    _ = wurl;
    _ = config;
    _ = tool;
}
