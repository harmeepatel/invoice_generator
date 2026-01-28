const builtin = @import("builtin");
const dvui = @import("dvui");
const std = @import("std");
const util = @import("util.zig");
const zqlite = @import("zqlite");
const validation = @import("validation.zig");

const Invoice = @import("invoice.zig");
const Field = @import("field.zig");
const Color = util.Color;
const KeyGen = util.KeyGen;
const Rect = dvui.Rect;
const Size = dvui.Size;

const clog: util.ColoredLog = .{ .log = std.log.scoped(.ae_main) };

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_instance.allocator();

pub const max_width = util.win_init_size.w * 0.75;
pub var keygen: KeyGen = undefined;
pub var invoice: Invoice = undefined;

pub var error_q: std.AutoArrayHashMap(usize, []const u8) = undefined;
pub var validation_q: std.ArrayList(validation.Kind) = undefined;
pub var field_kind_map: std.AutoArrayHashMap(usize, validation.Kind) = undefined;

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
    error_q = .init(gpa);
    validation_q = try .initCapacity(gpa, 2);
    field_kind_map = .init(gpa);

    {
        if (false) {
            win.theme = switch (win.backend.preferredColorScheme() orelse .dark) {
                .light => dvui.Theme.builtin.adwaita_light,
                .dark => dvui.Theme.builtin.adwaita_dark,
            };
        }

        var theme = win.theme;
        defer dvui.themeSet(theme);

        theme.embedded_fonts = util.fonts;
        theme.window.fill = Color.layer0.get();
        theme.err.fill = util.Color.err.get();
    }
}

// deinit app
pub fn AppDeinit() void {
    invoice.deinit();
    error_q.deinit();
    validation_q.deinit(gpa);
    field_kind_map.deinit();

    const leaked = gpa_instance.deinit();
    if (leaked == .leak) {
        clog.err("Memory leak detected!", .{});
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
    processValidationQueue();

    // scrollable area below the menu
    var scroll = dvui.scrollArea(@src(), .{ .horizontal_bar = .auto_overlay }, .{ .tag = "scroll", .expand = .both, .style = .window });
    defer scroll.deinit();

    var main_container = dvui.box(@src(), .{}, .{
        .tag = "main-container",
        .min_size_content = .{ .w = @min(dvui.windowRect().w, max_width) },
        .margin = Rect{
            .x = @max(util.gap.xxl, (dvui.windowRect().w - max_width) / 2.0),
            .w = @max(util.gap.xxl, (dvui.windowRect().w - max_width) / 2.0),
            .y = util.gap.xxl,
            .h = util.gap.xxl,
        },
    });
    defer main_container.deinit();

    // customer details
    {
        var flex_container = dvui.box(@src(), .{ .dir = .horizontal, .equal_space = true }, .{
            .tag = "form-container",
            .expand = .horizontal,
        });
        defer flex_container.deinit();

        // Left column
        {
            var fields = [_]Field{
                .{ .kind = .name, .label = "Name", .placeholder = "Hritik Roshan" },
                .{ .kind = .gstin, .label = "GSTIN", .placeholder = "24ABCDE1234F1Z5" },
                .{ .kind = .gst, .variant = .number, .label = "GST %", .placeholder = "5.0" },
                .{ .kind = .email, .is_optional = true, .label = "Email (Optional)", .placeholder = "abc@xyz.com" },
                .{ .kind = .phone, .label = "Phone", .placeholder = "+91 11111 99999" },
                .{ .kind = .remark, .is_optional = true, .label = "Remark (Optional)", .placeholder = "Transporter Name / Other Note" },
            };

            var left_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                .tag = "form-left-container",
                .expand = .horizontal,
                .margin = .{ .w = util.gap.xxl / 2 },
            });
            defer left_column.deinit();

            inline for (&fields, 0..) |*field, idx| {
                field.render(keygen.emit(), idx == fields.len - 1);
            }
        }

        // Right column
        {
            var fields = [_]Field{
                .{ .kind = .shop_no, .label = "Shop Number", .placeholder = "AB 404" },
                .{ .kind = .line, .label = "Address Line 1", .placeholder = "Complex / Plaza" },
                .{ .kind = .line, .is_optional = true, .label = "Address Line 2 (Optional)", .placeholder = "Landmark" },
                .{ .kind = .line, .is_optional = true, .label = "Address Line 3 (Optional)", .placeholder = "Street Name" },
                .{ .kind = .state, .variant = .selection, .label = "State", .placeholder = "Gujarat", .suggestions = &util.PostalCodes.states },
                .{ .kind = .city, .label = "City", .placeholder = "Ahmedabad" },
                .{ .kind = .postal_code, .label = "Postal Code", .placeholder = "123123" },
            };

            var right_column = dvui.box(@src(), .{ .dir = .vertical }, .{
                .tag = "form-right-container",
                .expand = .horizontal,
                .margin = .{ .x = util.gap.xxl / 2 },
            });
            defer right_column.deinit();

            inline for (&fields, 0..) |*field, idx| {
                field.render(keygen.emit(), idx == fields.len - 1);
            }
        }
    }

    _ = dvui.spacer(@src(), .{ .min_size_content = .{ .h = util.gap.xxxl } });

    // invoice items
    {
        var fields = [_]Field{
            .{ .kind = .serial_number, .label = "Serial Number", .placeholder = "000000000" },
            .{ .kind = .item_name, .label = "Item Name", .placeholder = "Bibcock" },
            .{ .kind = .hsn_code, .label = "HSN Code", .placeholder = "000000" },
            .{ .kind = .quantity, .label = "Quantity(Q)", .placeholder = "0" },
            .{ .kind = .sale_rate, .label = "Sale Rate(SR)", .placeholder = "00.00" }, // TODO: make a db and add products to automatically find prices
            .{ .kind = .discount, .label = "Discount %", .placeholder = "00.00" },
        };

        var fbox = dvui.flexbox(@src(), .{
            .justify_content = .start,
        }, .{
            .id_extra = keygen.emit(),
            .expand = .both,
        });
        defer fbox.deinit();

        const hgap = util.gap.xs;
        inline for (&fields, 0..) |*field, idx| {
            const k = keygen.emit();

            field.label_opts.font = dvui.Font.find(.{ .family = "light" }).withSize(util.text.sm);
            field.text_entry_opts.id_extra = keygen.emit();
            field.main_container_opts.margin = .{ .h = 0, .w = if (idx == fields.len - 1) 0 else hgap };
            field.main_container_opts.min_size_content = .{
                .w = blk: {
                    const gaps = hgap * @as(f32, @floatFromInt(fields.len - 1));
                    const field_width = ((fbox.data().rect.w - gaps) / fields.len);
                    break :blk field_width;
                },
            };

            field.render(k, false);
        }
    }
    // generate invoice button
    {
        if (dvui.button(@src(), "Generate Invoice", .{ .draw_focus = true }, .{
            .tag = "btn-generate-invoice",
            .expand = .both,
            .font = dvui.Font.find(.{ .family = "semibold" }),
            .color_fill = util.Color.primary.get(),
            .corner_radius = Rect.all(util.gap.xs),
            .padding = Rect.all(util.gap.md),
            .margin = .{ .x = 0, .w = 0, .y = util.gap.xxl, .h = util.gap.xxl },
        })) {
            clog.debug("invoice: {any}", .{invoice});
        }
    }

    return .ok;
}

// Queue a field for revalidation
pub fn queueForRevalidation(kind: validation.Kind) !void {
    // Avoid duplicates
    for (validation_q.items) |item| {
        if (item == kind) return;
    }
    try validation_q.append(gpa, kind);
}

/// Process validation queue - revalidate all queued fields
pub fn processValidationQueue() void {
    while (validation_q.items.len > 0) {
        const kind = validation_q.pop();
        // Trigger revalidation for this field type
        if (kind) |k| {
            revalidateField(k);
        } else {
            @panic("validation_q is empty");
        }
    }
}

/// Revalidate a specific field by its kind
fn revalidateField(kind: validation.Kind) void {
    // Find all field keys that match this kind
    var it = field_kind_map.iterator();
    while (it.next()) |entry| {
        const field_key = entry.key_ptr.*;
        const field_kind = entry.value_ptr.*;

        if (field_kind != kind) continue;

        // Get the current value from invoice draft
        const value: []const u8 = switch (kind) {
            .name => invoice.draft.name orelse "",
            .gstin => invoice.draft.gstin orelse "",
            .email => invoice.draft.email orelse "",
            .phone => invoice.draft.phone orelse "",
            .remark => invoice.draft.remark orelse "",
            .shop_no => invoice.draft.address.shop_no orelse "",
            .line => invoice.draft.address.line_1 orelse "",
            .state => invoice.draft.address.state orelse "",
            .city => invoice.draft.address.city orelse "",
            .postal_code => invoice.draft.address.postal_code orelse "",
            .serial_number => invoice.draft.current_product.serial_number orelse "",
            .item_name => invoice.draft.current_product.name orelse "",
            .hsn_code => invoice.draft.current_product.hsn_code orelse "",
            .quantity => blk: {
                var buf: [32]u8 = undefined;
                if (invoice.draft.current_product.quantity) |qty| {
                    break :blk std.fmt.bufPrint(&buf, "{d}", .{qty}) catch "";
                }
                break :blk "";
            },
            .sale_rate => blk: {
                var buf: [32]u8 = undefined;
                if (invoice.draft.current_product.sale_rate) |rate| {
                    break :blk std.fmt.bufPrint(&buf, "{d}", .{rate}) catch "";
                }
                break :blk "";
            },
            .discount => blk: {
                var buf: [32]u8 = undefined;
                if (invoice.draft.current_product.discount) |disc| {
                    break :blk std.fmt.bufPrint(&buf, "{d}", .{disc}) catch "";
                }
                break :blk "";
            },
            .gst => blk: {
                var buf: [32]u8 = undefined;
                if (invoice.draft.gst) |gst_val| {
                    break :blk std.fmt.bufPrint(&buf, "{d}", .{gst_val}) catch "";
                }
                break :blk "";
            },
        };

        // Run validation
        const result = switch (kind) {
            .name => validation.name(value),
            .gstin => validation.GSTIN(value),
            .gst => validation.GSTStr(value),
            .email => validation.email(value),
            .phone => validation.phone(value),
            .remark => validation.remark(value),
            .shop_no => validation.shopNo(value),
            .line => validation.line(value, false),
            .state => validation.state(value),
            .city => validation.city(value),
            .postal_code => blk: {
                if (invoice.draft.address.state) |state| {
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

        // Update error_q based on validation result
        if (result.errorMessage()) |err_msg| {
            error_q.put(field_key, err_msg) catch |err| {
                clog.err("Failed to set error: {}", .{err});
            };
        } else {
            _ = error_q.swapRemove(field_key);
        }
    }
}
