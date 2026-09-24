const enum_script = @import("../core/enums.zig");
const constant_script = @import("../core/language_constants.zig");
const token_script = @import("../core/token.zig");

const TokenType = enum_script.TokenType;

fn twoSliceAreTheSame(first_slice: []const u8, second_slice: []const u8) bool {
    const FIRST_SLICE_LEN: usize = first_slice.len;
    const SECOND_SLICE_LEN: usize = second_slice.len;

    if (FIRST_SLICE_LEN != SECOND_SLICE_LEN) {
        return false;
    }

    for (0..FIRST_SLICE_LEN) |index| {
        if (first_slice[index] != second_slice[index]) {
            return false;
        }
    } else return true;
}

fn contains(slice: []const u8, char: u8) bool {
    const LENGTH = slice.len;

    if (LENGTH == 0) {
        return false;
    }

    for (0..LENGTH) |index| {
        if (slice[index] == char) {
            return true;
        }
    }
    return false;
}

pub fn getTokenType(input: []const u8) TokenType {
    for (token_script.TokenPairs) |token| {
        if (twoSliceAreTheSame(input, token.lexem)) {
            return token.TokenType;
        }
    }

    if (isInteger(input)) return TokenType.IntegerValue;
    if (isDecimal(input)) return TokenType.DecimalValue;

    if (contains(input, '"')) return TokenType.StringValue;
    if (contains(input, '\'')) return TokenType.CharValue;

    return TokenType.Identifier;
}

pub fn isOperator(char: u8) bool {
    const LENGTH: usize = constant_script.OPERATORS.len;
    return for (0..LENGTH) |i| {
        if (char == constant_script.OPERATORS[i]) {
            break true;
        }
    } else false;
}

pub fn isSeparator(char: u8) bool {
    const LENGTH: usize = constant_script.SEPARATORS.len;
    return for (0..LENGTH) |i| {
        if (char == constant_script.SEPARATORS[i]) {
            break true;
        }
    } else false;
}

pub fn isInteger(input: []const u8) bool {
    const LENGTH: usize = input.len;

    return for (0..LENGTH) |i| {
        const char: u8 = input[i];
        if (input[i] == '-') {
            if (i != 0) {
                return false;
            }
            continue;
        }
        if (isDigit(char) == false) {
            return false;
        }
    } else true;
}

pub fn isDecimal(input: []const u8) bool {
    const LENGTH: usize = input.len;
    return for (0..LENGTH) |i| {
        const char: u8 = input[i];
        if (input[i] == '-') {
            if (i != 0) {
                break false;
            }
        } else if (input[i] == '.') {
            continue;
        } else if (!isDigit(char)) {
            break false;
        }
    } else true;
}

pub fn isLetterOrDigit(char: u8) bool {
    switch (char) {
        'a'...'z', 'A'...'Z', '0'...'9' => return true,
        else => return false,
    }
}

pub fn isDigit(char: u8) bool {
    switch (char) {
        '0'...'9' => return true,
        else => return false,
    }
}
