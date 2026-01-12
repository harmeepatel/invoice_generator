const std = @import("std");
const dvui = @import("dvui");
const main = @import("../main.zig");
const util = @import("../util.zig");
const log = std.log.scoped(.ae_invoice_item);

const Rect = dvui.Rect;

var label_options: dvui.Options = util.FieldOptions.label;
var text_entry_options = util.FieldOptions.text_entry;

key: usize,
const Self = @This();

pub const ItemField = struct {
    kind: Kind,
    label: []const u8,
    placeholder: []const u8 = "",
    has_error: bool = false,

    const Kind = enum {
        serial_number,
        item_name,
        hsn_code,
        quantity,
        sale_rate,
        discount,
        gst,
        total_tax,
        amount,
    };

    fn render(field: ItemField, key: usize, want_label: bool) void {
        var col_box = dvui.box(@src(), .{ .dir = .vertical }, .{
            .id_extra = key,
            .expand = .both,
            .min_size_content = .{ .w = main.max_width / (all.len + 1) },
            .max_size_content = .{ .w = main.max_width / (all.len + 1), .h = dvui.currentWindow().rect_pixels.h },
        });
        defer col_box.deinit();

        label_options.font = util.Font.light.sm();
        if (want_label) dvui.labelNoFmt(@src(), field.label, .{}, label_options);

        text_entry_options.id_extra = key;
        text_entry_options.margin = Rect{ .h = util.gap.sm };

        var te = dvui.textEntry(@src(), .{ .placeholder = field.placeholder }, text_entry_options);
        defer te.deinit();
    }
};

pub var all = [_]ItemField{
    .{ .kind = .serial_number, .label = "Serial Number", .placeholder = "000000000" },
    .{ .kind = .item_name, .label = "Item Name", .placeholder = "Bibcock" },
    .{ .kind = .hsn_code, .label = "HSN Code", .placeholder = "000000" },
    .{ .kind = .quantity, .label = "Quantity(Q)", .placeholder = "0" },
    .{ .kind = .sale_rate, .label = "Sale Rate(SR)", .placeholder = "00.00" },
    .{ .kind = .discount, .label = "Discount %", .placeholder = "00.00" },
    .{ .kind = .gst, .label = "GST", .placeholder = "00.00" }, // TODO: can be calculated
    .{ .kind = .total_tax, .label = "Total Tax", .placeholder = "00.00" }, // TODO: can be calculated
    .{ .kind = .amount, .label = "Amount", .placeholder = "Q * SR" }, // TODO: can be calculated
};

pub fn renderItem(self: Self, want_label: bool) void {
    var col_box = dvui.box(
        @src(),
        .{ .dir = .horizontal },
        .{
            .id_extra = self.key,
            .expand = .both,
        },
    );
    defer col_box.deinit();

    inline for (all[0..], 0..) |*field, idx| {
        const k = self.key + idx;
        field.render(k, want_label);

        // gap
        if (idx < all.len - 1) {
            var spacer = dvui.box(@src(), .{}, .{
                .id_extra = k,
                .min_size_content = .{ .w = util.gap.sm },
            });
            defer spacer.deinit();
        }
    }
}

pub fn render(key: usize) void {
    var row_box = dvui.box(
        @src(),
        .{ .dir = .vertical },
        .{
            .id_extra = key,
            .expand = .both,
        },
    );
    defer row_box.deinit();

    {
        for (main.item_list.items, 0..) |item, idx| {
            item.renderItem(if (idx == 0) true else false);
        }
    }

    {
        const font = util.Font.extra_light.lg();
        if (dvui.button(@src(), "+", .{ .draw_focus = true }, .{
            .tag = "add-item",
            .expand = .both,
            .corner_radius = Rect.all(util.gap.xs),
            .font = font,
        })) {
            const next_key = if (main.item_list.items.len > 0)
                main.item_list.items[main.item_list.items.len - 1].key + 1
            else
                key;
            main.item_list.append(main.gpa, .{ .key = next_key }) catch |err| {
                log.err("Failed to append item: {}", .{err});
            };
        }
    }
}
