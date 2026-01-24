const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const util = @import("util.zig");
const main = @import("main.zig");
const invoice = @import("invoice.zig");

const log = std.log.scoped(.ae_component_field);

const Self = @This();

pub const Variant = enum {
    default,
    selection_box,
};

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
    state,
    city,
    postal_code,
    serial_number,
    item_name,
    hsn_code,
    quantity,
    sale_rate,
    discount,
    gst,
};

kind: Kind,
key: usize = 0,
variant: Variant = .default,
label: ?[]const u8 = null,
placeholder: ?[]const u8 = null,
field_text: ?[]const u8 = null,
suggestions: ?[]const []const u8 = null,

main_container_opts: dvui.Options = .{
    .expand = .both,
    .margin = .{ .h = util.gap.lg },
},
label_opts: dvui.Options = .{
    .padding = dvui.Rect.all(0),
    .font = util.Font.light.md(),
},
err_label_opts: dvui.Options = .{
    .padding = dvui.Rect.all(0),
    .font = util.Font.light.sm(),
    .color_text = util.Color.err.get(),
    .gravity_x = 1.0,
},
text_entry_opts: dvui.Options = .{
    .expand = .horizontal,
    .margin = dvui.Rect.all(0),
    .padding = dvui.Rect.all(util.gap.sm),
    .color_border = util.Color.border.get(),
    .font = util.Font.light.sm(),
    .corner_radius = dvui.Rect.all(util.gap.xs),
    .min_size_content = .{ .h = util.text.sm },
},

pub fn init(typ: Kind) Self {
    return Self{ .kind = typ };
}

pub fn render(self: *Self, key: usize) void {
    self.key = key;

    self.main_container_opts.id_extra = self.key;

    var vbox = dvui.box(@src(), .{ .dir = .vertical }, self.main_container_opts);
    defer vbox.deinit();

    if (builtin.mode == .Debug) {
        dvui.label(@src(), "{d}", .{self.key}, .{
            .font = util.Font.extra_light.xs(),
            .color_text = util.Color.debug.get(),
            .padding = dvui.Rect.all(0),
        });
    }

    // label / error
    {
        var hbox = dvui.box(
            @src(),
            .{ .dir = .horizontal },
            .{
                .expand = .both,
            },
        );
        defer hbox.deinit();

        if (self.label) |label| dvui.labelNoFmt(@src(), label, .{}, self.label_opts);

        if (main.error_queue.get(self.key)) |err_msg| {
            dvui.labelNoFmt(@src(), err_msg, .{}, self.err_label_opts);
        }
    }

    // space
    {
        const spacer = dvui.box(@src(), .{}, .{ .min_size_content = .{ .h = util.gap.xs } });
        spacer.deinit();
    }

    // text-entry
    switch (self.variant) {
        .default => {
            if (main.error_queue.contains(self.key)) {
                self.text_entry_opts.color_border = util.Color.err.get();
            } else {
                self.text_entry_opts.color_border = util.Color.border.get();
            }

            var te = dvui.textEntry(@src(), .{ .placeholder = if (self.placeholder) |ph| ph else "" }, self.text_entry_opts);
            defer te.deinit();

            // for invoice-items that already have values entered.
            if (self.field_text) |text| {
                te.textSet(text, false);
            }

            if (main.should_reset_form) {
                te.textSet("", false);
            }

            if (te.text_changed) {
                _ = main.error_queue.swapRemove(self.key);

                const value = te.getText();

                switch (self.kind) {
                    .name => {
                        if (main.invoice.setName(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .gstin => {
                        if (main.invoice.setGSTIN(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .gst => {
                        if (main.invoice.setGST(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .email => {
                        if (main.invoice.setEmail(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .phone => {
                        if (main.invoice.setPhone(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .state => {
                        if (main.invoice.address_builder.setState(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .postal_code => {
                        // Register this field's key for cross-field validation
                        main.invoice.address_builder.setPostalCodeFieldKey(self.key);
                        if (main.invoice.address_builder.setPostalCode(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .city => {
                        if (main.invoice.address_builder.setCity(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .shop_no => {
                        if (main.invoice.address_builder.setShopNo(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .line_1 => {
                        if (main.invoice.address_builder.setLine1(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .line_2 => {
                        if (main.invoice.address_builder.setLine2(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .line_3 => {
                        if (main.invoice.address_builder.setLine3(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .serial_number => {
                        if (main.invoice.item_builder.setSerialNumber(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .item_name => {
                        if (main.invoice.item_builder.setItemName(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .hsn_code => {
                        if (main.invoice.item_builder.setHSNCode(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .quantity => {
                        if (main.invoice.item_builder.setQuantity(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .sale_rate => {
                        if (main.invoice.item_builder.setSaleRate(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .discount => {
                        if (main.invoice.item_builder.setDiscount(value)) |err| {
                            self.setError(err);
                        }
                    },
                    .remark => {
                        if (main.invoice.setRemark(value)) |err| {
                            self.setError(err);
                        }
                    },
                }
            }
        },

        .selection_box => {
            std.debug.assert(self.suggestions != null);
            const suggestion_list = self.suggestions.?;

            var te = dvui.widgetAlloc(dvui.TextEntryWidget);
            defer te.deinit();

            te.* = dvui.TextEntryWidget.init(@src(), .{ .placeholder = if (self.placeholder) |ph| ph else "" }, self.text_entry_opts);
            te.data().was_allocated_on_widget_stack = true;
            te.install();

            var sug = dvui.suggestion(te, .{
                .button = false,
                .open_on_focus = false,
                .open_on_text_change = true,
                .label = .{ .text = te.getText() },
            });
            defer sug.deinit();

            te.draw();

            if (te.text_changed) blk: {
                _ = main.error_queue.swapRemove(self.key);

                var filtered = std.ArrayListUnmanaged([]const u8).initCapacity(main.gpa, suggestion_list.len) catch {
                    dvui.dataRemove(null, te.data().id, "suggestions");
                    break :blk;
                };
                defer filtered.deinit(main.gpa);

                if (te.getText().len == 0) {
                    return;
                }

                var lower_buf: [64]u8 = undefined;
                var lower_filter: [64]u8 = undefined;

                for (suggestion_list) |sug_item| {
                    const state_lower = std.ascii.lowerString(&lower_buf, sug_item);
                    const filter_text = std.ascii.lowerString(&lower_filter, te.getText());

                    if (std.mem.containsAtLeast(u8, state_lower, 1, filter_text)) {
                        filtered.appendAssumeCapacity(sug_item);
                    }
                }
                dvui.dataSetSlice(null, te.data().id, "suggestions", filtered.items);

                if (main.invoice.address_builder.setState(te.getText())) |err| {
                    self.setError(err);
                }
            }

            if (sug.dropped()) {
                const suggestions = dvui.dataGetSlice(null, te.data().id, "suggestions", [][]const u8) orelse suggestion_list;
                for (suggestions) |state_name| {
                    if (sug.addChoiceLabel(state_name)) {
                        _ = main.error_queue.swapRemove(self.key);

                        te.textSet(suggestions[sug.selected_index], true);
                        if (main.invoice.address_builder.setState(suggestions[sug.selected_index])) |err| {
                            self.setError(err);
                        }
                    }
                }
            }
        },
    }
}

fn setError(self: *Self, msg: []const u8) void {
    main.error_queue.put(self.key, msg) catch {
        log.err("Failed to add error to queue", .{});
    };
}
