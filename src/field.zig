const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const util = @import("util.zig");
const main = @import("main.zig");

const validation = @import("validation.zig");
const clog: util.ColoredLog = .{ .log = std.log.scoped(.ae_field) };

const field_error = "_FIELD_ERROR";

const Self = @This();

pub const Variant = enum {
    text,
    number,
    selection,
};

kind: validation.Kind,
key: usize = 0,
variant: Variant = .text,
label: ?[]const u8 = null,
placeholder: ?[]const u8 = null,
field_text: ?[]const u8 = null,
suggestions: ?[]const []const u8 = null,
is_optional: bool = false,

main_container_opts: dvui.Options = .{
    .expand = .both,
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
    .padding = .{ .y = util.gap.sm, .h = util.gap.sm, .x = util.gap.md, .w = util.gap.md },
    .color_border = util.Color.border.get(),
    .font = util.Font.light.sm(),
    .corner_radius = dvui.Rect.all(util.gap.xs),
    .min_size_content = .{ .h = util.text.sm },
},

pub fn render(self: *Self, key: usize, is_last: bool) void {
    self.key = key;
    self.main_container_opts.id_extra = self.key;

    main.field_kind_map.put(self.key, self.kind) catch |err| {
        clog.err("Failed to register field kind: {}", .{err});
    };

    var vbox = dvui.box(@src(), .{ .dir = .vertical }, self.main_container_opts);
    defer vbox.deinit();

    if (builtin.mode == .Debug) {
        dvui.label(@src(), "{d}", .{self.key}, .{
            .font = util.Font.extra_light.xs(),
            .color_text = util.Color.debug.get(),
            .padding = dvui.Rect.all(0),
        });
    }

    {
        var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{ .expand = .horizontal });
        defer hbox.deinit();

        if (self.label) |label| dvui.labelNoFmt(@src(), label, .{}, self.label_opts);

        if (self.getError()) |err_msg| {
            dvui.labelNoFmt(@src(), err_msg, .{}, self.err_label_opts);
        }
    }

    _ = dvui.spacer(@src(), .{ .expand = .both, .min_size_content = .{ .h = util.gap.xs } });

    switch (self.variant) {
        .text => self.renderTextEntry(),
        .number => self.renderNumberEntry(),
        .selection => self.renderSelection(),
    }

    if (!is_last)
        _ = dvui.spacer(@src(), .{ .id_extra = key, .expand = .both, .min_size_content = .{ .h = util.gap.lg } });
}

fn renderTextEntry(self: *Self) void {
    var te = dvui.TextEntryWidget.init(@src(), .{
        // .text = .{ .internal = .{ .limit = 5 } },
    }, self.text_entry_opts);
    defer te.deinit();

    te.install();
    te.processEvents();
    te.draw();

    // Then apply error styling on top
    const rs = te.data().borderRectScale();
    if (self.getError()) |_| {
        rs.r.outsetAll(0).stroke(
            te.data().options.corner_radiusGet().scale(rs.s, dvui.Rect.Physical),
            .{
                .thickness = 3 * rs.s,
                .color = util.Color.err.get(),
                .after = true,
            },
        );
    } else {
        self.text_entry_opts.color_border = util.Color.border.get();
    }

    if (self.field_text) |text| {
        te.textSet(text, false);
    }

    if (te.text_changed) {
        const value = te.getText();
        if (!self.handleValueChange(value)) {
            self.updateInvoiceDraft(value);
        }
    }
}

fn renderNumberEntry(self: *Self) void {
    const min: f16 = 0.0;
    const max: f16 = if (self.kind == .discount) 100.0 else std.math.floatMax(f16);

    const stored_value = dvui.dataGet(null, dvui.parentGet().data().id, @tagName(self.kind), f16) orelse 5.0;

    var value: f16 = stored_value;
    const result = dvui.textEntryNumber(@src(), f16, .{ .value = &value, .min = min, .max = max }, self.text_entry_opts);

    var num_buf: [32]u8 = undefined;
    if (result.changed) {
        dvui.dataSet(null, dvui.parentGet().data().id, @tagName(self.kind), value);
        const v = std.fmt.bufPrint(&num_buf, "{d}", .{value}) catch {
            @panic("aaaahhhhh!");
        };
        if (!self.handleValueChange(v)) {
            self.updateInvoiceDraft(v);
        }
    }
}

fn renderSelection(self: *Self) void {
    if (self.suggestions == null or self.suggestions.?.len == 0) {
        @panic("Suggestion List not found. Set `.suggestion_list` field for `.kind = selection`");
    }
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
        if (!self.handleValueChange(te.getText())) {
            self.updateInvoiceDraft(te.getText());
        }
    }

    if (sug.dropped()) {
        const suggestions = dvui.dataGetSlice(null, te.data().id, "suggestions", [][]const u8) orelse suggestion_list;
        for (suggestions) |state_name| {
            if (sug.addChoiceLabel(state_name)) {
                const selected_value = suggestions[sug.selected_index];
                te.textSet(selected_value, false);
                if (!self.handleValueChange(selected_value)) {
                    self.updateInvoiceDraft(selected_value);
                }
            }
        }
    }
}

fn handleValueChange(self: *Self, value: []const u8) bool {
    var has_error = false;

    const result = switch (self.kind) {
        .name => validation.name(value),
        .gstin => validation.GSTIN(value),
        .gst => validation.GSTStr(value),
        .email => validation.email(value),
        .phone => validation.phone(value),
        .remark => validation.remark(value),
        .shop_no => validation.shopNo(value),
        .line => validation.line(value, self.is_optional),
        .state => validation.state(value),
        .city => validation.city(value),
        .postal_code => blk: {
            // Get the state value from invoice draft
            if (main.invoice.draft.address.state) |state| {
                break :blk validation.postalCodeForState(value, state);
            }
            break :blk validation.postalCode(value);
        },
        .serial_number => validation.serialNumber(value),
        .item_name => validation.itemName(value),
        .hsn_code => validation.hSNCode(value),
        .quantity => validation.quantityStr(value),
        .sale_rate => validation.saleRateStr(value),
        .discount => validation.discountStr(value),
    };

    if (result.errorMessage()) |err_msg| {
        self.setError(err_msg);
        has_error = true;
    } else {
        self.removeError();
    }

    return has_error;
}

fn updateInvoiceDraft(self: *Self, value: []const u8) void {
    switch (self.kind) {
        .name => main.invoice.draft.name = value,
        .gstin => main.invoice.draft.gstin = value,
        .gst => {
            if (std.fmt.parseFloat(f16, value)) |gst_val| {
                main.invoice.draft.gst = gst_val;
            } else |_| {
                clog.err("Something went wrong parsing .gst", .{});
            }
        },
        .email => main.invoice.draft.email = value,
        .phone => main.invoice.draft.phone = value,
        .remark => main.invoice.draft.remark = value,
        .shop_no => main.invoice.draft.address.shop_no = value,
        .line => main.invoice.draft.address.line_1 = value,
        .state => {
            main.invoice.draft.address.state = value;
            main.queueForRevalidation(.postal_code) catch |err| {
                clog.err("Failed to queue revalidation: {}", .{err});
            };
        },
        .city => main.invoice.draft.address.city = value,
        .postal_code => main.invoice.draft.address.postal_code = value,
        .serial_number => main.invoice.draft.current_product.serial_number = value,
        .item_name => main.invoice.draft.current_product.name = value,
        .hsn_code => main.invoice.draft.current_product.hsn_code = value,
        .quantity => {
            if (std.fmt.parseInt(usize, value, 10)) |qty| {
                main.invoice.draft.current_product.quantity = qty;
            } else |_| {}
        },
        .sale_rate => {
            if (std.fmt.parseFloat(f16, value)) |rate| {
                main.invoice.draft.current_product.sale_rate = rate;
            } else |_| {}
        },
        .discount => {
            if (std.fmt.parseFloat(f16, value)) |disc| {
                main.invoice.draft.current_product.discount = disc;
            } else |_| {}
        },
    }
}

fn getError(self: *Self) ?[]const u8 {
    return main.error_q.get(self.key); 
}

fn setError(self: *Self, msg: []const u8) void {
    main.error_q.put(self.key, msg) catch |err| {
        clog.err("Failed to set error: {}", .{err});
    };
}

fn removeError(self: *Self) void {
    _ = main.error_q.swapRemove(self.key);
}
