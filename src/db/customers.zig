const std = @import("std");
const zqlite = @import("zqlite");

const util = @import("../util.zig");
const form_field = @import("../components/form_field.zig");

conn: *zqlite.Conn,

const Self = @This();

pub const SetCustomerFieldError = error{
    UnknownFieldKind,
    OutOfMemory,
};

// db struct
pub const Address = struct {
    shop_no: []const u8,
    line_1: []const u8,
    line_2: ?[]const u8 = null,
    line_3: ?[]const u8 = null,
    state: []const u8,
    city: []const u8,
    postal_code: []const u8,

    pub fn format(alloc: std.mem.Allocator, self: Address) ![]const u8 {
        var parts = std.ArrayList([]const u8);

        try parts.append(alloc, self.shop_no);
        try parts.append(alloc, self.line_1);
        if (self.line_2) |l2| try parts.append(alloc, l2);
        if (self.line_3) |l3| try parts.append(alloc, l3);
        try parts.append(alloc, self.city);
        try parts.append(alloc, self.state);

        const main = std.mem.join(alloc, ", ", parts.items);

        return std.fmt.allocPrint(alloc, "{s}, India - {s}", .{ main, self.postal_code });
    }

    pub fn deinit(self: *Address, alloc: std.mem.Allocator) void {
        if (self.shop_no.len > 0) alloc.free(self.shop_no);
        if (self.line_1.len > 0) alloc.free(self.line_1);
        if (self.line_2) |l2| alloc.free(l2);
        if (self.line_3) |l3| alloc.free(l3);
        if (self.city.len > 0) alloc.free(self.city);
        if (self.state.len > 0) alloc.free(self.state);
        if (self.postal_code.len > 0) alloc.free(self.postal_code);
    }
};

// eg gstin: 24ABCDE1234F2Z5
pub const Customer = struct {
    id: i64,
    created_at: i64,
    name: []const u8,
    gstin: []const u8,
    email: ?[]const u8,
    phone: []const u8,
    remark: ?[]const u8,
    address: Address,

    pub fn init() Customer {
        return .{
            .id = 0,
            .created_at = 0,
            .name = &[_]u8{},
            .gstin = &[_]u8{},
            .email = null,
            .phone = &[_]u8{},
            .remark = null,
            .address = .{
                .shop_no = &[_]u8{},
                .line_1 = &[_]u8{},
                .line_2 = null,
                .line_3 = null,
                .state = &[_]u8{},
                .city = &[_]u8{},
                .postal_code = &[_]u8{},
            },
        };
    }

    pub fn deinit(self: *Customer, alloc: std.mem.Allocator) void {
        if (self.name.len > 0) alloc.free(self.name);
        if (self.gstin.len > 0) alloc.free(self.gstin);
        if (self.email) |email| alloc.free(email);
        if (self.phone.len > 0) alloc.free(self.phone);
        if (self.remark) |remark| alloc.free(remark);

        self.address.deinit(alloc);

        self.* = Customer.init();
    }

    pub fn reset(self: *Customer, alloc: std.mem.Allocator) void {
        self.deinit(alloc);
    }

    pub fn getFieldValue(self: Customer, kind: form_field.FormField.Kind) []const u8 {
        return switch (kind) {
            .name => self.name,
            .gstin => self.gstin,
            .email => self.email orelse "",
            .phone => self.phone,
            .remark => self.remark orelse "",
            .shop_no => self.address.shop_no,
            .line_1 => self.address.line_1,
            .line_2 => self.address.line_2 orelse "",
            .line_3 => self.address.line_3 orelse "",
            .city => self.address.city,
            .state => self.address.state,
            .postal_code => self.address.postal_code,
        };
    }

    pub fn setCustomerField(
        self: *Customer,
        alloc: std.mem.Allocator,
        kind: form_field.FormField.Kind,
        value: []const u8,
    ) SetCustomerFieldError!void {
        switch (kind) {
            .name => {
                if (self.name.len > 0) alloc.free(self.name);
                self.name = try alloc.dupe(u8, value);
            },
            .gstin => {
                if (self.gstin.len > 0) alloc.free(self.gstin);
                self.gstin = try alloc.dupe(u8, value);
            },
            .email => {
                if (self.email) |email| alloc.free(email);
                self.email = if (value.len == 0) null else try alloc.dupe(u8, value);
            },
            .phone => {
                if (self.phone.len > 0) alloc.free(self.phone);
                self.phone = try alloc.dupe(u8, value);
            },
            .remark => {
                if (self.remark) |remark| alloc.free(remark);
                self.remark = if (value.len == 0) null else try alloc.dupe(u8, value);
            },
            .shop_no => {
                if (self.address.shop_no.len > 0) alloc.free(self.address.shop_no);
                self.address.shop_no = try alloc.dupe(u8, value);
            },
            .line_1 => {
                if (self.address.line_1.len > 0) alloc.free(self.address.line_1);
                self.address.line_1 = try alloc.dupe(u8, value);
            },
            .line_2 => {
                if (self.address.line_2) |old| alloc.free(old);
                self.address.line_2 = if (value.len == 0) null else try alloc.dupe(u8, value);
            },
            .line_3 => {
                if (self.address.line_3) |old| alloc.free(old);
                self.address.line_3 = if (value.len == 0) null else try alloc.dupe(u8, value);
            },
            .city => {
                if (self.address.city.len > 0) alloc.free(self.address.city);
                self.address.city = try alloc.dupe(u8, value);
            },
            .state => {
                if (self.address.state.len > 0) alloc.free(self.address.state);
                self.address.state = try alloc.dupe(u8, value);
            },
            .postal_code => {
                if (self.address.postal_code.len > 0) alloc.free(self.address.postal_code);
                self.address.postal_code = try alloc.dupe(u8, value);
            },
        }
    }
};

pub fn init(conn: *zqlite.Conn) Self {
    return Self{ .conn = conn };
}

pub fn insert(self: *Self, customer: util.Customer) !i64 {
    const query =
        \\insert into customers (
        \\    name, gstin, email, phone, remark,
        \\    shop_no, line_1, line_2, line_3,
        \\    city, state, postal_code
        \\) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ;

    // try conn.exec("insert into test (name) values (?1), (?2)", .{"Leto", "Ghanima"});

    try self.conn.exec(query, .{
        .name = customer.name,
        .gstin = customer.gstin,
        .email = customer.email,
        .phone = customer.phone,
        .remark = customer.remark,
        .shop_no = customer.address.shop_no,
        .line_1 = customer.address.line_1,
        .line_2 = customer.address.line_2,
        .line_3 = customer.address.line_3,
        .city = customer.address.city,
        .state = customer.address.state,
        .postal_code = customer.address.postal_code,
    });

    return self.conn.lastInsertedRowId();
}
