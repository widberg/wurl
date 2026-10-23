const builtin = @import("builtin");
const clap = @import("clap");
const std = @import("std");
const wurl = @import("wurl");

extern "kernel32" fn AttachConsole(process_id: std.os.windows.DWORD) callconv(.winapi) std.os.windows.BOOL;
// zlinter-disable-next-line declaration_naming - Preserve the Windows API constant name.
const ATTACH_PARENT_PROCESS = std.math.maxInt(std.os.windows.DWORD);

const Error = error{
    NoTool,
    NoPath,
    NoGhidra,
    InvalidWurl,
};

fn loadConfig(gpa: std.mem.Allocator, arena: std.mem.Allocator, io: std.Io) !wurl.config.Config {
    const exe_dir = try std.process.executableDirPathAlloc(io, gpa);
    defer gpa.free(exe_dir);

    const config_path = try std.Io.Dir.path.join(gpa, &.{ exe_dir, "wurl.zon" });
    defer gpa.free(config_path);

    const source = try std.Io.Dir.cwd().readFileAllocOptions(io, config_path, gpa, std.Io.Limit.unlimited, std.mem.Alignment.of(u8), 0);
    defer gpa.free(source);

    var diagnostics: std.zon.parse.Diagnostics = undefined;
    const config = wurl.config.parse(gpa, arena, source, &diagnostics);

    var buf: [1024]u8 = undefined;
    const stderr = std.Io.File.stderr();
    var file_writer = stderr.writer(io, &buf);

    const formatter = diagnostics.fmt(config_path);
    try formatter.format(&file_writer.interface);
    try file_writer.flush();

    return config;
}

fn launch(gpa: std.mem.Allocator, io: std.Io, config: wurl.config.Config, url: wurl.wurl.Wurl) !void {
    const file = try config.findFileByHashPrefix(url.hash);

    const location = url.location orelse wurl.wurl.Location{ .address = null };

    switch (location) {
        .address => |address| {
            const ghidra = config.ghidra orelse return Error.NoTool;
            const config_file_ghidra = file.ghidra orelse return Error.NoGhidra;
            try wurl.tool.ghidra(gpa, io, ghidra, config_file_ghidra, address);
        },
        .offset => |offset| {
            const imhex = config.imhex orelse return Error.NoTool;
            const path = file.path orelse return Error.NoPath;
            try wurl.tool.imhex(gpa, io, imhex, path, offset);
        },
        .line_column => |line_column| {
            const vscode = config.vscode orelse return Error.NoTool;
            const path = file.path orelse return Error.NoPath;
            try wurl.tool.vscode(gpa, io, vscode, path, line_column);
        },
    }
}

pub fn main(init: std.process.Init) !void {
    if (builtin.os.tag == .windows) {
        _ = AttachConsole(ATTACH_PARENT_PROCESS);
    }

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

    if (res.args.help != 0 or res.positionals[0] == null) {
        return clap.helpToFile(init.io, .stderr(), clap.Help, &params, .{});
    }

    const str = res.positionals[0].?;
    const url = switch ((try wurl.wurl.parse(init.gpa, str)).value) {
        .ok => |url| url,
        .err => return Error.InvalidWurl,
    };
    const config = try loadConfig(init.gpa, init.arena.allocator(), init.io);
    return launch(init.gpa, init.io, config, url);
}
