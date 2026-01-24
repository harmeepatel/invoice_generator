const builtin = @import("builtin");
const dvui = @import("dvui");
const fonts = @import("fonts.zig");
const std = @import("std");
const util = @import("util.zig");
const zqlite = @import("zqlite");
const Invoice = @import("invoice.zig");

const Color = util.Color;
const KeyGen = util.KeyGen;
const Rect = dvui.Rect;
const Size = dvui.Size;

const log = std.log.scoped(.ae_main);

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_instance.allocator();

pub const max_width = util.win_init_size.w * 0.75;
pub var keygen: KeyGen = undefined;
pub var invoice: Invoice = undefined;

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
pub const std_options: std.Options = .{
    .logFn = dvui.App.logFn,
};

// init app state
pub fn AppInit(win: *dvui.Window) !void {
    keygen = .init();
    invoice = try .init(gpa);

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
    {}

    // invoice items
    {}

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
