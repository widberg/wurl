const std = @import("std");
const wurl = @import("wurl");
const clap = @import("clap");

fn spawn(io: std.Io, argv: []const []const u8) !void {
    _ = try std.process.spawn(io, .{
        .argv = argv,
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
    });
}

fn ghidra(io: std.Io, ghidra_path: []const u8, open_path: []const u8, address: u64) !void {
    _ = io;
    _ = ghidra_path;
    _ = open_path;
    _ = address;
}

fn imhex(io: std.Io, imhex_path: []const u8, open_path: []const u8, offset: u64) !void {
    const offset_str = "0x" ++ std.fmt.hex(offset);
    const argv = [_][]const u8{ imhex_path, "--open", open_path, "--select", offset_str };
    return spawn(io, &argv);
}

fn vscode(gpa: std.mem.Allocator, io: std.Io, vscode_path: []const u8, open_path: []const u8, line: u64, column: u64) !void {
    const open = try std.fmt.allocPrint(gpa, "{s}:{d}:{d}", .{ open_path, line, column });
    const argv = [_][]const u8{ vscode_path, "--goto", open };
    _ = try spawn(io, &argv);
    gpa.free(open);
}

fn find_file_in_config_by_hash_prefix(config: wurl.Config, hash: []const u8) ?*const wurl.ConfigFile {
    for (config.files) |file| {
        if (std.ascii.startsWithIgnoreCase(file.hash, hash)) {
            return &file;
        }
    }

    return null;
}

fn launch(gpa: std.mem.Allocator, io: std.Io, config: wurl.Config, url: wurl.Wurl) !void {
    const file = find_file_in_config_by_hash_prefix(config, url.hash) orelse return;

    switch (url.location.?) {
        .address => |address_location| {
            const address = address_location.address orelse 0;
            return ghidra(io, config.ghidra, file.path, address);
        },
        .offset => |offset_location| {
            const offset = offset_location.offset orelse 0;
            return imhex(io, config.imhex, file.path, offset);
        },
        .line_column => |line_column_location| {
            const line_column = line_column_location.line_column orelse wurl.WurlLineColumn{ .line = 0, .column = null };
            const line = line_column.line;
            const column = line_column.column orelse 0;
            return vscode(gpa, io, config.vscode, file.path, line, column);
        },
    }
}

const source =
    \\.{
    \\  .imhex = "imhex",
    \\  .vscode = "code",
    \\  .ghidra = "C:\Users\widberg\AppData\Local\gvm\ghidra_12.1.4_PUBLIC\ghidraRun.bat",
    \\  .files = .{
    \\    .{
    \\      .hash = "abcdef0756152162531abcd",
    \\      .path = "D:\\programming\\widberg\\wurl\\zig-out\\bin\\wurl.exe",
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
        const config = try wurl.config(init.gpa, init.arena.allocator(), source);
        const url = (try wurl.parse(init.gpa, str)).value.ok;

        std.debug.print("{any}\n", .{config});
        std.debug.print("{any}\n", .{url});
        return launch(init.gpa, init.io, config, url);
    }

    return clap.helpToFile(init.io, .stderr(), clap.Help, &params, .{});
}
