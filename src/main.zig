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

fn imhex(io: std.Io, imhex_path: []const u8, open_path: []const u8, offset: u64) !void {
    const offset_str = "0x" ++ std.fmt.hex(offset);
    const argv = [_][]const u8{ imhex_path, "--open", open_path, "--select", offset_str };
    return spawn(io, &argv);
}

fn launch(io: std.Io, url: wurl.Wurl) !void {
    _ = url;
    return imhex(io, "imhex", "D:\\programming\\widberg\\wurl\\zig-out\\bin\\wurl.exe", 0);
}

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
        const url = (try wurl.parse(init.gpa, str)).value.ok;
        std.debug.print("{any}\n", .{url});
        return launch(init.io, url);
    }

    return clap.helpToFile(init.io, .stderr(), clap.Help, &params, .{});
}
