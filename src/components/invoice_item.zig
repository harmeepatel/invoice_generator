const std = @import("std");
const dvui = @import("dvui");
const util = @import("../util.zig");

// pub const Invoice = struct {
//     id: i64,
//     invoice_no: i64, // Sequential number within fiscal year
//     customer_id: i64,
//     fiscal_year: [2]u16, // e.g., "2024-25"
//     invoice_date: i64, // Unix timestamp
//     due_date: i64, // Unix timestamp
//     transporter: []const u8,
//     subtotal: i64, // Amount in paise (1 rupee = 100 paise)
//     tax_amount: i64, // Tax in paise
//     total_amount: i64, // Total in paise
//     notes: ?[]const u8 = null,
//     created_at: i64 = 0,
// };

// pub const InvoiceItem = struct {
//     id: i64,
//     invoice_id: i64,
//     item_name: []const u8,
//     description: ?[]const u8 = null,
//     quantity: i64,
//     unit_price: i64, // Price in paise
//     tax_rate: i64, // Tax rate in basis points (e.g., 1800 = 18%)
//     amount: i64, // Total amount for this item in paise
// };

pub const ItemField = struct {
    label: []const u8,
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

    fn render(field: ItemField, key: usize) void {
        var col_box = dvui.box(
            @src(),
            .{ .dir = .vertical },
            .{
                .id_extra = key,
                .expand = .both,
                .margin = dvui.Rect{
                    .h = util.gap.md,
                    .w = util.gap.md,
                },
            },
        );
        defer col_box.deinit();

        {
            dvui.labelNoFmt(@src(), field.label, .{}, .{});
        }

        {
            const text_init_options: dvui.TextEntryWidget.InitOptions = .{
                .placeholder = field.placeholder,
                .multiline = field.multiline,
            };

            var te = dvui.textEntry(@src(), text_init_options, field.text_entry_options);
            defer te.deinit();
        }
    }
};

pub var all = [_]ItemField{
    .{ .label = "Name", .placeholder = "Hritik Roshan" },
    .{ .label = "GSTIN", .placeholder = "24ABCDE1234F1Z5" },
    .{ .label = "Email (Optional)", .placeholder = "abc@xyz.com (Optional)" },
    .{ .label = "Phone", .placeholder = "+91 11111 99999" },
    .{ .label = "Remark (Optional)", .placeholder = "Transporter Name / Other Note (Optional)" },
};

pub fn render(key: usize) void {
    var main_stack = dvui.box(
        @src(),
        .{ .dir = .horizontal },
        .{
            .expand = .both,
            .margin = dvui.Rect{ .h = util.gap.md },
        },
    );
    defer main_stack.deinit();

    // random number generater for field keys
    var prng = std.Random.DefaultPrng.init(@intCast(key));
    const rand = prng.random();

    {
        const seed = rand.int(usize);

        inline for (all[0..], 0..) |*field, idx| {
            field.render(seed + idx);
        }
    }
}
