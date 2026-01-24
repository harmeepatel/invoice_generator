const std = @import("std");
const log = std.log.scoped(.ae_invoice);

pub const Self = @This();

const ProductDraft = struct {
    serial_number: ?[]const u8 = null,
    name: ?[]const u8 = null,
    hsn_code: ?[]const u8 = null,
    quantity: ?usize = null,
    sale_rate: ?f16 = null,
    discount: ?f16 = null,
};

const Product = struct {
    serial_number: []const u8,
    name: []const u8,
    hsn_code: []const u8,
    quantity: usize,
    sale_rate: f16,
    discount: f16,
};

const AddressDraft = struct {
    shop_no: ?[]const u8 = null,
    line_1: ?[]const u8 = null,
    line_2: ?[]const u8 = null,
    line_3: ?[]const u8 = null,
    state: ?[]const u8 = null,
    city: ?[]const u8 = null,
    postal_code: ?[]const u8 = null,
};

const Address = struct {
    shop_no: []const u8,
    line_1: []const u8,
    line_2: ?[]const u8,
    line_3: ?[]const u8,
    state: []const u8,
    city: []const u8,
    postal_code: []const u8,
};

const InvoiceDraft = struct {
    id: ?usize = null,
    created_at: ?i64 = null,
    name: ?[]const u8 = null,
    gstin: ?[]const u8 = null,
    gst: ?f16 = null,
    email: ?[]const u8 = null,
    phone: ?[]const u8 = null,
    remark: ?[]const u8 = null,
    address: ?AddressDraft = null,
    current_product: ProductDraft = .{},
};

const Invoice = struct {
    id: usize,
    created_at: i64,
    name: []const u8,
    gstin: []const u8,
    gst: f16,
    email: ?[]const u8,
    phone: []const u8,
    remark: ?[]const u8,
    address: Address,
    product_list: []Product,
};

arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,
draft: InvoiceDraft,
product_list: std.ArrayList(Product),

pub fn init(gpa: std.mem.Allocator) !Self {
    var self = Self{
        .draft = .{},
        .arena = std.heap.ArenaAllocator.init(gpa),
        .allocator = undefined,
        .product_list = undefined,
    };
    self.allocator = self.arena.allocator();
    self.product_list = try std.ArrayList(Product).initCapacity(self.allocator, 4);
    return self;
}

pub fn deinit(self: *Self) void {
    self.arena.deinit();
}
