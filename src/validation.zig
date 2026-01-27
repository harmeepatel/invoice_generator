const std = @import("std");
const util = @import("util.zig");

pub const Kind = enum {
    name,
    gstin,
    email,
    phone,
    remark,
    shop_no,
    line,
    state,
    city,
    postal_code,
    serial_number,
    item_name,
    hsn_code,
    quantity,
    sale_rate,
    discount,
    gst,
};

pub fn ValidationResult(comptime T: type) type {
    return union(enum) {
        Valid: ?T,
        Invalid: []const u8,
        OutOfRange: struct { min: f32, max: f32 },
        TooShort: void,
        TooLong: void,
        Required: void,
        Empty: void,

        pub fn isValid(self: @This()) bool {
            return switch (self) {
                .Valid => true,
                else => false,
            };
        }

        pub fn getValue(self: @This()) ?T {
            return switch (self) {
                .Valid => |v| v,
                else => null,
            };
        }

        threadlocal var error_buf: [256]u8 = undefined;

        pub fn errorMessage(self: @This()) ?[]const u8 {
            return switch (self) {
                .Valid => null,
                .Required => "Required",
                .TooShort => "Too Short",
                .TooLong => "Too Long",

                .Invalid => |msg| msg,

                .OutOfRange => |range| std.fmt.bufPrint(
                    &error_buf,
                    "Out of range {d} - {d}",
                    .{ range.min, range.max },
                ) catch "Out of range",

                .Empty => "Field is empty",
            };
        }
    };
}

// ============================================================================
// FIELD VALIDATORS
// ============================================================================

pub fn name(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;
    if (value.len < 2) return .TooShort;
    if (value.len > 100) return .TooLong;

    for (value) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or
            c == ' ' or c == '-' or c == '\'' or c == '.';
        if (!is_valid) {
            return .{ .Invalid = "Invalid characters" };
        }
    }

    var has_letter = false;
    for (value) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .Invalid = "Must contain letters" };

    return .{ .Valid = value };
}

pub fn GSTIN(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;
    if (value.len != 15) return .{ .Invalid = "Must be 15 characters" };

    if (!std.ascii.isDigit(value[0]) or !std.ascii.isDigit(value[1])) {
        return .{ .Invalid = "Invalid state code" };
    }

    for (value[2..7]) |c| {
        if (!std.ascii.isUpper(c)) {
            return .{ .Invalid = "Invalid PAN format" };
        }
    }

    for (value[7..11]) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .Invalid = "Invalid PAN format" };
        }
    }

    if (!std.ascii.isUpper(value[11])) {
        return .{ .Invalid = "Invalid PAN format" };
    }

    const entity_code = value[12];
    if (!std.ascii.isDigit(entity_code) and !std.ascii.isUpper(entity_code)) {
        return .{ .Invalid = "Invalid registration number" };
    }

    if (value[13] != 'Z') {
        return .{ .Invalid = "Invalid format" };
    }

    const checksum = value[14];
    if (!std.ascii.isAlphanumeric(checksum)) {
        return .{ .Invalid = "Invalid checksum" };
    }

    return .{ .Valid = value };
}

pub fn email(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Valid = null };

    if (value.len < 5) return .TooShort;
    if (value.len > 254) return .TooLong;

    const at_pos = std.mem.indexOf(u8, value, "@") orelse {
        return .{ .Invalid = "Missing @" };
    };

    if (at_pos == 0 or at_pos == value.len - 1) return .{ .Invalid = "Invalid format" };

    const second_at = std.mem.indexOfPos(u8, value, at_pos + 1, "@");
    if (second_at != null) return .{ .Invalid = "Multiple @" };

    const local_part = value[0..at_pos];
    const domain_part = value[at_pos + 1 ..];

    if (local_part.len > 64) return .TooLong;

    const dot_pos = std.mem.indexOf(u8, domain_part, ".") orelse {
        return .{ .Invalid = "Missing domain extension" };
    };

    if (dot_pos == 0 or dot_pos == domain_part.len - 1) return .{ .Invalid = "Invalid domain" };

    for (local_part) |c| {
        const is_valid = std.ascii.isAlphanumeric(c) or
            c == '.' or c == '_' or c == '-' or c == '+';
        if (!is_valid) {
            return .{ .Invalid = "Invalid characters" };
        }
    }

    for (domain_part) |c| {
        const is_valid = std.ascii.isAlphanumeric(c) or c == '.' or c == '-';
        if (!is_valid) {
            return .{ .Invalid = "Invalid domain characters" };
        }
    }

    return .{ .Valid = value };
}

pub fn phone(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;

    var digit_count: usize = 0;
    var has_plus = false;

    for (value) |c| {
        if (std.ascii.isDigit(c)) {
            digit_count += 1;
        } else if (c == '+') {
            if (has_plus) return .{ .Invalid = "Multiple +" };
            has_plus = true;
        } else if (c != ' ' and c != '-' and c != '(' and c != ')') {
            return .{ .Invalid = "Invalid characters" };
        }
    }

    if (digit_count < 10) return .TooShort;
    if (digit_count > 15) return .TooLong;

    if (has_plus) {
        if (value.len < 3 or value[0] != '+' or value[1] != '9' or value[2] != '1') {
            return .{ .Invalid = "Invalid country code" };
        }
    }

    var found_first_digit = false;
    var skip_country_code = has_plus;
    var skipped: usize = 0;

    for (value) |c| {
        if (std.ascii.isDigit(c)) {
            if (skip_country_code) {
                skipped += 1;
                if (skipped > 2) skip_country_code = false;
            }

            if (!skip_country_code and !found_first_digit) {
                found_first_digit = true;
                if (c < '6' or c > '9') {
                    return .{ .Invalid = "Must start with 6-9" };
                }
            }
        }
    }

    return .{ .Valid = value };
}

pub fn remark(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Valid = null };

    if (value.len < 2) return .TooShort;
    if (value.len > 256) return .TooLong;

    for (value) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or std.ascii.isDigit(c) or
            c == ' ' or c == '-' or c == '\'' or c == '.' or c == ',' or c == '/' or c == ':';
        if (!is_valid) {
            return .{ .Invalid = "Invalid characters" };
        }
    }

    var has_content = false;
    for (value) |c| {
        if (c != ' ') {
            has_content = true;
            break;
        }
    }
    if (!has_content) return .{ .Invalid = "Empty" };

    return .{ .Valid = value };
}

pub fn shopNo(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;
    if (value.len > 100) return .TooLong;

    var has_content = false;
    for (value) |c| {
        if (c != ' ' and c != '\t') {
            has_content = true;
            break;
        }
    }
    if (!has_content) return .{ .Invalid = "Empty" };

    return .{ .Valid = value };
}

pub fn line(value: []const u8, is_optional: bool) ValidationResult([]const u8) {
    if (value.len == 0) {
        if (is_optional) return .{ .Valid = null };
        return .Required;
    }

    if (is_optional) {
        if (value.len > 200) return .TooLong;
        return .{ .Valid = value };
    }

    if (value.len < 3) return .TooShort;
    if (value.len > 200) return .TooLong;

    var has_letter = false;
    for (value) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .Invalid = "Must contain letters" };

    return .{ .Valid = value };
}

pub fn city(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;
    if (value.len < 2) return .TooShort;
    if (value.len > 50) return .TooLong;

    for (value) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or c == ' ' or c == '-';
        if (!is_valid) {
            return .{ .Invalid = "Invalid characters" };
        }
    }

    var has_letter = false;
    for (value) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .Invalid = "Must contain letters" };

    return .{ .Valid = value };
}

pub fn state(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;

    var value_buf: [64]u8 = undefined;
    const value_lower = std.ascii.lowerString(&value_buf, value);

    for (util.PostalCodes.states) |s| {
        var state_buf: [64]u8 = undefined;
        const state_lower = std.ascii.lowerString(&state_buf, s);

        if (std.mem.eql(u8, state_lower, value_lower)) {
            return .{ .Valid = value };
        }
    }

    return .{ .Invalid = "Invalid state" };
}

pub fn postalCode(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;
    if (value.len != 6) return .{ .Invalid = "Must be 6 digits" };

    for (value) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .Invalid = "Digits only" };
        }
    }

    const code = std.fmt.parseInt(u32, value, 10) catch {
        return .{ .Invalid = "Invalid format" };
    };

    const first_digit = code / 100000;
    if (first_digit == 0 or first_digit > 8) {
        return .{ .Invalid = "Invalid region" };
    }

    return .{ .Valid = value };
}

pub fn postalCodeForState(postal_code: []const u8, for_state: []const u8) ValidationResult([]const u8) {
    const format_result = postalCode(postal_code);
    if (!format_result.isValid()) return format_result;

    const code = std.fmt.parseInt(u32, postal_code, 10) catch {
        return .{ .Invalid = "Invalid format" };
    };

    var state_buf: [64]u8 = undefined;
    const state_lower = std.ascii.lowerString(&state_buf, for_state);

    var state_idx: ?usize = null;
    for (util.PostalCodes.states, 0..) |s, idx| {
        var s_buf: [64]u8 = undefined;
        const s_lower = std.ascii.lowerString(&s_buf, s);
        if (std.mem.eql(u8, s_lower, state_lower)) {
            state_idx = idx;
            break;
        }
    }

    if (state_idx == null) return .{ .Invalid = "Invalid state" };

    const min_code = util.PostalCodes.min_codes[state_idx.?];
    const max_code = util.PostalCodes.max_codes[state_idx.?];

    if (code < min_code or code > max_code) {
        return .{ .OutOfRange = .{ .min = @floatFromInt(min_code), .max = @floatFromInt(max_code) } };
    }

    return .{ .Valid = postal_code };
}

pub fn hSNCode(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;

    if (value.len != 4 and value.len != 6 and value.len != 8) {
        return .{ .Invalid = "Must be 4, 6, or 8 digits" };
    }

    for (value) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .Invalid = "Digits only" };
        }
    }

    return .{ .Valid = value };
}

pub fn itemName(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;
    if (value.len < 2) return .TooShort;
    if (value.len > 100) return .TooLong;

    var has_letter = false;
    for (value) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .Invalid = "Must contain letters" };

    return .{ .Valid = value };
}

pub fn serialNumber(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Required;
    if (value.len > 50) return .TooLong;

    var has_content = false;
    for (value) |c| {
        if (c != ' ' and c != '\t') {
            has_content = true;
            break;
        }
    }
    if (!has_content) return .{ .Invalid = "Empty" };

    return .{ .Valid = value };
}

pub fn quantity(value: []const u8) ValidationResult(usize) {
    if (value.len == 0) return .Required;

    const qty = std.fmt.parseInt(usize, value, 10) catch {
        return .{ .Invalid = "Must be a number" };
    };

    if (qty == 0) return .{ .Invalid = "Must be > 0" };

    return .{ .Valid = qty };
}

pub fn saleRate(value: []const u8) ValidationResult(f16) {
    if (value.len == 0) return .Required;

    const rate = std.fmt.parseFloat(f16, value) catch {
        return .{ .Invalid = "Must be a number" };
    };

    if (rate <= 0) return .{ .Invalid = "Must be > 0" };

    return .{ .Valid = rate };
}

pub fn discount(value: []const u8) ValidationResult(f16) {
    if (value.len == 0) return .{ .Valid = 0.0 };

    const disc = std.fmt.parseFloat(f16, value) catch {
        return .{ .Invalid = "Must be a number" };
    };

    if (disc < 0 or disc > 100) {
        return .{ .OutOfRange = .{ .min = 0, .max = 100 } };
    }

    return .{ .Valid = disc };
}

pub fn GST(value: []const u8) ValidationResult(f16) {
    if (value.len == 0) return .Required;

    const gst_val = std.fmt.parseFloat(f16, value) catch {
        return .{ .Invalid = "Must be a number" };
    };

    if (gst_val < 0 or gst_val > 28) {
        return .{ .OutOfRange = .{ .min = 0, .max = 28 } };
    }

    const valid_rates = [_]f16{ 0, 5, 12, 18, 28 };
    var is_valid_rate = false;
    for (valid_rates) |rate| {
        if (@abs(gst_val - rate) < 0.01) {
            is_valid_rate = true;
            break;
        }
    }

    if (!is_valid_rate) {
        return .{ .Invalid = "Must be 0, 5, 12, 18, or 28" };
    }

    return .{ .Valid = gst_val };
}

// STRING WRAPPER VALIDATORS
pub fn quantityStr(value: []const u8) ValidationResult([]const u8) {
    const result = quantity(value);
    return switch (result) {
        .Valid => .{ .Valid = value },
        .Required => .Required,
        .Invalid => |msg| .{ .Invalid = msg },
        else => .{ .Invalid = "Invalid" },
    };
}

pub fn saleRateStr(value: []const u8) ValidationResult([]const u8) {
    const result = saleRate(value);
    return switch (result) {
        .Valid => .{ .Valid = value },
        .Required => .Required,
        .Invalid => |msg| .{ .Invalid = msg },
        else => .{ .Invalid = "Invalid" },
    };
}

pub fn discountStr(value: []const u8) ValidationResult([]const u8) {
    const result = discount(value);
    return switch (result) {
        .Valid => .{ .Valid = value },
        .Required => .Required,
        .Invalid => |msg| .{ .Invalid = msg },
        .OutOfRange => .{ .OutOfRange = .{ .min = 0, .max = 100 } },
        else => .{ .Invalid = "Invalid" },
    };
}

pub fn GSTStr(value: []const u8) ValidationResult([]const u8) {
    const result = GST(value);
    return switch (result) {
        .Valid => .{ .Valid = value },
        .Required => .Required,
        .Invalid => |msg| .{ .Invalid = msg },
        .OutOfRange => .{ .OutOfRange = .{ .min = 0, .max = 28 } },
        else => .{ .Invalid = "Invalid" },
    };
}
