use crate::states::states;

fn contains_invalid_char(s: &str) -> Option<String> {
    for c in s.chars() {
        if !c.is_alphanumeric() && !c.is_whitespace() && !"/-(),.'&".contains(c) {
            return Some(format!("Invalid character: '{}'", c));
        }
    }
    None
}

fn is_all_digits(s: &str) -> bool {
    !s.is_empty() && s.chars().all(|c| c.is_ascii_digit())
}

fn is_all_letters(s: &str) -> bool {
    !s.is_empty() && s.chars().all(|c| c.is_alphabetic() || c.is_whitespace())
}

// --- customer ---

pub fn name(val: &str) -> Option<String> {
    let s = val.trim().to_uppercase();
    match s.len() {
        0 => Some("Required".into()),
        1..=2 => Some("Too short".into()),
        101.. => Some("Must be 100 characters or fewer".into()),
        _ => contains_invalid_char(&s),
    }
}

pub fn company_name(val: &str) -> Option<String> {
    name(val)
}

pub fn igst(val: &str) -> Option<String> {
    match val.trim().parse::<f64>() {
        Ok(v) if v >= 0.0 && v <= 40.0 => None,
        Ok(_) => Some("Must be 0% - 40%".into()),
        Err(_) => Some("Must be 0% - 40%".into()),
    }
}

pub fn gstin(val: &str) -> Option<String> {
    let s = val.trim().to_uppercase();

    let validate_pan = |pan: &str| -> Option<String> {
        match pan.len() {
            0 => return Some("Required".into()),
            n if n != 10 => return Some("PAN must be exactly 10 characters".into()),
            _ => {}
        }
        let chars: Vec<char> = pan.chars().collect();
        if !chars[..5].iter().all(|c| c.is_ascii_uppercase()) {
            return Some("First 5 characters of PAN must be alphabetic".into());
        }
        if !"PCFHATGLJ".contains(chars[3]) {
            return Some("Invalid 4th character [P, C, F, H, A, T, G, L, J]".into());
        }
        if !chars[5..9].iter().all(|c| c.is_ascii_digit()) {
            return Some("Characters 7–10 must be numeric".into());
        }
        if &pan[5..9] == "0000" {
            return Some("Numeric portion must be between 0001 and 9999".into());
        }
        if !chars[9].is_ascii_uppercase() {
            return Some("Last character must be alphabetic".into());
        }
        None
    };

    let chars: Vec<char> = s.chars().collect();
    match s.len() {
        0 => return Some("Required".into()),
        n if n != 15 => return Some("GSTIN must be 15 characters".into()),
        _ => {}
    }
    if !chars[0].is_ascii_digit() || !chars[1].is_ascii_digit() {
        return Some("GSTIN has an invalid state code".into());
    }
    if let Some(e) = validate_pan(&s[2..12]) {
        return Some(e);
    }
    if !chars[12].is_ascii_digit() && !chars[12].is_ascii_uppercase() {
        return Some("GSTIN has an invalid registration number".into());
    }
    if chars[13] != 'Z' {
        return Some("GSTIN has an invalid format".into());
    }
    if !chars[14].is_ascii_alphanumeric() {
        return Some("GSTIN has an invalid last character".into());
    }
    None
}

pub fn email(val: &str) -> Option<String> {
    if val.is_empty() {
        return None; // optional field
    }
    // basic RFC check: must have exactly one @, with content on both sides
    let parts: Vec<&str> = val.splitn(2, '@').collect();
    if parts.len() != 2
        || parts[0].is_empty()
        || !parts[1].contains('.')
        || parts[1].starts_with('.')
    {
        return Some("Invalid email".into());
    }
    None
}

pub fn phone(val: &str) -> Option<String> {
    // strip spaces for length check
    let s: String = val.chars().filter(|c| !c.is_whitespace()).collect();
    match s.len() {
        0 => Some("Required".into()),
        _ if !is_all_digits(&s) => Some("Letters not allowed".into()),
        n if n > 10 => Some("Must be exactly 10 digits".into()),
        _ => match s.chars().next().unwrap() {
            '6'..='9' => None,
            _ => Some("Should start with 6 - 9".into()),
        },
    }
}

pub fn remark(val: &str) -> Option<String> {
    if val.is_empty() {
        return None; // optional field
    }
    match val.len() {
        1..=2 => Some("Too short".into()),
        101.. => Some("Must be 100 characters or fewer".into()),
        _ => contains_invalid_char(val),
    }
}

pub fn shop_no(val: &str) -> Option<String> {
    let s = val.trim().to_uppercase();
    match s.len() {
        0 => Some("Required".into()),
        1..=2 => Some("Too short".into()),
        9.. => Some("Must be 8 characters or fewer".into()),
        _ => contains_invalid_char(&s),
    }
}

pub fn line(val: &str, required: bool) -> Option<String> {
    if !required && val.is_empty() {
        return None;
    }
    match val.len() {
        0 if required => Some("Required".into()),
        1..=2 => Some("Too short".into()),
        101.. => Some("Must be 100 characters or fewer".into()),
        _ => contains_invalid_char(val),
    }
}

pub fn city(val: &str) -> Option<String> {
    match val.len() {
        0 => Some("Required".into()),
        1..=2 => Some("Too short".into()),
        33.. => Some("Too long".into()),
        _ if !is_all_letters(val) => Some("Digits not allowed".into()),
        _ => contains_invalid_char(val),
    }
}

pub fn postal_code(state: &str, val: &str) -> Option<String> {
    let pc: u32 = match val.trim().parse() {
        Ok(n) => n,
        Err(_) => return Some("Required".into()),
    };
    if pc == 0 {
        return Some("Required".into());
    }
    let state_map = states();
    if let Some(info) = state_map.get(state) {
        if pc < info.min_code || pc > info.max_code {
            return Some(format!(
                "Out of range [{} - {}]",
                info.min_code, info.max_code
            ));
        }
    }
    None
}

// --- product ---

pub fn serial_number(val: &str) -> Option<String> {
    if val.is_empty() {
        Some("Required".into())
    } else {
        None
    }
}

pub fn product_name(val: &str) -> Option<String> {
    if val.is_empty() {
        Some("Required".into())
    } else {
        None
    }
}

pub fn hsn(val: &str) -> Option<String> {
    match val.len() {
        0 => Some("Required".into()),
        n if n != 2 && n != 4 && n != 6 && n != 8 => Some("Must be 2, 4, 6, or 8 digits".into()),
        _ if !is_all_digits(val) => Some("Letters not allowed".into()),
        _ => None,
    }
}

pub fn gst(val: &str) -> Option<String> {
    match val.trim().parse::<f64>() {
        Ok(v) if v >= 0.0 && v <= 40.0 => None,
        _ => Some("Must be 0% - 40%".into()),
    }
}

pub fn quantity(val: &str) -> Option<String> {
    match val.trim().parse::<i64>() {
        Ok(n) if n > 0 => None,
        _ => Some("Required".into()),
    }
}

pub fn rate(val: &str) -> Option<String> {
    match val.trim().parse::<f64>() {
        Ok(v) if v > 0.0 => None,
        _ => Some("Invalid".into()),
    }
}

pub fn discount(val: &str) -> Option<String> {
    match val.trim().parse::<f64>() {
        Ok(v) if v >= 0.0 && v <= 100.0 => None,
        _ => Some("Invalid".into()),
    }
}
