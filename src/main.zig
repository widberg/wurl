const std = @import("std");
const Io = std.Io;

const wurl = @import("wurl");
const clap = @import("clap");

pub fn main(init: std.process.Init) !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\--install              Install the protocol handler.
        \\--uninstall            Uninstall the protocol handler.
        \\--launch <str>         Handle a protocol string.
        \\
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
    }) catch |err| {
        // Report useful error and exit.
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        return clap.helpToFile(init.io, .stderr(), clap.Help, &params, .{});
    if (res.args.launch) |str| {
        const parsed_wurl = (try wurl.parse(init.gpa, str)).value.ok;
        std.debug.print("{any}\n", .{parsed_wurl});
    }
}
