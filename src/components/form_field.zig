const std = @import("std");
const dvui = @import("dvui");

const main = @import("../main.zig");
const util = @import("../util.zig");
const customers = @import("../db/customers.zig");
const validate = @import("../validate.zig");

const log = std.log.scoped(.component_form_field);

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
    multiline: bool = false,
    placeholder: []const u8 = "",

    label_options: dvui.Options = .{
        .padding = dvui.Rect.all(0),
        .font = util.font(util.text.sm, "Cascadia_Mono_Light"),
    },
    err_label_options: dvui.Options = .{
        .padding = dvui.Rect.all(0),
        .font = util.font(util.text.sm, "Cascadia_Mono_Light"),
        .color_text = dvui.Color.fromHex("#ED4A4A"),
        .gravity_x = 1.0,
    },
    text_entry_options: dvui.Options = .{
        .expand = .horizontal,
        .margin = dvui.Rect{ .h = util.gap.xl },
        .padding = dvui.Rect.all(util.gap.sm),
        .font = util.font(util.text.sm, "Cascadia_Mono_Light"),
        .min_size_content = .{ .h = util.text.sm },
    },

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
                    .margin = dvui.Rect{ .h = util.gap.md },
                },
            );
            defer h_stack.deinit();

            dvui.labelNoFmt(@src(), field.label, .{}, field.label_options);
            dvui.labelNoFmt(@src(), field.err_msg, .{}, field.err_label_options);
        }

        switch (field.kind) {
            .state => {
                {
                    var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{ .expand = .both });
                    defer hbox.deinit();

                    const combo = dvui.comboBox(@src(), .{}, field.text_entry_options);
                    defer combo.deinit();
                    // filter suggestions to match the start of the entry
                    if (combo.te.text_changed) blk: {
                        const arena = dvui.currentWindow().lifo();
                        var filtered = std.ArrayListUnmanaged([]const u8).initCapacity(arena, util.PostalCodes.count) catch {
                            dvui.dataRemove(null, combo.te.data().id, "suggestions");
                            break :blk;
                        };
                        defer filtered.deinit(arena);

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

                        // validateFormField(field, combo.te, customer);
                        field.validateAndUpdate(combo.te, customer);
                    }

                    if (combo.entries(dvui.dataGetSlice(null, combo.te.data().id, "suggestions", [][]const u8) orelse &util.PostalCodes.states)) |_| {
                        // validateFormField(field, combo.te, customer);
                        field.validateAndUpdate(combo.te, customer);
                    }
                }
            },
            else => {
                const text_init_options: dvui.TextEntryWidget.InitOptions = .{
                    .placeholder = field.placeholder,
                    .multiline = field.multiline,
                };

                if (field.multiline) {
                    field.text_entry_options.min_size_content = .{ .h = field.text_entry_options.font.?.size * util.scale_h.x6 };
                }

                if (field.err_msg.len > 0) {
                    field.text_entry_options.color_border = dvui.Color.fromHex("#ed4a4aff");
                } else {
                    field.text_entry_options.color_border = dvui.Color.fromHex("#4b4b4bff");
                }

                var te = dvui.textEntry(@src(), text_init_options, field.text_entry_options);
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
