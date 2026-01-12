const std = @import("std");
const dvui = @import("dvui");
const log = std.log.scoped(.ae_util);

const main = @import("main.zig");
const customers = @import("./db/customers.zig");
const validate = @import("validate_form.zig");

pub const Color = enum {
    layer0,
    layer1,

    primary,
    border,
    err,

    pub fn get(self: Color) dvui.Color {
        return switch (self) {
            .layer0 => dvui.Color.fromHSLuv(30, 8, 5, 100),
            .layer1 => Color.layer0.get().lighten(8),

            .primary => dvui.Color.fromHex("#6d6dff"),
            .border => Color.layer0.get().lighten(16),
            .err => dvui.Color.fromHex("#ff3333"),
        };
    }
};

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

fn makeScale(comptime base: f32, comptime scale: f32) type {
    return struct {
        pub const xs = base;
        pub const sm = xs * scale;
        pub const md = sm * scale;
        pub const lg = md * scale;
        pub const xl = lg * scale;
        pub const xxl = xl * scale;
        pub const xxxl = xxl * scale;
    };
}
const scaling = 1.28;
pub const gap = makeScale(10.0, scaling);
pub const text = makeScale(14.0, scaling);

pub const Font = enum {
    extra_light,
    light,
    regular,
    medium,
    semi_bold,
    bold,

    fn getName(self: Font) []const u8 {
        return switch (self) {
            .extra_light => "Cascadia_Mono_ExtraLight",
            .light => "Cascadia_Mono_Light",
            .regular => "Cascadia_Mono_Regular",
            .medium => "Cascadia_Mono_Medium",
            .semi_bold => "Cascadia_Mono_SemiBold",
            .bold => "Cascadia_Mono_Bold",
        };
    }

    inline fn makeFont(self: Font, size: f32) dvui.Font {
        return dvui.Font{
            .size = size,
            .id = dvui.Font.FontId.fromName(self.getName()),
        };
    }

    pub fn xs(self: Font) dvui.Font {
        return self.makeFont(text.xs);
    }
    pub fn sm(self: Font) dvui.Font {
        return self.makeFont(text.sm);
    }
    pub fn md(self: Font) dvui.Font {
        return self.makeFont(text.md);
    }
    pub fn lg(self: Font) dvui.Font {
        return self.makeFont(text.lg);
    }
    pub fn xl(self: Font) dvui.Font {
        return self.makeFont(text.xl);
    }
    pub fn xxl(self: Font) dvui.Font {
        return self.makeFont(text.xxl);
    }
};

pub const FieldOptions = struct {
    pub const label = dvui.Options{
        .margin = dvui.Rect{ .h = gap.sm },
        .padding = dvui.Rect.all(0),
        .font = Font.light.md(),
    };
    pub const err_label = dvui.Options{
        .padding = dvui.Rect.all(0),
        .font = Font.light.sm(),
        .color_text = Color.err.get(),
        .gravity_x = 1.0,
    };
    pub const text_entry = dvui.Options{
        .expand = .horizontal,
        .margin = dvui.Rect{ .h = gap.xl },
        .padding = dvui.Rect.all(gap.md),
        .font = Font.light.sm(),
        .color_border = Color.layer0.get().lighten(16),
        .corner_radius = dvui.Rect.all(gap.xs),
        .min_size_content = .{ .h = text.sm },
    };
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
