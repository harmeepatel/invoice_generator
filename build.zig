const std = @import("std");
const log = std.log.scoped(.ae_build);

pub fn log_debug(comptime format: []const u8, args: anytype) void {
    log.debug("\x1b[1;97m" ++ format ++ "\x1b[0m", args);
}
pub fn log_info(comptime format: []const u8, args: anytype) void {
    log.info("\x1b[1;96m" ++ format ++ "\x1b[0m", args);
}
pub fn log_warn(comptime format: []const u8, args: anytype) void {
    log.warn("\x1b[1;33m" ++ format ++ "\x1b[0m", args);
}
pub fn log_err(comptime format: []const u8, args: anytype) void {
    log.err("\x1b[1;91m" ++ format ++ "\x1b[0m", args);
}

fn initDbFile() void {
    const init_db_path = "src/assets/ae.db";
    var fs = std.fs.cwd();

    if (fs.openFile(init_db_path, .{})) |file| {
        defer file.close();
        log_info("DB found @ {s}", .{init_db_path});
    } else |err| switch (err) {
        error.FileNotFound => {
            if (std.fs.path.dirname(init_db_path)) |dir| fs.makePath(dir) catch {};

            var f = fs.createFile(init_db_path, .{}) catch {
                std.debug.panic("Problem creating file: {s}", .{init_db_path});
            };
            defer f.close();

            log_info("Creating new DB", .{});
        },
        else => |e| {
            log_err("Unexpected error: {any}", .{e});
        },
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "ae_invoice",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    {
        // dvui
        const dvui_dep = b.dependency("dvui", .{
            .target = target,
            .optimize = optimize,
            .backend = .sdl3,
        });
        exe.root_module.addImport("dvui", dvui_dep.module("dvui_sdl3"));

        // sqlite
        initDbFile();
        const zqlite = b.dependency("zqlite", .{
            .target = target,
            .optimize = optimize,
        });

        exe.linkLibC();
        exe.linkSystemLibrary("sqlite3");
        exe.root_module.addImport("zqlite", zqlite.module("zqlite"));

        const work_db_path = "zig-out/bin/assets/ae.db";
        const db_exists = blk: {
            std.fs.cwd().access(work_db_path, .{}) catch {
                break :blk false;
            };
            break :blk true;
        };

        if (!db_exists) {
            const install_assets = b.addInstallDirectory(.{
                .source_dir = b.path("src/assets"),
                .install_dir = .bin,
                .install_subdir = "assets",
            });
            b.getInstallStep().dependOn(&install_assets.step);
        } else {
            log_info("DB found @ {s}", .{work_db_path});
        }
    }

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.setCwd(b.path("zig-out/bin"));

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
