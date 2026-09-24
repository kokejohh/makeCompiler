const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const parse_util_script = @import("utils.zig");

const Token = struct_script.Token;
const TokenType = enum_script.TokenType;
const ParseData = struct_script.ParseData;
const ParseError = error_script.ParseError;

pub fn parseToTokens(allocator: *std.mem.Allocator, code: []const u8) !*std.ArrayList(Token) {
    //std.debug.print("\t{s}Parsing{s}\t\t\t\t", .{ printing_script.GREY, printing_script.RESET });

    const token_list = try allocator.create(std.ArrayList(Token));
    //token_list.* = try std.ArrayList(Token).initCapacity(allocator.*, 0);
    token_list.* = std.ArrayList(Token).empty;

    var parse_data = ParseData{
        .token_list = token_list,
        .code = code,
    };

    if (parse_data.code.len == 0) {
        return ParseError.CodeLengthIsZero;
    }

    const STRING_LENGTH: usize = code.len;
    while (parse_data.character_index < STRING_LENGTH) {
        try processCharacter(allocator, &parse_data);
    }
    //std.debug.print("{s}Done{s}\n", .{ printing.CYAN, printing_script.RESET });
    return token_list;
}

fn shouldSkip(allocator: *std.mem.Allocator, parse_data: *ParseData) !bool {
    parse_data.char_count += 1;
    if (parse_data.last_token != null) {
        if (parse_data.last_token.?.type == TokenType.Comment) {
            parse_data.was_comment = true;
        }
    }

    const current_char: u8 = parse_data.code[parse_data.character_index];

    if (current_char == '\n') {
        if (parse_data.was_comment == true) {
            try parse_data.token_list.append(
                allocator.*,
                Token{
                    .text = "",
                    .type = TokenType.EndComment,
                    .line_number = parse_data.line_count,
                    .char_number = parse_data.char_count,
                },
            );
            parse_data.was_comment = false;
        }
        parse_data.line_count += 1;
        parse_data.char_count = 0;
        parse_data.character_index += 1;
        return true;
    }
    const is_special_char: bool = current_char == '\r' or current_char == '\t' or current_char == ' ' or current_char == '\\';

    if (is_special_char == true) {
        parse_data.character_index += 1;
        return true;
    }
    return false;
}

fn processCharacter(allocator: *std.mem.Allocator, parse_data: *ParseData) !void {
    if (try shouldSkip(allocator, parse_data) == true) {
        return;
    }

    const previous_character_index: usize = parse_data.character_index;
    const token: Token = try getToken(allocator, parse_data);

    if (previous_character_index == parse_data.character_index) {
        parse_data.character_index += 1;
    }

    try parse_data.token_list.append(allocator.*, token);
    parse_data.last_token = token;
}

fn getToken(allocator: *std.mem.Allocator, parse_data: *ParseData) !Token {
    const current_char: u8 = parse_data.code[parse_data.character_index];

    if (current_char == '"') {
        return readString(allocator, parse_data);
    }
    if (current_char == '\'') {
        return readChar(allocator, parse_data);
    }
    if (parse_util_script.isOperator(current_char)) {
        return readOperator(allocator, parse_data);
    }
    if (parse_util_script.isSeparator(current_char)) {
        return readSeparator(allocator, parse_data);
    }
    return readWord(allocator, parse_data);
}

fn readString(allocator: *std.mem.Allocator, parse_data: *ParseData) !Token {
    var text_builder: std.ArrayList(u8) = try std.ArrayList(u8).initCapacity(allocator.*, 0);

    parse_data.character_index += 1;

    while (parse_data.character_index < parse_data.code.len) {
        const char: u8 = parse_data.code[parse_data.character_index];

        if (char == '"') {
            parse_data.character_index += 1;
            const text: []u8 = try text_builder.toOwnedSlice(allocator.*);

            return Token{
                .text = text,
                .type = TokenType.StringValue,
                .line_number = parse_data.line_count,
                .char_number = parse_data.char_count,
            };
        }

        try text_builder.append(allocator.*, char);
        parse_data.character_index += 1;
    }
    return ParseError.UnterminatedString;
}

fn readSeparator(allocator: *std.mem.Allocator, parse_data: *ParseData) !Token {
    const char: []u8 = try allocator.alloc(u8, 1);
    char[0] = parse_data.code[parse_data.character_index];
    const tokenType: []const u8 = char[0..];

    return Token{
        .text = tokenType,
        .type = parse_util_script.getTokenType(tokenType),
        .line_number = parse_data.line_count,
        .char_number = parse_data.char_count,
    };
}

fn readChar(allocator: *std.mem.Allocator, parse_data: *ParseData) !Token {
    parse_data.character_index += 1;

    if (parse_data.character_index >= parse_data.code.len) {
        return ParseError.UnexpectedValue;
    }

    const char_value: []u8 = try allocator.alloc(u8, 1);
    char_value[0] = parse_data.code[parse_data.character_index];

    parse_data.character_index += 1;

    if (parse_data.character_index >= parse_data.code.len) {
        return ParseError.UnexpectedValue;
    }
    if (parse_data.code[parse_data.character_index] != '\'') {
        return ParseError.UnterminatedChar;
    }
    parse_data.character_index += 1;

    return Token{
        .text = char_value,
        .type = TokenType.CharValue,
        .line_number = parse_data.line_count,
        .char_number = parse_data.char_count,
    };
}

fn readOperator(allocator: *std.mem.Allocator, parse_data: *ParseData) !Token {
    var text_builder: std.ArrayList(u8) = try std.ArrayList(u8).initCapacity(allocator.*, 0);

    const char: u8 = parse_data.code[parse_data.character_index];
    try text_builder.append(allocator.*, char);

    parse_data.character_index += 1;

    if (parse_data.character_index < parse_data.code.len) {
        const next: u8 = parse_data.code[parse_data.character_index];
        if (parse_util_script.isOperator(next)) {
            try text_builder.append(allocator.*, next);
            parse_data.character_index += 1;
        }
    }

    const text: []u8 = try text_builder.toOwnedSlice(allocator.*);
    return Token{
        .text = text,
        .type = parse_util_script.getTokenType(text),
        .line_number = parse_data.line_count,
        .char_number = parse_data.char_count,
    };
}

fn readWord(allocator: *std.mem.Allocator, parse_data: *ParseData) !Token {
    var text_builder: std.ArrayList(u8) = try .initCapacity(allocator.*, 0);

    while (parse_data.character_index < parse_data.code.len) {
        const c: u8 = parse_data.code[parse_data.character_index];

        if (parse_util_script.isLetterOrDigit(c) or c == '_') {
            try text_builder.append(allocator.*, c);
            parse_data.character_index += 1;
        } else {
            break;
        }
    }

    const text: []u8 = try text_builder.toOwnedSlice(allocator.*);
    return Token{
        .text = text,
        .type = parse_util_script.getTokenType(text),
        .line_number = parse_data.line_count,
        .char_number = parse_data.char_count,
    };
}
