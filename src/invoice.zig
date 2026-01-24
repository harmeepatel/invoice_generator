const std = @import("std");
const dvui = @import("dvui");
const util = @import("util.zig");

const log = std.log.scoped(.ae_invoice);

const KeyGen = util.KeyGen;
pub const ErrorMessage = ?[]const u8;

var err_buf: [128]u8 = undefined;

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

    // Key for the postal code field to trigger error updates
    postal_code_field_key: ?usize = null,

    pub fn setShopNo(self: *AddressBuilder, shop_no: []const u8) ErrorMessage {
        if (shop_no.len == 0) return "Required";
        if (shop_no.len > 100) return "Too Long [ < 100 ]";
        self.shop_no = shop_no;
        return null;
    }

    pub fn setLine1(self: *AddressBuilder, line_1: []const u8) ErrorMessage {
        if (line_1.len == 0) return "Required";
        if (line_1.len > 100) return "Too Long [ < 100 ]";
        self.line_1 = line_1;
        return null;
    }

    pub fn setLine2(self: *AddressBuilder, line_2: []const u8) ErrorMessage {
        if (line_2.len > 100) return "Too Long [ < 100 ]";
        self.line_2 = if (line_2.len > 0) line_2 else null;
        return null;
    }

    pub fn setLine3(self: *AddressBuilder, line_3: []const u8) ErrorMessage {
        if (line_3.len > 100) return "Too Long [ < 100 ]";
        self.line_3 = if (line_3.len > 0) line_3 else null;
        return null;
    }

    pub fn setState(self: *AddressBuilder, state: []const u8) ErrorMessage {
        var state_buf: [64]u8 = undefined;
        var str_buf: [64]u8 = undefined;

        if (state.len == 0) return "Required";

        // Validate against Indian states
        var found = false;
        for (util.PostalCodes.states) |valid_state| {
            const valid_state_lower = std.ascii.lowerString(&state_buf, valid_state);
            const state_lower = std.ascii.lowerString(&str_buf, state);

            if (std.mem.eql(u8, valid_state_lower, state_lower)) {
                found = true;
                break;
            }
        }

        if (!found) return "Invalid";

        const old_state = self.state;
        self.state = state;

        // Trigger postal code revalidation if state changed
        if (old_state != null and !std.mem.eql(u8, old_state.?, state)) {
            self.revalidatePostalCode();
        }

        return null;
    }

    pub fn setCity(self: *AddressBuilder, city: []const u8) ErrorMessage {
        if (city.len == 0) return "Required";
        if (city.len > 50) return "Too Long [ < 50 ]";
        self.city = city;
        return null;
    }

    pub fn setPostalCode(self: *AddressBuilder, postal_code: []const u8) ErrorMessage {
        if (postal_code.len != 6) return "Invalid";

        const code = std.fmt.parseInt(u32, postal_code, 10) catch return "Invalid";

        // If state is set, validate against state's postal code range
        if (self.state) |state| {
            var state_idx: ?usize = null;
            for (util.PostalCodes.states, 0..) |valid_state, idx| {
                if (std.mem.eql(u8, state, valid_state)) {
                    state_idx = idx;
                    break;
                }
            }

            if (state_idx) |idx| {
                const min = util.PostalCodes.min_codes[idx];
                const max = util.PostalCodes.max_codes[idx];

                if (code < min or code > max) {
                    const err_msg = std.fmt.bufPrint(&err_buf, "Out of Range [ {d} - {d} ]", .{ min, max }) catch {
                        @panic("Trouble Formating");
                    };
                    return err_buf[0..err_msg.len];
                }
            }
        }

        self.postal_code = postal_code;
        return null;
    }

    /// Revalidate postal code against current state
    /// Used when state changes to check if existing postal code is still valid
    pub fn revalidatePostalCode(self: *AddressBuilder) void {
        if (self.postal_code) |pc| {
            if (self.setPostalCode(pc)) |err| {
                if (self.postal_code_field_key) |key| {
                    const main = @import("main.zig");
                    main.error_queue.put(key, err) catch {};
                }
            }
        }
    }

    /// Set the field key for postal code field to enable cross-field error reporting
    pub fn setPostalCodeFieldKey(self: *AddressBuilder, key: usize) void {
        self.postal_code_field_key = key;
    }

    pub fn flush(self: *AddressBuilder) void {
        self.shop_no = null;
        self.line_1 = null;
        self.line_2 = null;
        self.line_3 = null;
        self.state = null;
        self.city = null;
        self.postal_code = null;
        // Keep postal_code_field_key as it's persistent across form resets
    }

    pub fn build(self: AddressBuilder) Address {
        return Address{
            .shop_no = self.shop_no.?,
            .line_1 = self.line_1.?,
            .line_2 = self.line_2,
            .line_3 = self.line_3,
            .state = self.state.?,
            .city = self.city.?,
            .postal_code = self.postal_code.?,
        };
    }
};

const Item = struct {
    serial_number: []const u8,
    item_name: []const u8,
    hsn_code: []const u8,
    quantity: usize,
    sale_rate: f16,
    discount: f16,

    pub fn row(self: Item, keygen: *KeyGen, want_label: bool) void {
        const Field = @import("Field.zig");
        var all = [_]Field{
            .{ .kind = .serial_number, .label = "Serial Number", .placeholder = "000000000" },
            .{ .kind = .item_name, .label = "Item Name", .placeholder = "Bibcock" },
            .{ .kind = .hsn_code, .label = "HSN Code", .placeholder = "000000" },
            .{ .kind = .quantity, .label = "Quantity(Q)", .placeholder = "0" },
            .{ .kind = .sale_rate, .label = "Sale Rate(SR)", .placeholder = "00.00" }, // TODO: make a db and add products to automatically find prices
            .{ .kind = .discount, .label = "Discount %", .placeholder = "00.00" },
        };

        var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{
            .id_extra = keygen.emit(),
            .expand = .both,
            .margin = .{ .h = util.gap.xs },
        });
        defer hbox.deinit();

        inline for (&all, 0..) |*field, idx| {
            const k = keygen.emit();

            if (!want_label) {
                field.label = null;
            }

            var buf: [16]u8 = undefined;
            field.field_text = switch (field.kind) {
                .serial_number => self.serial_number,
                .item_name => self.item_name,
                .hsn_code => self.hsn_code,
                .quantity => blk: {
                    const tmp = std.fmt.bufPrint(&buf, "{}", .{self.quantity}) catch "";
                    break :blk tmp;
                },
                .sale_rate => blk: {
                    const tmp = std.fmt.bufPrint(&buf, "{}", .{self.sale_rate}) catch "";
                    break :blk tmp;
                },
                .discount => blk: {
                    const tmp = std.fmt.bufPrint(&buf, "{}", .{self.discount}) catch "";
                    break :blk tmp;
                },
                else => unreachable,
            };

            field.label_opts.font = util.Font.light.sm();
            field.text_entry_opts.id_extra = keygen.emit();
            field.main_container_opts.margin = .{ .h = 0, .w = if (idx == all.len - 1) 0 else util.gap.xs };

            field.render(k);
        }
    }
};

pub const ItemBuilder = struct {
    serial_number: ?[]const u8 = null,
    item_name: ?[]const u8 = null,
    hsn_code: ?[]const u8 = null,
    quantity: ?usize = null,
    sale_rate: ?f16 = null,
    discount: f16 = 0.0,

    pub fn row(keygen: *KeyGen, want_label: bool) void {
        const Field = @import("Field.zig");
        var all = [_]Field{
            .{ .kind = .serial_number, .label = "Serial Number", .placeholder = "000000000" },
            .{ .kind = .item_name, .label = "Item Name", .placeholder = "Bibcock" },
            .{ .kind = .hsn_code, .label = "HSN Code", .placeholder = "000000" },
            .{ .kind = .quantity, .label = "Quantity(Q)", .placeholder = "0" },
            .{ .kind = .sale_rate, .label = "Sale Rate(SR)", .placeholder = "00.00" }, // TODO: make a db and add products to automatically find prices
            .{ .kind = .discount, .label = "Discount %", .placeholder = "00.00" },
        };

        var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{
            .id_extra = keygen.emit(),
            .expand = .both,
            .margin = .{ .h = util.gap.xs },
        });
        defer hbox.deinit();

        inline for (&all, 0..) |*field, idx| {
            const k = keygen.emit();

            if (!want_label) {
                field.label = null;
            }

            field.label_opts.font = util.Font.light.sm();
            field.text_entry_opts.id_extra = keygen.emit();
            field.main_container_opts.margin = .{ .h = 0, .w = if (idx == all.len - 1) 0 else util.gap.xs };

            field.render(k);
        }
    }

    pub fn setSerialNumber(self: *ItemBuilder, serial_number: []const u8) ErrorMessage {
        if (serial_number.len == 0) return "Required";
        if (serial_number.len > 50) return "Too Long [ < 50 ]";
        self.serial_number = serial_number;
        return null;
    }

    pub fn setItemName(self: *ItemBuilder, item_name: []const u8) ErrorMessage {
        if (item_name.len == 0) return "Required";
        if (item_name.len > 200) return "Too Long [ < 200 ]";
        self.item_name = item_name;
        return null;
    }

    pub fn setHSNCode(self: *ItemBuilder, hsn_code: []const u8) ErrorMessage {
        // HSN code should be 4, 6, or 8 digits
        if (hsn_code.len != 4 and hsn_code.len != 6 and hsn_code.len != 8) {
            return "Invalid"; // Reusing error type
        }

        // Must be all digits
        for (hsn_code) |c| {
            if (c < '0' or c > '9') return "Invalid";
        }

        self.hsn_code = hsn_code;
        return null;
    }

    pub fn setQuantity(self: *ItemBuilder, quantity: []const u8) ErrorMessage {
        const pq = std.fmt.parseInt(usize, quantity, 10) catch {
            return "Invalid";
        };
        if (pq == 0) return "Must be atleast 1";
        self.quantity = pq;
        return null;
    }

    pub fn setSaleRate(self: *ItemBuilder, sale_rate: []const u8) ErrorMessage {
        const psr = std.fmt.parseFloat(f16, sale_rate) catch {
            return "Invalid rate format";
        };
        if (psr <= 0.0) return "Must be > 0.0";
        self.sale_rate = psr;
        return null;
    }

    pub fn setDiscount(self: *ItemBuilder, discount: []const u8) ErrorMessage {
        const pd = std.fmt.parseFloat(f16, discount) catch {
            return "Invalid discount format";
        };
        if (pd < 0.0 or pd > 100.0) return "Invalid";
        self.discount = pd;
        return null;
    }

    pub fn flush(self: *ItemBuilder) void {
        self.serial_number = null;
        self.item_name = null;
        self.hsn_code = null;
        self.quantity = null;
        self.sale_rate = null;
        self.discount = 0.0;
        log.debug("flush: {any}", .{self});
    }

    pub fn build(self: *ItemBuilder, allocator: std.mem.Allocator) Item {
        return Item{
            .serial_number = allocator.dupe(u8, self.serial_number.?) catch {
                @panic("Failed to duplicate ItemBuilder.serial_number");
            },
            .item_name = allocator.dupe(u8, self.item_name.?) catch {
                @panic("Failed to duplicate ItemBuilder.serial_number");
            },
            .hsn_code = allocator.dupe(u8, self.hsn_code.?) catch {
                @panic("Failed to duplicate ItemBuilder.serial_number");
            },
            .quantity = self.quantity.?,
            .sale_rate = self.sale_rate.?,
            .discount = self.discount,
        };
    }
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
    items: []Item,
};

pub const InvoiceBuilder = struct {
    allocator: std.mem.Allocator,

    name: ?[]const u8 = null,
    gstin: ?[]const u8 = null,
    gst: ?f16 = null,
    email: ?[]const u8 = null,
    phone: ?[]const u8 = null,
    remark: ?[]const u8 = null,
    address: ?Address = null,
    address_builder: AddressBuilder,

    item_builder: ItemBuilder,
    item_list: std.ArrayList(Item),

    pub fn init(allocator: std.mem.Allocator) !InvoiceBuilder {
        return .{
            .allocator = allocator,
            .item_list = try std.ArrayList(Item).initCapacity(allocator, 8),
            .address_builder = AddressBuilder{},
            .item_builder = ItemBuilder{},
        };
    }

    pub fn deinit(self: *InvoiceBuilder) void {
        if (self.item_builder.serial_number) |sn| {
            self.allocator.free(sn);
        }
        if (self.item_builder.item_name) |in| {
            self.allocator.free(in);
        }
        if (self.item_builder.hsn_code) |hsn| {
            self.allocator.free(hsn);
        }

        self.item_list.deinit(self.allocator);
    }

    pub fn setName(self: *InvoiceBuilder, name: []const u8) ErrorMessage {
        if (name.len == 0) return "Required";
        if (name.len > 100) return "Too Long [ < 100 ]";
        self.name = name;
        return null;
    }

    /// Validates GSTIN format: 15 characters
    /// Format: 2 digits (state code) + 10 characters (PAN) + 1 digit (entity number) + Z + 1 check digit
    /// Example: 27AAPFU0939F1ZV
    pub fn setGSTIN(self: *InvoiceBuilder, gstin: []const u8) ErrorMessage {
        if (gstin.len != 15) return "Invalid Length";

        for (gstin[0..2], 0..) |c, idx| {
            if (c < '0' or c > '9') return std.fmt.bufPrint(&err_buf, "Invalid Character: {d}", .{idx + 1}) catch {
                @panic("Trouble Formating");
            };
        }

        // Next 10 characters should be alphanumeric (PAN format)
        // First 5 are letters, next 4 are digits, last is a letter
        {
            for (gstin[2..7], 0..) |c, idx| {
                if (!std.ascii.isAlphabetic(c)) return std.fmt.bufPrint(&err_buf, "Invalid Character: {d}", .{idx + 1}) catch {
                    @panic("Trouble Formating");
                };
            }

            for (gstin[7..11], 0..) |c, idx| {
                if (c < '0' or c > '9') return std.fmt.bufPrint(&err_buf, "Invalid Character: {d}", .{idx + 1}) catch {
                    @panic("Trouble Formating");
                };
            }

            if (!std.ascii.isAlphabetic(gstin[11])) return "Invalid Character: 12";
        }

        // 13th character should be a digit (entity number: 1-9, A-Z)
        const entity_char = gstin[12];
        if (!((entity_char >= '1' and entity_char <= '9') or std.ascii.isAlphabetic(entity_char))) {
            return "Invalid Character: 13";
        }

        // 14th character should be 'Z'
        if (gstin[13] != 'Z') return "Invalid Character: 14";

        // 15th character should be alphanumeric (check digit)
        if (!std.ascii.isAlphanumeric(gstin[14])) return "Invalid Character: 15";

        self.gstin = gstin;
        return null;
    }

    pub fn setGST(self: *InvoiceBuilder, gst: []const u8) ErrorMessage {
        const pg = std.fmt.parseFloat(f16, gst) catch {
            return "Invalid GST format";
        };

        const valid_rates = [_]f16{ 0.0, 5.0, 12.0, 18.0, 28.0 };
        var is_valid = false;

        for (valid_rates) |rate| {
            if (@abs(pg - rate) < 0.01) {
                is_valid = true;
                break;
            }
        }

        if (!is_valid) return "Must be one of: 0.0, 5.0, 12.0, 18.0, 28.0";
        self.gst = pg;
        return null;
    }

    pub fn setEmail(self: *InvoiceBuilder, email: []const u8) ErrorMessage {
        if (email.len == 0) {
            self.email = null;
            return "";
        }

        if (email.len > 100) return "Too Long [ < 100 ]";

        // Basic email validation
        var has_at = false;
        var has_dot_after_at = false;
        var at_pos: usize = 0;

        for (email, 0..) |c, i| {
            if (c == '@') {
                if (has_at) return "Invalid Multiple `@`"; // Multiple @
                has_at = true;
                at_pos = i;
                if (i == 0 or i == email.len - 1) return "Invalid Position `@`";
            }
            if (has_at and c == '.' and i > at_pos + 1) {
                has_dot_after_at = true;
            }
        }

        if (!has_at or !has_dot_after_at) return "Invalid";
        if (email[email.len - 1] == '.') return "Invalid Position `.`";

        self.email = email;
        return null;
    }

    /// Validates Indian phone numbers: 10 digits
    pub fn setPhone(self: *InvoiceBuilder, phone: []const u8) ErrorMessage {
        if (phone.len != 10) return "Invalid";

        // Must be all digits
        for (phone) |c| {
            if (c < '0' or c > '9') return "Must be Numbers";
        }

        // First digit should be 6-9 (valid Indian mobile numbers)
        const first_digit = phone[0];
        if (first_digit < '6' or first_digit > '9') return "Should Start with 6 or 9";

        self.phone = phone;
        return null;
    }

    pub fn setRemark(self: *InvoiceBuilder, remark: []const u8) ErrorMessage {
        if (remark.len > 500) return "Too Long [ < 500 ]";
        self.remark = if (remark.len > 0) remark else null;
        return null;
    }

    pub fn addItem(self: *InvoiceBuilder) !void {
        if (self.item_builder.serial_number == null or
            self.item_builder.item_name == null or
            self.item_builder.hsn_code == null or
            self.item_builder.quantity == null or
            self.item_builder.sale_rate == null)
        {
            return error.IncompleteItem;
        }

        try self.item_list.append(self.allocator, self.item_builder.build(self.allocator));
        self.item_builder.flush();
    }

    pub fn removeItem(self: *InvoiceBuilder, index: usize) void {
        _ = self.item_list.swapRemove(index);
    }

    pub fn flush(self: *InvoiceBuilder) void {
        self.name = null;
        self.gstin = null;
        self.gst = null;
        self.email = null;
        self.phone = null;
        self.remark = null;
        self.address = null;
        self.address_builder.flush();
        self.item_builder.flush();
        self.item_list.clearRetainingCapacity();
    }

    pub fn build(self: *InvoiceBuilder, id: usize) !Invoice {
        return Invoice{
            .id = id,
            .created_at = std.time.timestamp(),
            .name = self.name.?,
            .gstin = self.gstin.?,
            .gst = self.gst.?,
            .email = self.email,
            .phone = self.phone.?,
            .remark = self.remark,
            .address = self.address_builder.build(),
            .items = try self.item_list.toOwnedSlice(),
        };
    }
};
