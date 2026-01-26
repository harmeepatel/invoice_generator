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

main_container_opts: dvui.Options = .{
    .expand = .both,
    .margin = .{ .h = util.gap.lg },
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
    .padding = dvui.Rect.all(util.gap.sm),
    .color_border = util.Color.border.get(),
    .font = util.Font.light.sm(),
    .corner_radius = dvui.Rect.all(util.gap.xs),
    .min_size_content = .{ .h = util.text.sm },
},

pub fn render(self: *Self, key: usize) void {
    self.key = key;
    self.main_container_opts.id_extra = self.key;

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

    {
        const spacer = dvui.box(@src(), .{}, .{ .min_size_content = .{ .h = util.gap.xs } });
        spacer.deinit();
    }

    switch (self.variant) {
        .text => self.renderTextEntry(),
        .number => self.renderNumberEntry(),
        .selection => self.renderSelection(),
    }
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
        _ = self.handleValueChange(value);
    }
}

fn renderNumberEntry(self: *Self) void {
    const min: f16 = 0.0;
    const max: f16 = if (self.kind == .discount) 100.0 else std.math.floatMax(f16);

    const stored_value = dvui.dataGet(null, dvui.parentGet().data().id, @tagName(self.kind), f16) orelse 5.0;

    var value: f16 = stored_value;
    const result = dvui.textEntryNumber(@src(), f16, .{ .value = &value, .min = min, .max = max }, self.text_entry_opts);

    if (result.changed) {
        // self.handleValueChange(value);
        dvui.dataSet(null, dvui.parentGet().data().id, @tagName(self.kind), value);
    }
}

fn renderSelection(self: *Self) void {
    std.debug.assert(self.suggestions != null);
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
        _ = self.handleValueChange(te.getText());
    }

    if (sug.dropped()) {
        const suggestions = dvui.dataGetSlice(null, te.data().id, "suggestions", [][]const u8) orelse suggestion_list;
        for (suggestions) |state_name| {
            if (sug.addChoiceLabel(state_name)) {
                te.textSet(suggestions[sug.selected_index], true);
                _ = self.handleValueChange(suggestions[sug.selected_index]);
            }
        }
    }
}

fn handleValueChange(self: *Self, value: []const u8) bool {
    var is_error_set = false;
    const result = validation.validateName(value);

    if (result.errorMessage()) |err_msg| {
        self.setError(err_msg);
        is_error_set = true;
    } else {
        self.removeError();
    }

    return is_error_set;
}

// TODO
fn getError(self: *Self) ?[]const u8 {
    return main.error_queue.get(self.key);
}

fn setError(self: *Self, msg: []const u8) void {
    main.error_queue.put(self.key, msg) catch |err| {
        clog.err("Failed to set error: {}", .{err});
    };
}

fn removeError(self: *Self) void {
    _ = main.error_queue.swapRemove(self.key);
}
