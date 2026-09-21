const std = @import("std");
const enum_script = @import("enums.zig");

const TokenType = enum_script.TokenType;

pub const ParseData = struct {
    token_list: *std.ArrayList(Token),
    last_token: ?Token = null,
    character_index: usize = 0,
    code: []const u8 = "",
    line_count: usize = 0,
    char_count: usize = 0,
    was_comment: bool = false,
};

pub const Token = struct {
    text: []const u8,
    Type: TokenType,
    line_number: usize,
    char_number: usize,

    pub fn print_value(self: *const Token) void {
        std.debug.print("Token values:\n text: '{s}'\n type: {}\n line no: {}\n", .{
            self.text,
            self.Type,
            self.lineNumber,
        });
    }

    pub fn isType(self: *const Token, tokenType: TokenType) bool {
        return self.Type == tokenType;
    }
};
