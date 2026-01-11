const zqlite = @import("zqlite");
const std = @import("std");

const util = @import("../util.zig");
const Customers = @import("./customers.zig");

conn: zqlite.Conn,
const Self = @This();

pub fn init(allocator: std.mem.Allocator) !Self {
    const exe_path = try std.fs.selfExePathAlloc(allocator);
    defer allocator.free(exe_path);

    const exe_dir = std.fs.path.dirname(exe_path) orelse ".";

    const db_path = try std.fs.path.joinZ(allocator, &.{ exe_dir, "assets", "ae.db" });
    defer allocator.free(db_path);

    const flags = zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;

    var self = Self{ .conn = try zqlite.open(db_path, flags) };
    try self.createTables();

    return self;
}

pub fn deinit(self: *Self) void {
    self.conn.close();
}

pub fn createTables(self: *Self) !void {
    const create_customers =
        \\CREATE TABLE IF NOT EXISTS customers (
        \\    id INTEGER PRIMARY KEY AUTOINCREMENT,
        \\    created_at INTEGER NOT NULL DEFAULT (unixepoch()),
        \\    name TEXT NOT NULL,
        \\    gstin TEXT NOT NULL,
        \\    email TEXT,
        \\    phone TEXT NOT NULL,
        \\    remark TEXT,
        \\    shop_no TEXT NOT NULL,
        \\    line_1 TEXT NOT NULL,
        \\    line_2 TEXT,
        \\    line_3 TEXT,
        \\    city TEXT NOT NULL,
        \\    state TEXT NOT NULL,
        \\    postal_code TEXT NOT NULL
        \\);
    ;

    try self.conn.exec(create_customers, .{});
}
