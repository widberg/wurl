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

fn ghidra(gpa: std.mem.Allocator, io: std.Io, ghidra_path: []const u8, config_file_ghidra: wurl.ConfigFileGhidra, address: ?u64) !void {
    const project = config_file_ghidra.project;
    const program = config_file_ghidra.program;

    var url = try std.ArrayList(u8).initCapacity(gpa, 0x400);
    defer url.deinit(gpa);

    try url.print(gpa, "ghidra:/", .{});

    switch (project) {
        .shared => |shared| {
            const repository = shared.repository;
            try url.print(gpa, "/{s}", .{shared.host});
            if (shared.port) |port| {
                try url.print(gpa, ":{d}", .{port});
            }
            try url.print(gpa, "/{s}/{s}", .{ repository, program });
        },
        .non_shared => |non_shared| {
            try url.print(gpa, "{s}/{s}?/{s}", .{ non_shared.path, non_shared.name, program });
        },
    }

    if (address) |addr| {
        try url.print(gpa, "#0x{x}", .{addr});
    }

    const argv = [_][]const u8{ ghidra_path, url.items };
    try spawn(io, &argv);
}

fn imhex(io: std.Io, imhex_path: []const u8, open_path: []const u8, offset: ?u64) !void {
    const argv_prefix = [_][]const u8{ imhex_path, "--open", open_path };
    if (offset) |off| {
        const offset_str = "0x" ++ std.fmt.hex(off);
        const argv = argv_prefix ++ [_][]const u8{ "--select", offset_str };
        try spawn(io, &argv);
    } else {
        const argv = argv_prefix;
        try spawn(io, &argv);
    }
}

fn vscode(gpa: std.mem.Allocator, io: std.Io, vscode_path: []const u8, open_path: []const u8, line_column: ?wurl.WurlLineColumn) !void {
    var goto = try std.ArrayList(u8).initCapacity(gpa, 0x400);
    defer goto.deinit(gpa);

    try goto.appendSlice(gpa, open_path);

    if (line_column) |l_c| {
        try goto.print(gpa, ":{d}", .{l_c.line});
        if (l_c.column) |column| {
            try goto.print(gpa, ":{d}", .{column});
        }
    }

    const argv = [_][]const u8{ vscode_path, "--goto", goto.items };
    try spawn(io, &argv);
}

fn find_file_in_config_by_hash_prefix(config: *const wurl.Config, hash: []const u8) ?*const wurl.ConfigFile {
    for (config.files) |*file| {
        if (std.ascii.startsWithIgnoreCase(file.hash, hash)) {
            return file;
        }
    }

    return null;
}

fn launch(gpa: std.mem.Allocator, io: std.Io, config: wurl.Config, url: wurl.Wurl) !void {
    const file = find_file_in_config_by_hash_prefix(&config, url.hash) orelse return;

    switch (url.location.?) {
        .address => |address| {
            const config_file_ghidra = file.ghidra orelse return;
            try ghidra(gpa, io, config.ghidra, config_file_ghidra, address);
        },
        .offset => |offset| {
            const path = file.path orelse return;
            try imhex(io, config.imhex, path, offset);
        },
        .line_column => |line_column| {
            const path = file.path orelse return;
            try vscode(gpa, io, config.vscode, path, line_column);
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
        const config = try wurl.config(init.gpa, init.arena.allocator(), source);
        const url = (try wurl.parse(init.gpa, str)).value.ok;
        try launch(init.gpa, init.io, config, url);
        return;
    }

    try clap.helpToFile(init.io, .stderr(), clap.Help, &params, .{});
}
