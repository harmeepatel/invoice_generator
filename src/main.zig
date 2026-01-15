const builtin = @import("builtin");
const dvui = @import("dvui");
const fonts = @import("fonts");
const std = @import("std");
const util = @import("util.zig");
const zqlite = @import("zqlite");

const Color = util.Color;
const Field = @import("components/Field.zig");
const Rect = dvui.Rect;
const Size = dvui.Size;
const InvoiceBuilder = @import("invoice.zig").InvoiceBuilder;

const log = std.log.scoped(.ae_main);

pub const max_width = util.win_init_size.w * 0.75;
pub var should_reset_form: bool = false;

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_instance.allocator();

pub var error_queue: std.AutoArrayHashMap(usize, []const u8) = undefined;
pub var invoice: InvoiceBuilder = undefined;

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

    log.debug("{any}", .{invoice});

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
            .color_fill = util.Color.err.get(),
        });
        defer box.deinit();

        dvui.label(@src(), "{d}", .{dvui.FPS()}, .{ .gravity_x = 0.5 });
    }

    return frame();
}

// this is redrawn every frame
pub fn frame() !dvui.App.Result {
    // var key: usize = 0;

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
        var fields_arr = [_]Field{
            .init(.name),
            .init(.state),
            .init(.postal_code),
        };

        inline for (&fields_arr, 0..) |*field, idx| {
            field.render(idx);
        }
    }

    return .ok;
}
