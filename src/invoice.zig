const std = @import("std");

const Address = struct {
    shop_no: []const u8,
    line_1: []const u8,
    line_2: ?[]const u8 = null,
    line_3: ?[]const u8 = null,
    state: []const u8,
    city: []const u8,
    postal_code: []const u8,
};

pub const AddressBuilder = struct {
    shop_no: ?[]const u8 = null,
    line_1: ?[]const u8 = null,
    line_2: ?[]const u8 = null,
    line_3: ?[]const u8 = null,
    state: ?[]const u8 = null,
    city: ?[]const u8 = null,
    postal_code: ?[]const u8 = null,

    pub fn setShopNo(self: *AddressBuilder, shop_no: []const u8) void {
        self.shop_no = shop_no;
    }
    pub fn setLine1(self: *AddressBuilder, line_1: []const u8) void {
        self.line_1 = line_1;
    }
    pub fn setLine2(self: *AddressBuilder, line_2: []const u8) void {
        self.line_2 = line_2;
    }
    pub fn setLine3(self: *AddressBuilder, line_3: []const u8) void {
        self.line_3 = line_3;
    }
    pub fn setState(self: *AddressBuilder, state: []const u8) void {
        self.state = state;
    }
    pub fn setCity(self: *AddressBuilder, city: []const u8) void {
        self.city = city;
    }
    pub fn setPostalCode(self: *AddressBuilder, postal_code: []const u8) void {
        self.postal_code = postal_code;
    }

    pub fn flush(self: *AddressBuilder) AddressBuilder {
        self.shop_no = null;
        self.line_1 = null;
        self.line_2 = null;
        self.line_3 = null;
        self.state = null;
        self.city = null;
        self.postal_code = null;
    }

    pub fn build(self: AddressBuilder) Address {
        return Address{
            .shop_no = self.shop_no,
            .line_1 = self.line_1,
            .line_2 = if (self.line_2) |l2| l2 else null,
            .line_3 = if (self.line_3) |l3| l3 else null,
            .state = self.state,
            .city = self.city,
            .postal_code = self.postal_code,
        };
    }
};

const Item = struct {
    serial_number: []const u8,
    item_name: []const u8,
    hsn_code: []const u8,
    quantity: usize,
    sale_rate: f32,
    discount: f32,
};

pub const ItemBuilder = struct {
    serial_number: ?[]const u8 = null,
    item_name: ?[]const u8 = null,
    hsn_code: ?[]const u8 = null,
    quantity: ?usize = null,
    sale_rate: ?f32 = null,
    discount: f32 = 0.0,

    pub fn setSerialNumber(self: *ItemBuilder, serial_number: []const u8) void {
        self.serial_number = serial_number;
    }

    pub fn setItemName(self: *ItemBuilder, item_name: []const u8) void {
        self.item_name = item_name;
    }

    pub fn setHSNCode(self: *ItemBuilder, hsn_code: []const u8) void {
        self.hsn_code = hsn_code;
    }

    pub fn setQuantity(self: *ItemBuilder, quantity: usize) void {
        self.quantity = quantity;
    }

    pub fn setSaleRate(self: *ItemBuilder, sale_rate: f32) void {
        self.sale_rate = sale_rate;
    }

    pub fn setDiscount(self: *ItemBuilder, discount: f32) void {
        self.discount = discount;
    }

    pub fn flush(self: *ItemBuilder) ItemBuilder {
        self.serial_number = null;
        self.item_name = null;
        self.hsn_code = null;
        self.quantity = null;
        self.sale_rate = null;
        self.discount = 0.0;
    }

    pub fn build(self: ItemBuilder) Item {
        return Item{
            .serial_number = self.serial_number,
            .item_name = self.item_name,
            .hsn_code = self.hsn_code,
            .quantity = self.quantity,
            .sale_rate = self.sale_rate,
            .discount = self.discount,
        };
    }
};

const Invoice = struct {
    id: usize,
    created_at: i64,
    name: []const u8,
    gstin: []const u8,
    gst: f32,
    email: ?[]const u8,
    phone: []const u8,
    remark: ?[]const u8,
    address: Address,
    items: []Item,
};

pub const InvoiceBuilder = struct {
    allocator: std.mem.Allocator,

    name: ?[]const u8 = null,
    gstin: ?[]const u8 = null,
    gst: ?f32 = null,
    email: ?[]const u8 = null,
    phone: ?[]const u8 = null,
    remark: ?[]const u8 = null,
    address: ?Address = null,
    address_builder: AddressBuilder,

    item_builder: ItemBuilder,
    items: std.ArrayList(Item),

    pub fn init(allocator: std.mem.Allocator) !InvoiceBuilder {
        return .{
            .allocator = allocator,
            .items = try std.ArrayList(Item).initCapacity(allocator, 8),
            .address_builder = AddressBuilder{},
            .item_builder = ItemBuilder{},
        };
    }

    pub fn deinit(self: *InvoiceBuilder) void {
        self.items.deinit(self.allocator);
    }

    pub fn setName(self: *InvoiceBuilder, name: []const u8) void {
        self.name = name;
    }

    pub fn setGSTIN(self: *InvoiceBuilder, gstin: []const u8) void {
        self.gstin = gstin;
    }

    pub fn setGST(self: *InvoiceBuilder, gst: f32) void {
        self.gst = gst;
    }

    pub fn setPhone(self: *InvoiceBuilder, phone: []const u8) void {
        self.phone = phone;
    }

    pub fn addItem(self: *InvoiceBuilder) !void {
        try self.items.append(self.item_builder.build());
    }

    pub fn removeItem(self: *InvoiceBuilder, index: usize) void {
        _ = self.items.swapRemove(index);
    }

    pub fn flush(self: *InvoiceBuilder) InvoiceBuilder {
        self.name = null;
        self.gstin = null;
        self.gst = null;
        self.email = null;
        self.phone = null;
        self.remark = null;
        self.address = null;
        self.address_builder = self.address_builder.flush();
        self.item_builder = self.item_builder.flush();
        self.items = self.items.clearRetainingCapacity();
    }

    pub fn build(self: *InvoiceBuilder, id: usize) Invoice {
        return Invoice{
            .id = id,
            .created_at = std.time.timestamp(),
            .name = self.name.?,
            .gstin = self.gstin.?,
            .email = self.email,
            .phone = self.phone.?,
            .remark = self.remark,
            .address = self.address_builder.build(),
            .items = try self.items.toOwnedSlice(),
        };
    }
};
