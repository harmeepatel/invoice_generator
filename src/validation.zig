const std = @import("std");
const util = @import("util.zig");

pub const Kind = enum {
    name,
    gstin,
    email,
    phone,
    remark,
    shop_no,
    line_1,
    line_2,
    line_3,
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
        Valid: T,
        Required: []const u8,
        TooShort: struct { min: usize, field: []const u8 },
        TooLong: struct { max: usize, field: []const u8 },
        InvalidFormat: []const u8,
        OutOfRange: struct { min: f32, max: f32, field: []const u8 },
        InvalidCharacters: []const u8,
        InvalidLength: struct { expected: usize, field: []const u8 },
        DoesNotMatch: []const u8,
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

                .Required => |field| std.fmt.bufPrint(
                    &error_buf,
                    "{s} is required",
                    .{field},
                ) catch "Required",

                .TooShort => |info| std.fmt.bufPrint(
                    &error_buf,
                    "{s} must be at least {d} characters",
                    .{ info.field, info.min },
                ) catch "Too short",

                .TooLong => |info| std.fmt.bufPrint(
                    &error_buf,
                    "{s} must be at most {d} characters",
                    .{ info.field, info.max },
                ) catch "Too long",

                .InvalidFormat => |desc| desc,

                .OutOfRange => |range| std.fmt.bufPrint(
                    &error_buf,
                    "{s} must be between {d} and {d}",
                    .{ range.field, range.min, range.max },
                ) catch "Out of range",

                .InvalidCharacters => |desc| desc,

                .InvalidLength => |info| std.fmt.bufPrint(
                    &error_buf,
                    "{s} must be exactly {d} characters",
                    .{ info.field, info.expected },
                ) catch "Invalid length",

                .DoesNotMatch => |what| std.fmt.bufPrint(
                    &error_buf,
                    "Does not match {s}",
                    .{what},
                ) catch "Does not match",

                .Empty => "Field is empty",
            };
        }

        pub fn errorMessageStatic(self: @This()) []const u8 {
            return switch (self) {
                .Valid => "",
                .Required => |field| blk: {
                    var buf: [128]u8 = undefined;
                    break :blk std.fmt.bufPrint(&buf, "{s} is required", .{field}) catch "Required";
                },
                .TooShort => |info| blk: {
                    var buf: [128]u8 = undefined;
                    break :blk std.fmt.bufPrint(&buf, "{s} must be at least {d} characters", .{ info.field, info.min }) catch "Too short";
                },
                .TooLong => |info| blk: {
                    var buf: [128]u8 = undefined;
                    break :blk std.fmt.bufPrint(&buf, "{s} must be at most {d} characters", .{ info.field, info.max }) catch "Too long";
                },
                .InvalidFormat => |desc| desc,
                .OutOfRange => |range| blk: {
                    var buf: [128]u8 = undefined;
                    break :blk std.fmt.bufPrint(&buf, "{s} must be between {d} and {d}", .{ range.field, range.min, range.max }) catch "Out of range";
                },
                .InvalidCharacters => |desc| desc,
                .InvalidLength => |info| blk: {
                    var buf: [128]u8 = undefined;
                    break :blk std.fmt.bufPrint(&buf, "{s} must be exactly {d} characters", .{ info.field, info.expected }) catch "Invalid length";
                },
                .DoesNotMatch => |what| blk: {
                    var buf: [128]u8 = undefined;
                    break :blk std.fmt.bufPrint(&buf, "Does not match {s}", .{what}) catch "Does not match";
                },
                .Empty => "Field is empty",
            };
        }
    };
}

pub fn validateName(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "Name" };
    if (value.len < 3) return .{ .TooShort = .{ .min = 3, .field = "Name" } };
    if (value.len > 100) return .{ .TooLong = .{ .max = 100, .field = "Name" } };
    return .{ .Valid = value };
}

pub fn validateGSTIN(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "GSTIN" };
    if (value.len != 15) return .{ .InvalidLength = .{ .expected = 15, .field = "GSTIN" } };

    // First 2 must be digits (state code)
    if (!std.ascii.isDigit(value[0]) or !std.ascii.isDigit(value[1])) {
        return .{ .InvalidFormat = "GSTIN must start with 2-digit state code" };
    }

    // Next 10 characters - PAN (5 letters, 4 digits, 1 letter)
    for (value[2..7]) |c| {
        if (!std.ascii.isAlphabetic(c)) {
            return .{ .InvalidFormat = "GSTIN format invalid at PAN section" };
        }
    }
    for (value[7..11]) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .InvalidFormat = "GSTIN format invalid at PAN section" };
        }
    }
    if (!std.ascii.isAlphabetic(value[11])) {
        return .{ .InvalidFormat = "GSTIN format invalid at PAN section" };
    }

    // 12th character - entity code (digit)
    if (!std.ascii.isDigit(value[12])) {
        return .{ .InvalidFormat = "GSTIN entity code must be a digit" };
    }

    // 13th character - default 'Z'
    if (!std.ascii.isAlphabetic(value[13])) {
        return .{ .InvalidFormat = "GSTIN 13th character must be alphabetic" };
    }

    // 14th character - checksum (alphanumeric)
    if (!std.ascii.isAlphanumeric(value[14])) {
        return .{ .InvalidFormat = "GSTIN checksum must be alphanumeric" };
    }

    return .{ .Valid = value };
}

pub fn validateGST(value: []const u8) ValidationResult(f16) {
    if (value.len == 0) return .{ .Required = "GST %" };

    const gst_val = std.fmt.parseFloat(f16, value) catch {
        return .{ .InvalidFormat = "GST % must be a valid number" };
    };

    if (gst_val < 0 or gst_val > 28) {
        return .{ .OutOfRange = .{ .min = 0, .max = 28, .field = "GST %" } };
    }

    // Validate against common GST rates in India: 0, 5, 12, 18, 28
    const valid_rates = [_]f16{ 0, 5, 12, 18, 28 };
    var is_valid_rate = false;
    for (valid_rates) |rate| {
        if (@abs(gst_val - rate) < 0.01) {
            is_valid_rate = true;
            break;
        }
    }

    if (!is_valid_rate) {
        return .{ .InvalidFormat = "GST % should be 0, 5, 12, 18, or 28" };
    }

    return .{ .Valid = gst_val };
}

pub fn validateEmail(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Empty; // Optional field

    if (value.len < 5) return .{ .TooShort = .{ .min = 5, .field = "Email" } };
    if (value.len > 100) return .{ .TooLong = .{ .max = 100, .field = "Email" } };

    // Basic email validation: must contain @ and .
    const at_pos = std.mem.indexOf(u8, value, "@") orelse {
        return .{ .InvalidFormat = "Email must contain @" };
    };

    if (at_pos == 0) return .{ .InvalidFormat = "Email cannot start with @" };
    if (at_pos == value.len - 1) return .{ .InvalidFormat = "Email cannot end with @" };

    const after_at = value[at_pos + 1 ..];
    const dot_pos = std.mem.indexOf(u8, after_at, ".") orelse {
        return .{ .InvalidFormat = "Email must contain domain extension" };
    };

    if (dot_pos == 0) return .{ .InvalidFormat = "Invalid email domain format" };
    if (dot_pos == after_at.len - 1) return .{ .InvalidFormat = "Email domain incomplete" };

    return .{ .Valid = value };
}

pub fn validatePhone(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "Phone" };

    // Remove common separators for validation
    var digit_count: usize = 0;
    for (value) |c| {
        if (std.ascii.isDigit(c)) {
            digit_count += 1;
        } else if (c != ' ' and c != '-' and c != '+' and c != '(' and c != ')') {
            return .{ .InvalidCharacters = "Phone contains invalid characters" };
        }
    }

    if (digit_count < 10) return .{ .TooShort = .{ .min = 10, .field = "Phone (digits)" } };
    if (digit_count > 15) return .{ .TooLong = .{ .max = 15, .field = "Phone (digits)" } };

    return .{ .Valid = value };
}

pub fn validateState(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "State" };

    // Check if state exists in the list
    for (util.PostalCodes.states) |state| {
        if (std.mem.eql(u8, state, value)) {
            return .{ .Valid = value };
        }
    }

    return .{ .DoesNotMatch = "valid Indian state" };
}

pub fn validatePostalCode(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "Postal code" };

    if (value.len != 6) return .{ .InvalidLength = .{ .expected = 6, .field = "Postal code" } };

    for (value) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .InvalidCharacters = "Postal code must contain only digits" };
        }
    }

    const code = std.fmt.parseInt(u32, value, 10) catch {
        return .{ .InvalidFormat = "Invalid postal code format" };
    };

    // Validate against Indian postal code ranges
    // First digit determines region: 1-8
    const first_digit = code / 100000;
    if (first_digit == 0 or first_digit > 8) {
        return .{ .InvalidFormat = "Postal code region invalid (must start with 1-8)" };
    }

    return .{ .Valid = value };
}

pub fn validateHSNCode(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "HSN code" };

    // HSN codes can be 4, 6, or 8 digits
    if (value.len != 4 and value.len != 6 and value.len != 8) {
        return .{ .InvalidFormat = "HSN code must be 4, 6, or 8 digits" };
    }

    for (value) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .InvalidCharacters = "HSN code must contain only digits" };
        }
    }

    return .{ .Valid = value };
}

pub fn validateRequired(value: []const u8, field_name: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = field_name };
    return .{ .Valid = value };
}

pub fn validateQuantity(value: []const u8) ValidationResult(usize) {
    if (value.len == 0) return .{ .Required = "Quantity" };

    const qty = std.fmt.parseInt(usize, value, 10) catch {
        return .{ .InvalidFormat = "Quantity must be a valid whole number" };
    };

    if (qty == 0) {
        return .{ .InvalidFormat = "Quantity must be greater than 0" };
    }

    return .{ .Valid = qty };
}

pub fn validateSaleRate(value: []const u8) ValidationResult(f16) {
    if (value.len == 0) return .{ .Required = "Sale rate" };

    const rate = std.fmt.parseFloat(f16, value) catch {
        return .{ .InvalidFormat = "Sale rate must be a valid number" };
    };

    if (rate <= 0) {
        return .{ .InvalidFormat = "Sale rate must be greater than 0" };
    }

    return .{ .Valid = rate };
}

pub fn validateDiscount(value: []const u8) ValidationResult(f16) {
    if (value.len == 0) return .{ .Valid = 0.0 }; // Default to 0 if empty

    const disc = std.fmt.parseFloat(f16, value) catch {
        return .{ .InvalidFormat = "Discount must be a valid number" };
    };

    if (disc < 0 or disc > 100) {
        return .{ .OutOfRange = .{ .min = 0, .max = 100, .field = "Discount %" } };
    }

    return .{ .Valid = disc };
}

// Cross-field validation for postal code and state
pub fn validatePostalCodeForState(postal_code: []const u8, state: []const u8) ValidationResult([]const u8) {
    const code = std.fmt.parseInt(u32, postal_code, 10) catch {
        return .{ .InvalidFormat = "Invalid postal code format" };
    };

    // Find state index
    var state_idx: ?usize = null;
    for (util.PostalCodes.states, 0..) |s, idx| {
        if (std.mem.eql(u8, s, state)) {
            state_idx = idx;
            break;
        }
    }

    if (state_idx == null) return .{ .DoesNotMatch = "valid state" };

    const min_code = util.PostalCodes.min_codes[state_idx.?];
    const max_code = util.PostalCodes.max_codes[state_idx.?];

    if (code < min_code or code > max_code) {
        return .{ .DoesNotMatch = "selected state" };
    }

    return .{ .Valid = postal_code };
}

// Helper for number validation from textEntryNumber
pub fn validateNumberInRange(comptime T: type, value: T, min: ?T, max: ?T, field_name: []const u8) ValidationResult(T) {
    if (min) |m| {
        if (value < m) {
            const min_f: f32 = switch (@typeInfo(T)) {
                .Int => @floatFromInt(m),
                .Float => @floatCast(m),
                else => 0,
            };
            const max_f: f32 = if (max) |mx| switch (@typeInfo(T)) {
                .Int => @floatFromInt(mx),
                .Float => @floatCast(mx),
                else => 0,
            } else min_f;
            return .{ .OutOfRange = .{ .min = min_f, .max = max_f, .field = field_name } };
        }
    }

    if (max) |m| {
        if (value > m) {
            const min_f: f32 = if (min) |mn| switch (@typeInfo(T)) {
                .Int => @floatFromInt(mn),
                .Float => @floatCast(mn),
                else => 0,
            } else 0;
            const max_f: f32 = switch (@typeInfo(T)) {
                .Int => @floatFromInt(m),
                .Float => @floatCast(m),
                else => 0,
            };
            return .{ .OutOfRange = .{ .min = min_f, .max = max_f, .field = field_name } };
        }
    }

    return .{ .Valid = value };
}
