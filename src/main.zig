const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const zqlite = @import("zqlite");
const log = std.log.scoped(.ae_main);

const Rect = dvui.Rect;
const Size = dvui.Size;
const Color = dvui.Color;

// user {
const fonts = @import("fonts");
const util = @import("util.zig");
const form_field = @import("components/form_field.zig");

const Invoice_Item = @import("components/invoice_item.zig");
const Db = @import("db/init.zig");
const Customers = @import("db/customers.zig");

const window_icon_png = @embedFile("assets/achal-logo.png");

var customer: Customers.Customer = .init();
pub var ae_db: Db = undefined;
pub var should_reset_form: bool = false;

// max-width of main container
pub const max_width = util.win_init_size.w * 0.75;

pub var item_list: std.ArrayList(Invoice_Item) = undefined;

// }

pub const dvui_app: dvui.App = .{
    .config = .{
        .options = .{
            .size = util.win_init_size,
            .min_size = util.win_min_size,
            .title = "Achal Enterprise Invoice",
            .icon = window_icon_png,
        },
    },
    .initFn = AppInit,
    .frameFn = AppFrame,
    .deinitFn = AppDeinit,
};

pub const main = dvui.App.main;
pub const panic = dvui.App.panic;
pub const std_options: std.Options = .{
    .logFn = dvui.App.logFn,
};

// init app state
var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_instance.allocator();

var orig_content_scale: f32 = 1.0;

pub fn AppInit(win: *dvui.Window) !void {
    ae_db = try Db.init(gpa);
    item_list = try .initCapacity(gpa, 8);
    try item_list.append(gpa, .{ .key = 999_999 });

    orig_content_scale = win.content_scale;

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

    theme.window.fill = util.Color.layer0.get();
}

// deinit app
pub fn AppDeinit() void {
    util.dumpStruct(Customers.Customer, customer, null);
    util.dumpStruct(@TypeOf(item_list), item_list, null);
    customer.deinit(gpa);
    ae_db.deinit();
    item_list.deinit(gpa);

    const leaked = gpa_instance.deinit();
    if (leaked == .leak) {
        log.err("Memory leak detected!", .{});
    }
}

// frame draw
pub fn AppFrame() !dvui.App.Result {
    return frame();
}

// this is redrawn every frame
pub fn frame() !dvui.App.Result {
    var key: usize = 0;

    // idk what this is
    var scaler = dvui.scale(@src(), .{ .scale = &dvui.currentWindow().content_scale, .pinch_zoom = .global }, .{ .rect = .cast(dvui.windowRect()) });
    scaler.deinit();

    dvui.label(@src(), "{d}", .{dvui.FPS()}, .{ .gravity_x = 1 });
    // menu
    {
        const padding = Rect.all(util.gap.sm);
        {
            var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{
                .tag = "menu-container",
                .style = .window,
                .background = true,
                .expand = .horizontal,
                .padding = padding,
            });
            defer hbox.deinit();

            var m = dvui.menu(@src(), .horizontal, .{});
            defer m.deinit();

            if (dvui.menuItemLabel(@src(), "File", .{ .submenu = true }, .{
                .tag = "first-focusable",
                .font = util.Font.extra_light.sm(),
            })) |r| {
                var fw = dvui.floatingMenu(@src(), .{ .from = r }, .{});
                defer fw.deinit();

                // new invoice
                if (dvui.menuItemLabel(@src(), "New Invoice", .{}, .{ .expand = .horizontal }) != null) {
                    customer.reset(gpa);

                    for (&form_field.all) |*field| {
                        field.err_msg = "";
                    }

                    should_reset_form = true;

                    m.close();
                }
                if (dvui.menuItemLabel(@src(), "Close Menu", .{}, .{ .expand = .horizontal }) != null) {
                    m.close();
                }

                if (dvui.backend.kind != .web) {
                    if (dvui.menuItemLabel(@src(), "Exit", .{}, .{ .expand = .horizontal }) != null) {
                        return .close;
                    }
                }
            }

            if (dvui.button(@src(), "dbg", .{}, .{
                .tag = "dbg",
            })) {
                dvui.toggleDebugWindow();
            }
        }

        {
            var pad = dvui.box(@src(), .{}, .{ .tag = "menu-padding", .padding = Rect{ .w = padding.w, .x = padding.x } });
            defer pad.deinit();

            var line = dvui.box(@src(), .{}, .{
                .tag = "menu-seperator",
                .background = true,
                .color_fill = Color.gray,
                .min_size_content = dvui.Size{ .w = dvui.windowRectPixels().w, .h = 1 },
            });
            defer line.deinit();
        }
    }

    // scrollable area below the menu
    var scroll = dvui.scrollArea(@src(), .{}, .{ .tag = "scroll", .expand = .both, .style = .window });
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

    // vbox for title and form-fields
    {
        const left_field_count = 5;

        var flex_container = dvui.box(@src(), .{ .dir = .horizontal }, .{
            .tag = "form-container",
            .expand = .horizontal,
            .margin = .{ .h = util.gap.xxxl },
        });
        defer flex_container.deinit();

        const column_width = (flex_container.child_rect.w - (util.gap.xxl)) / 2.0;

        // left column
        {
            // vbox for title and form-fields
            var left_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                .tag = "form-left-container",
                .min_size_content = .{ .w = column_width },
            });
            defer left_column.deinit();

            // form-fields
            {
                inline for (form_field.all[0..left_field_count], 0..) |*field, idx| {
                    field.render(key + idx, &customer);
                    key += 1;
                }
            }
        }

        // gap
        {
            var spacer = dvui.box(@src(), .{}, .{
                .tag = "form-spacer",
                .min_size_content = .{ .w = util.gap.xxl },
            });
            defer spacer.deinit();
        }

        // right column
        {
            // vbox for title and form-fields
            var right_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                .tag = "form-right-container",
                .min_size_content = .{ .w = column_width },
            });
            defer right_column.deinit();

            // form-fields
            {
                inline for (form_field.all[left_field_count..], 0..) |*field, idx| {
                    field.render(key + idx, &customer);
                    key += 1;
                }
            }
        }
    }

    // invoice item
    {
        Invoice_Item.render(key);
        key += 1;
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
            log.info("button clicked", .{});
        }
    }

    return .ok;
}
