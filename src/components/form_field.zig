const std = @import("std");
const dvui = @import("dvui");

const main = @import("../main.zig");
const util = @import("../util.zig");
const customers = @import("../db/customers.zig");
const validate = @import("../validate_form.zig");

const log = std.log.scoped(.ae_form_field);

var text_entry_opts = util.FieldOptions.text_entry;

pub var all = [_]FormField{
    .{ .kind = .name, .label = "Name", .placeholder = "Hritik Roshan" },
    .{ .kind = .gstin, .label = "GSTIN", .placeholder = "24ABCDE1234F1Z5" },
    .{ .kind = .email, .label = "Email (Optional)", .placeholder = "abc@xyz.com (Optional)" },
    .{ .kind = .phone, .label = "Phone", .placeholder = "+91 11111 99999" },
    .{ .kind = .remark, .label = "Remark (Optional)", .placeholder = "Transporter Name / Other Note (Optional)" },
    // address
    .{ .kind = .shop_no, .label = "Shop Number", .placeholder = "AB 404" },
    .{ .kind = .line_1, .label = "Address Line 1", .placeholder = "Complex / Plaza" },
    .{ .kind = .line_2, .label = "Address Line 2 (Optional)", .placeholder = "Landmark (Optional)" },
    .{ .kind = .line_3, .label = "Address Line 3 (Optional)", .placeholder = "Street Name (Optional)" },
    .{ .kind = .state, .label = "State", .placeholder = "Gujarat" },
    .{ .kind = .city, .label = "City", .placeholder = "Ahmedabad" },
    .{ .kind = .postal_code, .label = "Postal Code", .placeholder = "123123" },
};

pub const FormField = struct {
    kind: Kind,
    label: []const u8,
    err_msg: []const u8 = "",
    placeholder: []const u8 = "",

    pub const Kind = enum {
        name,
        gstin,
        email,
        phone,
        remark,
        shop_no,
        line_1,
        line_2,
        line_3,
        city,
        state,
        postal_code,
    };

    pub fn render(field: *FormField, key: usize, customer: *customers.Customer) void {
        var v_stack = dvui.box(
            @src(),
            .{ .dir = .vertical },
            .{ .id_extra = key, .expand = .both },
        );
        defer v_stack.deinit();

        {
            var h_stack = dvui.box(
                @src(),
                .{ .dir = .horizontal },
                .{
                    .id_extra = key,
                    .expand = .both,
                },
            );
            defer h_stack.deinit();

            dvui.labelNoFmt(@src(), field.label, .{}, util.FieldOptions.label);
            dvui.labelNoFmt(@src(), field.err_msg, .{}, util.FieldOptions.err_label);
        }

        switch (field.kind) {
            .state => {
                {
                    var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{ .expand = .both });
                    defer hbox.deinit();

                    const combo = dvui.comboBox(@src(), .{}, text_entry_opts);
                    defer combo.deinit();

                    // filter suggestions to match the start of the entry
                    if (combo.te.text_changed) blk: {
                        var filtered = std.ArrayListUnmanaged([]const u8).initCapacity(main.gpa, util.PostalCodes.count) catch {
                            dvui.dataRemove(null, combo.te.data().id, "suggestions");
                            break :blk;
                        };
                        defer filtered.deinit(main.gpa);

                        for (util.PostalCodes.states) |state| {
                            var lower_buf: [64]u8 = undefined;
                            var lower_filter: [64]u8 = undefined;
                            const s = std.ascii.lowerString(&lower_buf, state);
                            const filter_text = std.ascii.lowerString(&lower_filter, combo.te.getText());

                            if (std.mem.startsWith(u8, s, filter_text)) {
                                filtered.appendAssumeCapacity(state);
                            }
                        }
                        dvui.dataSetSlice(null, combo.te.data().id, "suggestions", filtered.items);

                        field.validateAndUpdate(combo.te, customer);
                    }

                    if (combo.entries(dvui.dataGetSlice(null, combo.te.data().id, "suggestions", [][]const u8) orelse &util.PostalCodes.states)) |_| {
                        field.validateAndUpdate(combo.te, customer);
                    }
                }
            },
            else => {
                if (field.err_msg.len > 0) {
                    text_entry_opts.color_fill = util.Color.err.get();
                } else {
                    text_entry_opts.color_fill = util.Color.layer1.get();
                }

                var te = dvui.textEntry(@src(), .{ .placeholder = field.placeholder }, text_entry_opts);
                defer te.deinit();

                if (main.should_reset_form) {
                    te.textSet("", false);
                    field.err_msg = "";
                }

                // store postal_code even if it's incorrect incase user changes state field after pincode
                switch (field.kind) {
                    .postal_code => {
                        customer.setCustomerField(main.gpa, field.kind, te.getText()) catch |err| {
                            log.err("Error setting customer field {any} with \n {any}", .{ field.kind, err });
                        };
                        if (te.text_changed) {
                            field.validateAndUpdate(te, customer);
                        }
                    },
                    else => {
                        if (te.text_changed) {
                            field.validateAndUpdate(te, customer);
                        }
                    },
                }
            },
        }
    }

    pub fn validateAndUpdate(
        self: *FormField,
        text_entry_widget: *dvui.TextEntryWidget,
        customer: *customers.Customer,
    ) void {
        const result = validate.validate(self.kind, text_entry_widget.getText(), customer.*);

        if (result.err_msg) |err| {
            self.err_msg = err;
        } else {
            self.err_msg = "";
            customer.setCustomerField(main.gpa, self.kind, text_entry_widget.getText()) catch |err| {
                log.err("Error setting customer field {any} with \n {any}", .{ self.kind, err });
            };

            // Revalidate dependent fields
            for (result.revalidate_fields) |revalidate_kind| {
                for (&all) |*other_field| {
                    if (other_field.kind == revalidate_kind) {
                        const current_value = customer.getFieldValue(revalidate_kind);
                        const revalidation_result = validate.validate(
                            revalidate_kind,
                            current_value,
                            customer.*,
                        );

                        if (revalidation_result.err_msg) |revalidate_err| {
                            other_field.err_msg = revalidate_err;
                        } else {
                            other_field.err_msg = "";
                        }
                        break;
                    }
                }
            }
        }
    }
};
