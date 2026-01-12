// AI: https://claude.ai/chat/9305592c-c47e-4ee3-9083-93e859bbd666
const std = @import("std");
const log = std.log.scoped(.ae_validate_item);

/// Validates serial number
/// Rules: 1-50 characters, alphanumeric and basic separators
fn serialNumber(str: []const u8) bool {
    if (str.len == 0) return false;
    if (str.len > 50) return false;

    for (str) |c| {
        const is_valid = std.ascii.isAlphanumeric(c) or c == '-' or c == '_' or c == '/' or c == ' ';
        if (!is_valid) return false;
    }

    var has_content = false;
    for (str) |c| {
        if (std.ascii.isAlphanumeric(c)) {
            has_content = true;
            break;
        }
    }
    if (!has_content) return false;

    return true;
}

/// Validates item name
/// Rules: 2-100 characters, letters, numbers, and basic punctuation
fn itemName(str: []const u8) bool {
    if (str.len == 0) return false;
    if (str.len < 2 or str.len > 100) return false;

    // Check for valid characters
    for (str) |c| {
        const is_valid = std.ascii.isAlphanumeric(c) or
            c == ' ' or c == '-' or c == '/' or c == '(' or c == ')' or c == '.' or c == ',';
        if (!is_valid) return false;
    }

    // Must have at least one letter
    var has_letter = false;
    for (str) |c| {
        if (std.ascii.isAlphabetic(c)) {
            has_letter = true;
            break;
        }
    }

    return has_letter;
}

/// Validates HSN Code (Harmonized System of Nomenclature)
/// Rules: 4, 6, or 8 digits
fn hsnCode(str: []const u8) bool {
    if (str.len == 0) return false;

    // HSN codes can be 4, 6, or 8 digits
    if (str.len != 4 and str.len != 6 and str.len != 8) {
        return false;
    }

    // Must be all digits
    for (str) |c| {
        if (!std.ascii.isDigit(c)) {
            return false;
        }
    }

    return true;
}

/// Validates quantity
/// Rules: Positive integer, max 999999
fn quantity(str: []const u8) bool {
    if (str.len == 0) return false;

    // Parse as integer
    const qty = std.fmt.parseInt(u32, str, 10) catch return false;

    if (qty == 0) return false;
    if (qty > 999999) return false;

    return true;
}

/// Validates sale rate
/// Rules: Positive number with up to 2 decimal places, max 9999999.99
fn saleRate(str: []const u8) bool {
    if (str.len == 0) return false;

    const rate = std.fmt.parseFloat(f64, str) catch {
        return false;
    };

    if (rate <= 0) return false;
    if (rate > 9999999.99) return false;

    // Check decimal places
    if (std.mem.indexOf(u8, str, ".")) |dot_idx| {
        const decimal_part = str[dot_idx + 1 ..];
        if (decimal_part.len > 2) {
            return false;
        }
    }

    return true;
}

/// Validates discount percentage
/// Rules: 0-100, up to 2 decimal places
fn discountPercent(str: []const u8) bool {
    // Discount is optional, empty is valid (means 0%)
    if (str.len == 0) return true;

    const discount = std.fmt.parseFloat(f64, str) catch {
        return false;
    };

    if (discount < 0 or discount > 100) return false;

    // Check decimal places
    if (std.mem.indexOf(u8, str, ".")) |dot_idx| {
        const decimal_part = str[dot_idx + 1 ..];
        if (decimal_part.len > 2) {
            return false;
        }
    }

    return true;
}

/// Validates GST percentage
/// Rules: Must be one of the standard GST rates in India: 0, 0.25, 3, 5, 12, 18, 28
fn gst(str: []const u8) bool {
    if (str.len == 0) return false;

    const gst_rate = std.fmt.parseFloat(f64, str) catch return false;

    // Valid GST rates in India
    const valid_rates = [_]f64{ 0, 0.25, 3, 5, 12, 18, 28 };

    for (valid_rates) |rate| {
        if (@abs(gst_rate - rate) < 0.001) {
            return true;
        }
    }

    return false;
}

/// Validates total tax
/// Rules: Non-negative number, up to 2 decimal places
fn totalTax(str: []const u8) bool {
    if (str.len == 0) return true; // Can be empty if auto-calculated

    const tax = std.fmt.parseFloat(f64, str) catch return false;

    if (tax < 0) return false;
    if (tax > 99999999.99) return false;

    // Check decimal places
    if (std.mem.indexOf(u8, str, ".")) |dot_idx| {
        const decimal_part = str[dot_idx + 1 ..];
        if (decimal_part.len > 2) return false;
    }

    return true;
}

/// Validates amount (typically auto-calculated as Quantity * Sale Rate - Discount + Tax)
/// Rules: Non-negative number, up to 2 decimal places
fn amount(str: []const u8) bool {
    // Amount is typically auto-calculated, but validate if manually entered
    if (str.len == 0) return true; // Can be empty if auto-calculated

    const amt = std.fmt.parseFloat(f64, str) catch {
        return false;
    };

    if (amt < 0) return false;
    if (amt > 99999999.99) return false;

    // Check decimal places
    if (std.mem.indexOf(u8, str, ".")) |dot_idx| {
        const decimal_part = str[dot_idx + 1 ..];
        if (decimal_part.len > 2) {
            return false;
        }
    }

    return true;
}

/// Main validation function - returns true if valid, false if error
pub fn validate(kind: anytype, value: []const u8) bool {
    return switch (kind) {
        .serial_number => serialNumber(value),
        .item_name => itemName(value),
        .hsn_code => hsnCode(value),
        .quantity => quantity(value),
        .sale_rate => saleRate(value),
        .discount => discountPercent(value),
        .gst => gst(value),
        .total_tax => totalTax(value),
        .amount => amount(value),
    };
}
