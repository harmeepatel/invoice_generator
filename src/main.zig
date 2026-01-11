const std = @import("std");
const builtin = @import("builtin");
const dvui = @import("dvui");
const zqlite = @import("zqlite");
const log = std.log.scoped(.aei_main);

pub const Rect = dvui.Rect;
pub const Size = dvui.Size;

// user {
const fonts = @import("fonts");
const util = @import("util.zig");
const form_field = @import("components/form_field.zig");
const invoice_item = @import("components/invoice_item.zig");

const Db = @import("db/init.zig");
const customers = @import("db/customers.zig");

const window_icon_png = @embedFile("assets/achal-logo.png");

pub var ae_db: Db = undefined;
var customer: customers.Customer = .init();
pub var should_reset_form: bool = false;
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

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_instance.allocator();

var orig_content_scale: f32 = 1.0;

// init app state
pub fn AppInit(win: *dvui.Window) !void {
    ae_db = try Db.init(gpa);

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

    theme.window.fill = dvui.Color.fromHex("#141312ff");
}

// deinit app
pub fn AppDeinit() void {
    util.dumpStruct(customers.Customer, customer, null);
    customer.deinit(gpa);
    ae_db.deinit();

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

    // idk what this is
    var scaler = dvui.scale(@src(), .{ .scale = &dvui.currentWindow().content_scale, .pinch_zoom = .global }, .{ .rect = .cast(dvui.windowRect()) });
    scaler.deinit();

    // menu
    {
        const padding = Rect.all(util.gap.sm);
        {
            var hbox = dvui.box(@src(), .{ .dir = .horizontal }, .{
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
                .font = util.font(util.text.xs, "Cascadia_Mono_ExtraLight"),
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
        }

        {
            var pad = dvui.box(@src(), .{}, .{ .padding = Rect{ .w = padding.w, .x = padding.x } });
            defer pad.deinit();

            var line = dvui.box(@src(), .{}, .{
                .background = true,
                .color_fill = dvui.Color.gray,
                .min_size_content = dvui.Size{ .w = dvui.windowRectPixels().w, .h = 1 },
            });
            defer line.deinit();
        }
    }

    // random number generater for field keys
    var prng = std.Random.DefaultPrng.init(@intCast(14101998));
    const rand = prng.random();

    // scrollable area below the menu
    var scroll = dvui.scrollArea(@src(), .{}, .{ .expand = .both, .style = .window });
    defer scroll.deinit();

    // max-width of main container
    const max_width = util.win_init_size.w * 0.75;

    var main_container = dvui.box(@src(), .{}, .{
        .max_size_content = .{ .w = max_width, .h = dvui.currentWindow().rect_pixels.h },
        .margin = Rect{
            .y = util.gap.lg,
            .x = @max(util.gap.lg, (dvui.windowRect().w - max_width) / 2.0),
            .w = @max(util.gap.lg, (dvui.windowRect().w - max_width) / 2.0),
        },
    });
    defer main_container.deinit();

    // vbox for title and form-fields
    {
        var field_container = dvui.box(@src(), .{ .dir = .vertical }, .{
            .min_size_content = .{ .w = max_width },
        });
        defer field_container.deinit();

        // two column layout with half the window width
        {
            const left_field_count = 5;

            var flex_container = dvui.box(@src(), .{ .dir = .horizontal }, .{
                .expand = .horizontal,
            });
            defer flex_container.deinit();

            const column_gap = util.gap.md;
            const column_width = (flex_container.child_rect.w - (column_gap * 2)) / 2.0;

            // left column
            {
                // vbox for title and form-fields
                var left_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                    .min_size_content = .{ .w = column_width },
                    .max_size_content = .{
                        .w = column_width,
                        .h = util.win_init_size.h,
                    },
                });
                defer left_column.deinit();

                // form-fields
                {
                    const seed_a = rand.int(usize);

                    inline for (form_field.all[0..left_field_count], 0..) |*field, idx| {
                        field.render(seed_a + idx, &customer);
                    }
                }
            }

            // gap
            {
                var spacer = dvui.box(@src(), .{}, .{
                    .min_size_content = .{ .w = column_gap * 2 },
                });
                defer spacer.deinit();
            }

            // right column
            {
                // vbox for title and form-fields
                var right_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                    .min_size_content = .{ .w = column_width },
                    .max_size_content = .{
                        .w = column_width,
                        .h = util.win_init_size.h,
                    },
                });
                defer right_column.deinit();

                // form-fields
                {
                    const seed_b = rand.int(usize);

                    inline for (form_field.all[left_field_count..], 0..) |*field, idx| {
                        field.render(seed_b + idx, &customer);
                    }
                }
            }
        }

        // invoice item
        {
            const seed = rand.int(usize);
            invoice_item.render(seed);
        }

        // generate invoice button
        {
            const font = util.font(util.text.md, "Cascadia_Mono_Light");
            var btn_container = dvui.box(@src(), .{ .dir = .horizontal }, .{
                .expand = .horizontal,
                .max_size_content = .{ .w = max_width / 2, .h = font.size * util.scale_h.x8 },
            });
            defer btn_container.deinit();

            if (dvui.button(@src(), "Generate Invoice", .{ .draw_focus = true }, .{
                .tag = "btn-save",
                .expand = .both,
                .font = font,
            })) {
                log.info("button clicked", .{});
            }
        }
    }

    return .ok;
}
