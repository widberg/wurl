const std = @import("std");
const wurl = @import("wurl");
const clap = @import("clap");

fn find_file_in_config_by_hash_prefix(config: *const wurl.config.Config, hash: []const u8) ?*const wurl.config.ConfigFile {
    for (config.files) |*file| {
        if (std.ascii.startsWithIgnoreCase(file.hash, hash)) {
            return file;
        }
    }

    return null;
}

fn launch(gpa: std.mem.Allocator, io: std.Io, config: wurl.config.Config, url: wurl.wurl.Wurl) !void {
    const file = find_file_in_config_by_hash_prefix(&config, url.hash) orelse return;

    switch (url.location.?) {
        .address => |address| {
            const config_file_ghidra = file.ghidra orelse return;
            try wurl.tool.ghidra(gpa, io, config.ghidra, config_file_ghidra, address);
        },
        .offset => |offset| {
            const path = file.path orelse return;
            try wurl.tool.imhex(io, config.imhex, path, offset);
        },
        .line_column => |line_column| {
            const path = file.path orelse return;
            try wurl.tool.vscode(gpa, io, config.vscode, path, line_column);
        },
    }
}

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

pub fn main(init: std.process.Init) !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\<str>                  Handle a protocol string.
        \\
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.positionals[0]) |str| {
        const config = try wurl.config.parse(init.gpa, init.arena.allocator(), source);
        const url = (try wurl.wurl.parse(init.gpa, str)).value.ok;
        try launch(init.gpa, init.io, config, url);
        return;
    }

    try clap.helpToFile(init.io, .stderr(), clap.Help, &params, .{});
}
