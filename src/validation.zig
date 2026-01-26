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
    };
}

pub fn validateName(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "Name" };
    if (value.len < 2) return .{ .TooShort = .{ .min = 2, .field = "Name" } };
    if (value.len > 100) return .{ .TooLong = .{ .max = 100, .field = "Name" } };

    // Check for valid characters (letters, spaces, hyphens, apostrophes, periods)
    for (value) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or
            c == ' ' or c == '-' or c == '\'' or c == '.';
        if (!is_valid) {
            return .{ .InvalidCharacters = "Name contains invalid characters" };
        }
    }

    // Check that it's not just spaces
    var has_letter = false;
    for (value) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .InvalidFormat = "Name must contain letters" };

    return .{ .Valid = value };
}

pub fn validateGSTIN(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "GSTIN" };
    if (value.len != 15) return .{ .InvalidLength = .{ .expected = 15, .field = "GSTIN" } };

    // Validate state code (first 2 digits)
    if (!std.ascii.isDigit(value[0]) or !std.ascii.isDigit(value[1])) {
        return .{ .InvalidFormat = "GSTIN must start with 2-digit state code" };
    }

    // Validate PAN portion (positions 2-11): AAAAA9999A
    for (value[2..7]) |c| {
        if (!std.ascii.isUpper(c)) {
            return .{ .InvalidFormat = "Invalid PAN format in GSTIN" };
        }
    }

    for (value[7..11]) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .InvalidFormat = "Invalid PAN format in GSTIN" };
        }
    }

    if (!std.ascii.isUpper(value[11])) {
        return .{ .InvalidFormat = "Invalid PAN format in GSTIN" };
    }

    // Validate entity code (position 12)
    const entity_code = value[12];
    if (!std.ascii.isDigit(entity_code) and !std.ascii.isUpper(entity_code)) {
        return .{ .InvalidFormat = "Invalid registration number in GSTIN" };
    }

    // Validate 13th character (must be 'Z')
    if (value[13] != 'Z') {
        return .{ .InvalidFormat = "13th character must be 'Z'" };
    }

    // Validate checksum (position 14)
    const checksum = value[14];
    if (!std.ascii.isAlphanumeric(checksum)) {
        return .{ .InvalidFormat = "Invalid checksum in GSTIN" };
    }

    return .{ .Valid = value };
}

pub fn validateEmail(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Empty; // Optional field

    if (value.len < 5) return .{ .TooShort = .{ .min = 5, .field = "Email" } };
    if (value.len > 254) return .{ .TooLong = .{ .max = 254, .field = "Email" } };

    // Find @ symbol
    const at_pos = std.mem.indexOf(u8, value, "@") orelse {
        return .{ .InvalidFormat = "Email must contain @" };
    };

    if (at_pos == 0) return .{ .InvalidFormat = "Email cannot start with @" };
    if (at_pos == value.len - 1) return .{ .InvalidFormat = "Email cannot end with @" };

    // Check for multiple @ symbols
    const second_at = std.mem.indexOfPos(u8, value, at_pos + 1, "@");
    if (second_at != null) return .{ .InvalidFormat = "Email cannot contain multiple @" };

    const local_part = value[0..at_pos];
    const domain_part = value[at_pos + 1 ..];

    // Validate local part
    if (local_part.len > 64) return .{ .TooLong = .{ .max = 64, .field = "Email username" } };

    // Validate domain part
    const dot_pos = std.mem.indexOf(u8, domain_part, ".") orelse {
        return .{ .InvalidFormat = "Email must contain domain extension" };
    };

    if (dot_pos == 0) return .{ .InvalidFormat = "Invalid email domain format" };
    if (dot_pos == domain_part.len - 1) return .{ .InvalidFormat = "Email domain incomplete" };

    // Validate characters in local part
    for (local_part) |c| {
        const is_valid = std.ascii.isAlphanumeric(c) or
            c == '.' or c == '_' or c == '-' or c == '+';
        if (!is_valid) {
            return .{ .InvalidCharacters = "Email contains invalid characters" };
        }
    }

    // Validate characters in domain
    for (domain_part) |c| {
        const is_valid = std.ascii.isAlphanumeric(c) or c == '.' or c == '-';
        if (!is_valid) {
            return .{ .InvalidCharacters = "Email domain contains invalid characters" };
        }
    }

    return .{ .Valid = value };
}

pub fn validatePhone(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "Phone" };

    var digit_count: usize = 0;
    var has_plus = false;

    for (value) |c| {
        if (std.ascii.isDigit(c)) {
            digit_count += 1;
        } else if (c == '+') {
            if (has_plus) return .{ .InvalidFormat = "Multiple + symbols not allowed" };
            has_plus = true;
        } else if (c != ' ' and c != '-' and c != '(' and c != ')') {
            return .{ .InvalidCharacters = "Phone contains invalid characters" };
        }
    }

    if (digit_count < 10) return .{ .TooShort = .{ .min = 10, .field = "Phone (digits)" } };
    if (digit_count > 15) return .{ .TooLong = .{ .max = 15, .field = "Phone (digits)" } };

    // Validate country code if present
    if (has_plus) {
        if (value.len < 3 or value[0] != '+' or value[1] != '9' or value[2] != '1') {
            return .{ .InvalidFormat = "Country code must be +91" };
        }
    }

    // For Indian numbers, first digit (after country code) should be 6-9
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
                // First actual digit should be 6-9 for mobile, or handle landline (2-5)
                if (c < '6' or c > '9') {
                    return .{ .InvalidFormat = "Mobile number must start with 6-9" };
                }
            }
        }
    }

    return .{ .Valid = value };
}

pub fn validateRemark(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .Empty; // Optional field

    if (value.len < 2) return .{ .TooShort = .{ .min = 2, .field = "Remark" } };
    if (value.len > 256) return .{ .TooLong = .{ .max = 256, .field = "Remark" } };

    for (value) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or std.ascii.isDigit(c) or
            c == ' ' or c == '-' or c == '\'' or c == '.' or c == ',' or c == '/' or c == ':';
        if (!is_valid) {
            return .{ .InvalidCharacters = "Remark contains invalid characters" };
        }
    }

    // Check that it's not just spaces
    var has_content = false;
    for (value) |c| {
        if (c != ' ') {
            has_content = true;
            break;
        }
    }
    if (!has_content) return .{ .InvalidFormat = "Remark must contain text" };

    return .{ .Valid = value };
}

pub fn validateShopNo(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "Shop Number" };
    if (value.len > 100) return .{ .TooLong = .{ .max = 100, .field = "Shop Number" } };

    var has_content = false;
    for (value) |c| {
        if (c != ' ' and c != '\t') {
            has_content = true;
            break;
        }
    }
    if (!has_content) return .{ .InvalidFormat = "Shop Number cannot be empty" };

    return .{ .Valid = value };
}

pub fn validateLine(value: []const u8, optional: bool) ValidationResult([]const u8) {
    if (value.len == 0) {
        if (optional) return .Empty;
        return .{ .Required = "Address line required" };
    }

    if (optional) {
        if (value.len > 200) return .{ .TooLong = .{ .max = 200, .field = "Address line" } };
        return .{ .Valid = value };
    }

    if (value.len < 3) return .{ .TooShort = .{ .min = 3, .field = "Address line" } };
    if (value.len > 200) return .{ .TooLong = .{ .max = 200, .field = "Address line" } };

    var has_letter = false;
    for (value) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .InvalidFormat = "Address must contain letters" };

    return .{ .Valid = value };
}

pub fn validateCity(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "City" };
    if (value.len < 2) return .{ .TooShort = .{ .min = 2, .field = "City" } };
    if (value.len > 50) return .{ .TooLong = .{ .max = 50, .field = "City" } };

    for (value) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or c == ' ' or c == '-';
        if (!is_valid) {
            return .{ .InvalidCharacters = "City contains invalid characters" };
        }
    }

    var has_letter = false;
    for (value) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .InvalidFormat = "City must contain letters" };

    return .{ .Valid = value };
}

pub fn validateState(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "State" };

    // Case-insensitive state matching
    var value_buf: [64]u8 = undefined;
    const value_lower = std.ascii.lowerString(&value_buf, value);

    for (util.PostalCodes.states) |state| {
        var state_buf: [64]u8 = undefined;
        const state_lower = std.ascii.lowerString(&state_buf, state);

        if (std.mem.eql(u8, state_lower, value_lower)) {
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

    // Validate first digit is 1-8 (Indian postal code regions)
    const first_digit = code / 100000;
    if (first_digit == 0 or first_digit > 8) {
        return .{ .InvalidFormat = "Postal code region invalid (must start with 1-8)" };
    }

    return .{ .Valid = value };
}

pub fn validatePostalCodeForState(postal_code: []const u8, state: []const u8) ValidationResult([]const u8) {
    // First validate postal code format
    const format_result = validatePostalCode(postal_code);
    if (!format_result.isValid()) return format_result;

    const code = std.fmt.parseInt(u32, postal_code, 10) catch {
        return .{ .InvalidFormat = "Invalid postal code format" };
    };

    // Find state index (case-insensitive)
    var state_buf: [64]u8 = undefined;
    const state_lower = std.ascii.lowerString(&state_buf, state);

    var state_idx: ?usize = null;
    for (util.PostalCodes.states, 0..) |s, idx| {
        var s_buf: [64]u8 = undefined;
        const s_lower = std.ascii.lowerString(&s_buf, s);
        if (std.mem.eql(u8, s_lower, state_lower)) {
            state_idx = idx;
            break;
        }
    }

    if (state_idx == null) return .{ .DoesNotMatch = "valid state" };

    const min_code = util.PostalCodes.min_codes[state_idx.?];
    const max_code = util.PostalCodes.max_codes[state_idx.?];

    if (code < min_code or code > max_code) {
        return .{ .DoesNotMatch = "postal code range for selected state" };
    }

    return .{ .Valid = postal_code };
}

pub fn validateHSNCode(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "HSN code" };

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

pub fn validateItemName(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "Item name" };
    if (value.len < 2) return .{ .TooShort = .{ .min = 2, .field = "Item name" } };
    if (value.len > 100) return .{ .TooLong = .{ .max = 100, .field = "Item name" } };

    var has_letter = false;
    for (value) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .InvalidFormat = "Item name must contain letters" };

    return .{ .Valid = value };
}

pub fn validateSerialNumber(value: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = "Serial number" };
    if (value.len > 50) return .{ .TooLong = .{ .max = 50, .field = "Serial number" } };

    var has_content = false;
    for (value) |c| {
        if (c != ' ' and c != '\t') {
            has_content = true;
            break;
        }
    }
    if (!has_content) return .{ .InvalidFormat = "Serial number cannot be empty" };

    return .{ .Valid = value };
}

pub fn validateQuantity(value: []const u8) ValidationResult(usize) {
    if (value.len == 0) return .{ .Required = "Quantity" };

    const qty = std.fmt.parseInt(usize, value, 10) catch {
        return .{ .InvalidFormat = "Quantity must be a valid whole number" };
    };

    if (qty == 0) return .{ .InvalidFormat = "Quantity must be greater than 0" };

    return .{ .Valid = qty };
}

pub fn validateSaleRate(value: []const u8) ValidationResult(f16) {
    if (value.len == 0) return .{ .Required = "Sale rate" };

    const rate = std.fmt.parseFloat(f16, value) catch {
        return .{ .InvalidFormat = "Sale rate must be a valid number" };
    };

    if (rate <= 0) return .{ .InvalidFormat = "Sale rate must be greater than 0" };

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

pub fn validateGST(value: []const u8) ValidationResult(f16) {
    if (value.len == 0) return .{ .Required = "GST %" };

    const gst_val = std.fmt.parseFloat(f16, value) catch {
        return .{ .InvalidFormat = "GST % must be a valid number" };
    };

    if (gst_val < 0 or gst_val > 28) {
        return .{ .OutOfRange = .{ .min = 0, .max = 28, .field = "GST %" } };
    }

    // Validate against standard Indian GST rates
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

pub fn validateRequired(value: []const u8, field_name: []const u8) ValidationResult([]const u8) {
    if (value.len == 0) return .{ .Required = field_name };
    return .{ .Valid = value };
}
