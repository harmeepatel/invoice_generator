// INFO: AI GENERATED CODE: https://claude.ai/chat/1d02a3b9-1b73-41aa-be67-45fb6cca208d

const std = @import("std");
const log = std.log.scoped(.ae_validate);

const main = @import("main.zig");
const util = @import("util.zig");
const customers = @import("db/customers.zig");
const form_field = @import("components/form_field.zig");

/// Validation result that can indicate which other fields need revalidation
pub const ValidationResult = struct {
    err_msg: ?[]const u8,
    revalidate_fields: []const form_field.FormField.Kind = &[_]form_field.FormField.Kind{},
};

var error_message_buffer: [256]u8 = undefined;

/// Validates name field
/// Rules: 2-100 characters, only letters, spaces, and basic punctuation
fn name(str: []const u8) ValidationResult {
    // Check if empty
    if (str.len == 0) return .{ .err_msg = "Name is required" };

    // Check length
    if (str.len < 2) return .{ .err_msg = "Name too short (min 2 chars)" };
    if (str.len > 100) return .{ .err_msg = "Name too long (max 100 chars)" };

    // Check for valid characters (letters, spaces, hyphens, apostrophes, periods)
    for (str) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or
            c == ' ' or c == '-' or c == '\'' or c == '.';
        if (!is_valid) {
            return .{ .err_msg = "Name contains invalid characters" };
        }
    }

    // Check that it's not just spaces
    var has_letter = false;
    for (str) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .err_msg = "Name must contain letters" };

    return .{ .err_msg = null };
}

/// Validates GSTIN (Goods and Services Tax Identification Number)
/// Format: 24AAAPPPPPPCZZZ
/// - 24: Gujarat state code (fixed)
/// - AAA...: 10-digit PAN (uppercase alphanumeric)
/// - C: Registration number (digit or letter)
/// - Z: Fixed 'Z'
/// - Z: Checksum digit
fn gstin(str: []const u8) ValidationResult {
    // Check if empty
    if (str.len == 0) return .{ .err_msg = "GSTIN is required" };

    // Check exact length
    if (str.len != 15) return .{ .err_msg = "GSTIN must be 15 characters" };

    // Check state code (must be 24 for Gujarat)
    if (str[0] != '2' or str[1] != '4') {
        return .{ .err_msg = "GSTIN must start with 24 (Gujarat)" };
    }

    // Check PAN portion (positions 2-11): should be uppercase alphanumeric
    // PAN format: AAAAA9999A (5 letters, 4 digits, 1 letter)
    for (str[2..7]) |c| {
        if (!std.ascii.isUpper(c)) {
            return .{ .err_msg = "Invalid PAN format in GSTIN" };
        }
    }

    for (str[7..11]) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .err_msg = "Invalid PAN format in GSTIN" };
        }
    }

    if (!std.ascii.isUpper(str[11])) {
        return .{ .err_msg = "Invalid PAN format in GSTIN" };
    }

    // Check 13th character (entity registration number)
    const reg_char = str[12];
    const is_valid_reg = std.ascii.isDigit(reg_char) or std.ascii.isUpper(reg_char);
    if (!is_valid_reg) {
        return .{ .err_msg = "Invalid registration number in GSTIN" };
    }

    // Check 14th character (must be 'Z')
    if (str[13] != 'Z') {
        return .{ .err_msg = "14th character must be 'Z'" };
    }

    // Check 15th character (checksum - must be alphanumeric)
    const checksum = str[14];
    const is_valid_checksum = std.ascii.isDigit(checksum) or std.ascii.isUpper(checksum);
    if (!is_valid_checksum) {
        return .{ .err_msg = "Invalid checksum in GSTIN" };
    }

    return .{ .err_msg = null };
}

/// Validates email address
/// Basic format: username@domain.tld
fn email(str: []const u8) ValidationResult {
    // Check if empty
    if (str.len == 0) return .{ .err_msg = "Email is required" };

    // Check length
    if (str.len < 5) return .{ .err_msg = "Email too short" };
    if (str.len > 254) return .{ .err_msg = "Email too long (max 254 chars)" };

    // Find @ symbol
    const at_index = std.mem.indexOfScalar(u8, str, '@') orelse {
        return .{ .err_msg = "Email must contain @" };
    };

    // Check that @ is not at start or end
    if (at_index == 0) return .{ .err_msg = "@ cannot be at start" };
    if (at_index == str.len - 1) return .{ .err_msg = "@ cannot be at end" };

    // Check for multiple @ symbols
    const second_at = std.mem.indexOfScalarPos(u8, str, at_index + 1, '@');
    if (second_at != null) return .{ .err_msg = "Email cannot contain multiple @" };

    const local_part = str[0..at_index];
    const domain_part = str[at_index + 1 ..];

    // Validate local part (before @)
    if (local_part.len == 0) return .{ .err_msg = "Email username cannot be empty" };
    if (local_part.len > 64) return .{ .err_msg = "Email username too long" };

    // Check for at least one dot in domain
    const dot_index = std.mem.indexOfScalar(u8, domain_part, '.') orelse {
        return .{ .err_msg = "Domain must contain a dot" };
    };

    // Check that domain has content before and after the dot
    if (dot_index == 0) return .{ .err_msg = "Invalid domain format" };
    if (dot_index == domain_part.len - 1) return .{ .err_msg = "Invalid domain format" };

    // Basic character validation
    for (local_part) |c| {
        const is_valid = std.ascii.isAlphanumeric(c) or
            c == '.' or c == '_' or c == '-' or c == '+';
        if (!is_valid) {
            return .{ .err_msg = "Invalid characters in email" };
        }
    }

    for (domain_part) |c| {
        const is_valid = std.ascii.isAlphanumeric(c) or c == '.' or c == '-';
        if (!is_valid) {
            return .{ .err_msg = "Invalid characters in domain" };
        }
    }

    return .{ .err_msg = null };
}

/// Validates Indian phone number
/// Formats accepted:
/// - 10 digits: 9876543210
/// - With +91: +919876543210 or +91 9876543210
/// - With 0: 09876543210
fn phone(str: []const u8) ValidationResult {
    // Check if empty
    if (str.len == 0) return .{ .err_msg = "Phone number is required" };

    // Remove spaces and common separators for validation
    var digit_count: usize = 0;
    var has_plus = false;
    var has_country_code = false;
    var first_digit_found = false;
    var first_digit: u8 = 0;

    for (str) |c| {
        if (std.ascii.isDigit(c)) {
            digit_count += 1;
            if (!first_digit_found) {
                first_digit = c;
                first_digit_found = true;
            }
        } else if (c == '+') {
            if (has_plus) return .{ .err_msg = "Multiple + symbols not allowed" };
            has_plus = true;
        } else if (c == ' ' or c == '-' or c == '(' or c == ')') {
            // Allow these separators
            continue;
        } else {
            return .{ .err_msg = "Invalid characters in phone number" };
        }
    }

    // Check if starts with +91
    if (has_plus) {
        if (str.len < 3 or str[0] != '+' or str[1] != '9' or str[2] != '1') {
            return .{ .err_msg = "Country code must be +91" };
        }
        has_country_code = true;
    }

    // Determine expected digit count
    // const expected_digits: usize = if (has_country_code) 12 else 10; // +91 adds 2 more digits

    if (digit_count < 10) return .{ .err_msg = "Phone number too short" };
    if (digit_count > 12) return .{ .err_msg = "Phone number too long" };

    // Indian mobile numbers start with 6, 7, 8, or 9
    // If there's a country code, we need to skip 91 and check the next digit
    if (has_country_code) {
        // After +91, the first digit should be 6, 7, 8, or 9
        var actual_first: u8 = 0;
        var found_after_code = false;
        var nine_one_count: u8 = 0;

        for (str) |c| {
            if (std.ascii.isDigit(c)) {
                if (c == '9' or c == '1') {
                    nine_one_count += 1;
                    if (nine_one_count > 2) {
                        actual_first = c;
                        found_after_code = true;
                        break;
                    }
                } else {
                    actual_first = c;
                    found_after_code = true;
                    break;
                }
            }
        }

        if (found_after_code) {
            if (actual_first < '6' or actual_first > '9') {
                return .{ .err_msg = "Mobile number must start with 6-9" };
            }
        }
    } else {
        // Without country code, check first actual digit (skip leading 0 if present)
        var check_digit = first_digit;
        if (first_digit == '0' and digit_count == 11) {
            // Skip the leading 0
            var skip_zero = false;
            for (str) |c| {
                if (std.ascii.isDigit(c)) {
                    if (c == '0' and !skip_zero) {
                        skip_zero = true;
                        continue;
                    }
                    check_digit = c;
                    break;
                }
            }
        }

        if (check_digit < '6' or check_digit > '9') {
            return .{ .err_msg = "Mobile number must start with 6-9" };
        }
    }

    return .{ .err_msg = null };
}

/// Validates remarks field
/// Rules: 2-256 characters, only letters, spaces, and basic punctuation
fn remark(str: []const u8) ValidationResult {
    // Check if empty
    if (str.len == 0) return .{ .err_msg = "Remark is required" };

    // Check length
    if (str.len < 2) return .{ .err_msg = "Remark too short (min 2 chars)" };
    if (str.len > 256) return .{ .err_msg = "Remark too long (max 256 chars)" };

    // Check for valid characters (letters, spaces, hyphens, apostrophes, periods)
    for (str) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or
            c == ' ' or c == '-' or c == '\'' or c == '.';
        if (!is_valid) {
            return .{ .err_msg = "Remark contains invalid characters" };
        }
    }

    // Check that it's not just spaces
    var has_letter = false;
    for (str) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .err_msg = "Remark must contain letters" };

    return .{ .err_msg = null };
}

/// Validates shop/building number
fn shopNo(str: []const u8) ValidationResult {
    if (str.len == 0) return .{ .err_msg = "Shop/Building is required" };
    if (str.len > 100) return .{ .err_msg = "Shop/Building too long (max 100)" };

    var has_content = false;
    for (str) |c| {
        if (c != ' ' and c != '\t') {
            has_content = true;
            break;
        }
    }
    if (!has_content) return .{ .err_msg = "Shop/Building cannot be empty" };

    return .{ .err_msg = null };
}

/// Validates address line 1
fn line1(str: []const u8) ValidationResult {
    if (str.len == 0) return .{ .err_msg = "Address line 1 is required" };
    if (str.len < 3) return .{ .err_msg = "Address too short (min 3 chars)" };
    if (str.len > 200) return .{ .err_msg = "Address too long (max 200)" };

    var has_letter = false;
    for (str) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .err_msg = "Address must contain letters" };

    return .{ .err_msg = null };
}

/// Validates optional address line 2
fn line2(str: []const u8) ValidationResult {
    if (str.len > 200) return .{ .err_msg = "Address too long (max 200)" };
    return .{ .err_msg = null };
}

/// Validates optional address line 3
fn line3(str: []const u8) ValidationResult {
    if (str.len > 200) return .{ .err_msg = "Address too long (max 200)" };
    return .{ .err_msg = null };
}

/// Validates city name
fn city(str: []const u8) ValidationResult {
    if (str.len == 0) return .{ .err_msg = "City is required" };
    if (str.len < 2) return .{ .err_msg = "City too short (min 2 chars)" };
    if (str.len > 50) return .{ .err_msg = "City too long (max 50 chars)" };

    for (str) |c| {
        const is_valid = std.ascii.isAlphabetic(c) or c == ' ' or c == '-';
        if (!is_valid) {
            return .{ .err_msg = "City contains invalid characters" };
        }
    }

    var has_letter = false;
    for (str) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }
    if (!has_letter) return .{ .err_msg = "City must contain letters" };

    return .{ .err_msg = null };
}

fn state(str: []const u8) ValidationResult {
    for (util.PostalCodes.states) |s| {
        var state_buf: [64]u8 = undefined;
        var str_buf: [64]u8 = undefined;

        const state_lower = std.ascii.lowerString(&state_buf, s);
        const str_lower = std.ascii.lowerString(&str_buf, str);

        if (std.mem.eql(u8, state_lower, str_lower)) {
            return .{ .err_msg = null, .revalidate_fields = &[_]form_field.FormField.Kind{.postal_code} };
        }
    }

    return .{ .err_msg = "Foreign State" };
}

/// Validates postal code (requires state for accurate validation)
fn postalCode(str: []const u8, state_name: []const u8) ValidationResult {
    const postal_code = blk: {
        if (str.len > 0) {
            break :blk std.fmt.parseInt(u32, str, 10) catch {
                return .{ .err_msg = "Cannot convert string to int" };
            };
        } else {
            break :blk 0;
        }
    };
    if (str.len == 0) return .{ .err_msg = "Postal code is required" };
    if (str.len != 6) return .{ .err_msg = "Postal code must be 6 digits" };

    for (str) |c| {
        if (!std.ascii.isDigit(c)) {
            return .{ .err_msg = "Postal code must be digits only" };
        }
    }

    // If no state provided, just validate format
    if (state_name.len == 0) {
        return .{ .err_msg = null };
    }

    // Convert state name to lowercase
    var state_buf: [64]u8 = undefined;
    const state_lower = std.ascii.lowerString(&state_buf, state_name);

    // Find the state in postal_ranges
    const states = util.PostalCodes.states;
    const min_postal_code = util.PostalCodes.min_codes;
    const max_postal_code = util.PostalCodes.max_codes;
    for (0..util.PostalCodes.count) |idx| {
        var range_state_buf: [64]u8 = undefined;
        const range_state_lower = std.ascii.lowerString(&range_state_buf, states[idx]);
        if (std.mem.eql(u8, range_state_lower, state_lower)) {
            if (postal_code >= min_postal_code[idx] and postal_code <= max_postal_code[idx]) {
                return .{ .err_msg = null }; // Valid
            }

            const msg = std.fmt.bufPrint(
                &error_message_buffer,
                "Out of range [{d}-{d}]",
                .{ min_postal_code[idx], max_postal_code[idx] },
            ) catch {
                return .{ .err_msg = "Cannot generate error message" };
            };

            return .{ .err_msg = error_message_buffer[0..msg.len] };
        }
    }

    return .{ .err_msg = null }; // State not found in ranges, allow it
}

/// Main validation function
pub fn validate(kind: form_field.FormField.Kind, value: []const u8, customer: customers.Customer) ValidationResult {
    return switch (kind) {
        .name => name(value),
        .gstin => gstin(value),
        .email => email(value),
        .phone => phone(value),
        .remark => remark(value),
        .shop_no => shopNo(value),
        .line_1 => line1(value),
        .line_2 => line2(value),
        .line_3 => line3(value),
        .city => city(value),
        .state => state(value),
        .postal_code => postalCode(value, customer.address.state),
    };
}
