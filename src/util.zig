const std = @import("std");
const dvui = @import("dvui");
const log = std.log.scoped(.aei_util);

const main = @import("main.zig");
const customers = @import("./db/customers.zig");
const validate = @import("validate.zig");
const form_field = @import("components/form_field.zig");

pub const win_aspect_ratio: dvui.Rect = .{ .w = 16.0, .h = 10.0 };
pub const win_init_size: dvui.Size = .{ .w = win_aspect_ratio.w * 100, .h = win_aspect_ratio.h * 100 };
pub const win_min_size: dvui.Size = .{ .w = win_aspect_ratio.w * 50, .h = win_aspect_ratio.h * 50 };

pub const PostalCodes = struct {
    pub const states = [_][]const u8{
        "Andaman and Nicobar Islands",
        "Andhra Pradesh",
        "Arunachal Pradesh",
        "Assam",
        "Bihar",
        "Chandigarh",
        "Chhattisgarh",
        "Dadra and Nagar Haveli and Daman and Diu",
        "Delhi",
        "Goa",
        "Gujarat",
        "Haryana",
        "Himachal Pradesh",
        "Jammu and Kashmir (including Ladakh)",
        "Jharkhand",
        "Karnataka",
        "Kerala",
        "Lakshadweep",
        "Madhya Pradesh",
        "Maharashtra",
        "Manipur",
        "Meghalaya",
        "Mizoram",
        "Nagaland",
        "Odisha",
        "Puducherry",
        "Punjab",
        "Rajasthan",
        "Sikkim",
        "Tamil Nadu",
        "Telangana",
        "Tripura",
        "Uttar Pradesh",
        "Uttarakhand",
        "West Bengal",
    };

    pub const min_codes = [_]u32{
        744101, 507130, 790001, 781001, 800001, 140119, 490001, 362520,
        110001, 403001, 360001, 121001, 171001, 180001, 813208, 560001,
        670001, 682551, 450001, 400001, 795001, 783123, 796001, 797001,
        751001, 533464, 140001, 301001, 737101, 600001, 500001, 799001,
        201001, 244712, 700001,
    };

    pub const max_codes = [_]u32{
        744304, 535594, 792131, 788931, 855117, 160102, 497778, 396240,
        110097, 403806, 396590, 136156, 177601, 194404, 835325, 591346,
        695615, 682559, 488448, 445402, 795159, 794115, 796901, 798627,
        770076, 673310, 160104, 345034, 737139, 643253, 509412, 799290,
        285223, 263680, 743711,
    };

    pub const count = states.len;

    comptime {
        std.debug.assert(states.len == min_codes.len);
        std.debug.assert(states.len == max_codes.len);
    }
};

pub var form_fields: ?struct {
    name: FormField,
    gstin: FormField,
    email: FormField,
    phone: FormField,
    address: FormField,
} = null;

fn makeScale(comptime base: f32, comptime scale: f32) type {
    return struct {
        pub const xs = base;
        pub const sm = xs * scale;
        pub const md = sm * scale;
        pub const lg = md * scale;
        pub const xl = lg * scale;
        pub const xxl = xl * scale;
    };
}
const scaling = 1.36;
pub const gap = makeScale(8.0, scaling);
pub const text = makeScale(13.0, scaling);

fn makeHeightScale() type {
    return struct {
        pub const x1 = 1.0;
        pub const x2 = 2.0;
        pub const x4 = 4.0;
        pub const x6 = 6.0;
        pub const x8 = 8.0;
    };
}
pub const scale_h = makeHeightScale();

pub fn font(size: f32, name: []const u8) dvui.Font {
    return dvui.Font{
        .size = size,
        .id = dvui.Font.FontId.fromName(name),
    };
}

pub const FormField = struct {
    kind: form_field.FormField.Kind,
    label: []const u8,
    err_msg: []const u8 = "",
    multiline: bool = false,
    placeholder: []const u8 = "",

    label_options: dvui.Options = .{
        .padding = dvui.Rect.all(0),
        .font = font(text.sm, "Cascadia_Mono_Light"),
    },
    err_label_options: dvui.Options = .{
        .padding = dvui.Rect.all(0),
        .font = font(text.sm, "Cascadia_Mono_Light"),
        .color_text = dvui.Color.fromHex("#ED4A4A"),
        .gravity_x = 1.0,
    },
    text_entry_options: dvui.Options = .{
        .expand = .horizontal,
        .margin = dvui.Rect{ .h = gap.xl },
        .padding = dvui.Rect.all(gap.sm),
        .font = font(text.sm, "Cascadia_Mono_Light"),
        .min_size_content = .{ .h = text.sm },
    },

    pub fn validateAndUpdate(
        self: *FormField,
        text_entry_widget: *dvui.TextEntryWidget,
        customer: *customers.Customer,
    ) void {
        const result = validate.validate(self.kind, text_entry_widget.getText(), customer.*);

        if (result.err_msg) |err| {
            self.err_msg = err;
        } else {
            self.err_msg = "";
            customer.setCustomerField(main.gpa, self.kind, text_entry_widget.getText()) catch |err| {
                log.err("Error setting customer field {any} with \n {any}", .{ self.kind, err });
            };

            // Revalidate dependent fields
            for (result.revalidate_fields) |revalidate_kind| {
                for (&form_field.all_fields) |*other_field| {
                    if (other_field.kind == revalidate_kind) {
                        const current_value = customer.getFieldValue(revalidate_kind);
                        const revalidation_result = validate.validate(
                            revalidate_kind,
                            current_value,
                            customer.*,
                        );

                        if (revalidation_result.err_msg) |revalidate_err| {
                            other_field.err_msg = revalidate_err;
                        } else {
                            other_field.err_msg = "";
                        }
                        break;
                    }
                }
            }
        }
    }
};

pub fn dumpStruct(comptime T: type, value: T, spaces: ?comptime_int) void {
    const info = @typeInfo(T);

    const spc = spaces orelse 1;
    const indent = "  ";
    const indent2 = indent ++ indent;

    switch (info) {
        .@"struct" => |s| {
            if (spc != 1) {
                log.info("{s}{s} {{", .{ indent, @typeName(T) });
            } else {
                log.info("{s} {{", .{@typeName(T)});
            }

            inline for (s.fields) |field| {
                const field_value = @field(value, field.name);

                // If the field is itself a struct, recurse
                switch (@typeInfo(field.type)) {
                    .@"struct" => {
                        const nest_indent = indent2.len * 4;
                        log.info("{s}{s} =", .{ indent2, field.name });
                        dumpStruct(field.type, field_value, nest_indent);
                    },
                    .optional => {
                        if (field_value) |v| {
                            log.info("{s}{s} = {s}", .{ indent2, field.name, v });
                        }
                    },
                    else => {
                        if (@TypeOf(field_value) == []const u8) {
                            log.info("{s}{s} = {s}", .{ indent2, field.name, field_value });
                        } else {
                            log.info("{s}{s} = {any}", .{ indent2, field.name, field_value });
                        }
                    },
                }
            }

            if (spc != 1) {
                log.info("{s}}}", .{indent});
            } else {
                log.info("}}", .{});
            }
        },

        else => {
            log.info("cannot dump non-struct type: {s}", .{@typeName(T)});
        },
    }
}
