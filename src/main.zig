const std = @import("std");
const wurl = @import("wurl");
const clap = @import("clap");

fn load_config(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io) !wurl.config.Config {
    const exe_dir = try std.process.executableDirPathAlloc(io, gpa);
    defer gpa.free(exe_dir);

    const config_path = try std.fs.path.join(gpa, &.{ exe_dir, "wurl.zon" });
    defer gpa.free(config_path);

    const source = try std.Io.Dir.cwd().readFileAllocOptions(io, config_path, gpa, std.Io.Limit.unlimited, std.mem.Alignment.of(u8), 0);
    defer gpa.free(source);

    return try wurl.config.parse(gpa, arena, source);
}

fn find_file_in_config_by_hash_prefix(config: *const wurl.config.Config, hash: []const u8) ?*const wurl.config.File {
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
            const ghidra = config.ghidra orelse return;
            const config_file_ghidra = file.ghidra orelse return;
            try wurl.tool.ghidra(gpa, io, ghidra, config_file_ghidra, address);
        },
        .offset => |offset| {
            const imhex = config.imhex orelse return;
            const path = file.path orelse return;
            try wurl.tool.imhex(io, imhex, path, offset);
        },
        .line_column => |line_column| {
            const vscode = config.vscode orelse return;
            const path = file.path orelse return;
            try wurl.tool.vscode(gpa, io, vscode, path, line_column);
        },
    }
}

pub fn main(init: std.process.Init) !void {
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\<URL>                  Handle a protocol string.
        \\
    );

    const parsers = comptime .{
        .URL = clap.parsers.string,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, init.minimal.args, .{
        .diagnostic = &diag,
        .allocator = init.gpa,
    }) catch |err| {
        try diag.reportToFile(init.io, .stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0 or res.positionals[0] == null)
        return clap.helpToFile(init.io, .stderr(), clap.Help, &params, .{});

    const str = res.positionals[0] orelse unreachable;

    const config = try load_config(init.gpa, init.arena.allocator(), init.io);
    const url = (try wurl.wurl.parse(init.gpa, str)).value.ok;
    return launch(init.gpa, init.io, config, url);
}
