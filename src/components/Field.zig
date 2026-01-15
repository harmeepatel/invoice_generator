const std = @import("std");
const dvui = @import("dvui");
const util = @import("../util.zig");
const main = @import("../main.zig");

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

label_opts: dvui.Options = .{
    .margin = dvui.Rect{ .h = util.gap.sm },
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
    .margin = dvui.Rect{ .h = util.gap.xl },
    .padding = dvui.Rect.all(util.gap.md),
    .font = util.Font.light.sm(),
    // .color_border = util.Color.border.get(),
    .corner_radius = dvui.Rect.all(util.gap.xs),
    .min_size_content = .{ .h = util.text.sm },
},

pub fn init(typ: Kind) Self {
    return Self{ .kind = typ };
}

pub fn render(self: *Self, key: usize) void {
    self.key = key;

    var vbox = dvui.box(
        @src(),
        .{ .dir = .vertical },
        .{ .id_extra = self.key, .expand = .both },
    );
    defer vbox.deinit();

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

    switch (self.variant) {
        .default => {
            var te = dvui.textEntry(@src(), .{ .placeholder = if (self.placeholder) |ph| ph else "" }, self.text_entry_opts);
            defer te.deinit();

            if (main.should_reset_form) {
                te.textSet("", false);
            }

            if (te.text_changed) {
                const value = te.getText();
                log.debug("err_msg: {s}", .{value});
            }
        },
        else => unreachable,
    }
}
