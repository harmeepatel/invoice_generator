const builtin = @import("builtin");
const dvui = @import("dvui");
const fonts = @import("fonts");
const std = @import("std");
const util = @import("util.zig");
const zqlite = @import("zqlite");

const Color = util.Color;
const Field = @import("Field.zig");
const InvoiceBuilder = @import("invoice.zig").InvoiceBuilder;
const ItemBuilder = @import("invoice.zig").ItemBuilder;
const KeyGen = util.KeyGen;
const Rect = dvui.Rect;
const Size = dvui.Size;

const log = std.log.scoped(.ae_main);

pub const max_width = util.win_init_size.w * 0.75;
pub var should_reset_form: bool = false;

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_instance.allocator();

pub var error_queue: std.AutoArrayHashMap(usize, []const u8) = undefined;
pub var invoice: InvoiceBuilder = undefined;
pub var keygen: KeyGen = undefined;

pub const dvui_app: dvui.App = .{
    .config = .{
        .options = .{
            .size = util.win_init_size,
            .min_size = util.win_min_size,
            .title = "Achal Enterprise Invoice",
            .icon = @embedFile("assets/achal-logo.png"),
            .vsync = true,
        },
    },
    .initFn = AppInit,
    .frameFn = AppFrame,
    .deinitFn = AppDeinit,
};

pub const main = dvui.App.main;
pub const panic = dvui.App.panic;
// pub const std_options: std.Options = .{
//     .logFn = dvui.App.logFn,
// };

// init app state
pub fn AppInit(win: *dvui.Window) !void {
    error_queue = .init(gpa);
    invoice = try .init(gpa);
    keygen = .init();

    {
        try dvui.addFont("Cascadia_Mono_ExtraLight", fonts.Cascadia_Mono_Light, null);
        try dvui.addFont("Cascadia_Mono_Light", fonts.Cascadia_Mono_Light, null);
        try dvui.addFont("Cascadia_Mono_Regular", fonts.Cascadia_Mono_Regular, null);
        try dvui.addFont("Cascadia_Mono_Medium", fonts.Cascadia_Mono_Regular, null);
        try dvui.addFont("Cascadia_Mono_SemiBold", fonts.Cascadia_Mono_Regular, null);
        try dvui.addFont("Cascadia_Mono_Bold", fonts.Cascadia_Mono_Bold, null);

        if (false) {
            win.theme = switch (win.backend.preferredColorScheme() orelse .dark) {
                .light => dvui.Theme.builtin.adwaita_light,
                .dark => dvui.Theme.builtin.adwaita_dark,
            };
        }

        var theme = win.theme;
        defer dvui.themeSet(theme);

        theme.window.fill = Color.layer0.get();
    }
}

// deinit app
pub fn AppDeinit() void {
    error_queue.deinit();
    invoice.deinit();

    const leaked = gpa_instance.deinit();
    if (leaked == .leak) {
        log.err("Memory leak detected!", .{});
    }
}

// frame draw
pub fn AppFrame() !dvui.App.Result {
    @branchHint(.likely);
    if (builtin.mode == .Debug) {
        const box = dvui.box(@src(), .{ .dir = .horizontal }, .{
            .expand = .horizontal,
            .background = true,
            .color_fill = util.Color.debug.get(),
        });
        defer box.deinit();

        {
            var buf: [32]u8 = undefined;
            const fps = try std.fmt.bufPrint(&buf, "{d:.5}", .{dvui.FPS()});
            if (dvui.button(@src(), fps, .{}, .{
                .min_size_content = .{ .w = 80 },
                .gravity_x = 0.5,
            })) {
                dvui.toggleDebugWindow();
            }
        }
    }

    keygen = keygen.reset();
    return frame();
}

// this is redrawn every frame
pub fn frame() !dvui.App.Result {
    // scrollable area below the menu
    var scroll = dvui.scrollArea(@src(), .{ .horizontal_bar = .auto_overlay }, .{ .tag = "scroll", .expand = .both, .style = .window });
    defer scroll.deinit();

    var main_container = dvui.box(@src(), .{}, .{
        .tag = "main-container",
        .min_size_content = .{ .w = @min(dvui.windowRect().w, max_width) },
        .margin = Rect{
            .x = @max(util.gap.xxl, (dvui.windowRect().w - max_width) / 2.0),
            .w = @max(util.gap.xxl, (dvui.windowRect().w - max_width) / 2.0),
            .y = util.gap.xl,
            .h = util.gap.xxl,
        },
    });
    defer main_container.deinit();

    // customer details
    {
        var all = [_]Field{
            .{ .kind = .name, .label = "Name", .placeholder = "Hritik Roshan" },
            .{ .kind = .gstin, .label = "GSTIN", .placeholder = "24ABCDE1234F1Z5" },
            .{ .kind = .gst, .label = "GST %", .placeholder = "5.0" },
            .{ .kind = .email, .label = "Email (Optional)", .placeholder = "abc@xyz.com (Optional)" },
            .{ .kind = .phone, .label = "Phone", .placeholder = "+91 11111 99999" },
            .{ .kind = .remark, .label = "Remark (Optional)", .placeholder = "Transporter Name / Other Note (Optional)" },
            // address
            .{ .kind = .shop_no, .label = "Shop Number", .placeholder = "AB 404" },
            .{ .kind = .line_1, .label = "Address Line 1", .placeholder = "Complex / Plaza" },
            .{ .kind = .line_2, .label = "Address Line 2 (Optional)", .placeholder = "Landmark (Optional)" },
            .{ .kind = .line_3, .label = "Address Line 3 (Optional)", .placeholder = "Street Name (Optional)" },
            .{ .kind = .state, .variant = .selection_box, .label = "State", .placeholder = "Gujarat", .suggestions = &util.PostalCodes.states },
            .{ .kind = .city, .label = "City", .placeholder = "Ahmedabad" },
            .{ .kind = .postal_code, .label = "Postal Code", .placeholder = "123123" },
        };
        const left_field_count = 6;

        var flex_container = dvui.box(@src(), .{ .dir = .horizontal, .equal_space = true }, .{
            .tag = "form-container",
            .expand = .horizontal,
            .margin = .{ .h = util.gap.xxxl },
        });
        defer flex_container.deinit();

        // left column
        {
            var left_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                .tag = "form-left-container",
                .expand = .horizontal,
                .margin = .{ .w = util.gap.xxl / 2 },
            });
            defer left_column.deinit();

            {
                inline for (all[0..left_field_count]) |*field| {
                    field.render(keygen.emit());
                }
            }
        }

        // right column
        {
            var right_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                .tag = "form-right-container",
                .expand = .horizontal,
                .margin = .{ .x = util.gap.xxl / 2 },
            });
            defer right_column.deinit();

            {
                inline for (all[left_field_count..]) |*field| {
                    field.render(keygen.emit());
                }
            }
        }
    }

    // invoice items
    {
        {
            var vbox_item = dvui.box(
                @src(),
                .{ .dir = .vertical },
                .{
                    .id_extra = keygen.emit(),
                    .expand = .both,
                },
            );
            defer vbox_item.deinit();

            {
                for (invoice.item_list.items, 0..) |item, idx| {
                    if (idx == 0) item.row(&keygen, true) else item.row(&keygen, false);
                }
                if (invoice.item_list.items.len > 0) {
                    ItemBuilder.row(&keygen, false);
                } else {
                    ItemBuilder.row(&keygen, true);
                }
            }

            {
                if (dvui.button(@src(), "+", .{ .draw_focus = true }, .{
                    .tag = "add-item",
                    .expand = .horizontal,
                    .corner_radius = Rect.all(util.gap.xs),
                    .font = util.Font.extra_light.lg(),
                })) {
                    try invoice.addItem();
                    log.debug("invoice: {any}", .{invoice});
                    log.debug("invoice.item_builder: {any}", .{invoice.item_builder});
                    log.debug("invoice.item_list.items: {any}", .{invoice.item_list.items});
                    log.debug("", .{});
                }
            }
        }
    }

    // generate invoice button
    {
        if (dvui.button(@src(), "Generate Invoice", .{ .draw_focus = true }, .{
            .tag = "btn-generate-invoice",
            .expand = .both,
            .font = util.Font.semi_bold.lg(),
            .color_fill = util.Color.primary.get(),
            .corner_radius = Rect.all(util.gap.xs),
            .padding = Rect.all(util.gap.md),
            .margin = .{ .x = 0, .w = 0, .y = util.gap.xxl, .h = util.gap.xxl },
        })) {
            log.debug("invoice: {any}", .{invoice});
        }
    }

    return .ok;
}
