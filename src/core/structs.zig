const std = @import("std");
const enum_script = @import("enums.zig");
const error_script = @import("errors.zig");

const TokenType = enum_script.TokenType;
const ASTNodeType = enum_script.ASTNodeType;
const ASTError = error_script.ASTError;

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
    type: TokenType,
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

pub const ASTData = struct {
    ast_node: *std.ArrayList(*ASTNode),
    token_index: usize,
    token_list: *const std.ArrayList(Token),
    error_detail: ?[]const u8 = null,
    error_token: ?Token = null,
    error_function: ?[]const u8 = null,

    pub fn getToken(self: *ASTData) !Token {
        if (self.token_index >= self.token_list.items.len) {
            return ASTError.IndexOutOfRange;
        }
        const token: Token = self.token_list.items[self.token_index];
        self.error_token = token;
        return token;
    }

    pub fn getNextToken(self: *ASTData) !Token {
        self.token_index += 1;
        if (self.token_index >= self.token_list.items.len) {
            return ASTError.IndexOutOfRange;
        }
        const token: Token = self.token_list.items[self.token_index];
        self.error_token = token;
        return token;
    }

    pub fn setErrorData(self: *ASTData, error_message: []const u8, error_token: Token) void {
        self.error_detail = error_message;
        self.error_token = error_token;
    }

    pub fn incrementIndex(self: *ASTData) !void {
        self.token_index += 1;
        if (self.token_index >= self.token_list.items.len) {
            return ASTError.IndexOutOfRange;
        }
    }
};

pub const ASTNode = struct {
    node_type: ASTNodeType = ASTNodeType.Invalid,

    token: ?Token = null,
    left: ?*ASTNode = null,
    middle: ?*ASTNode = null,
    right: ?*ASTNode = null,
    children: ?*std.ArrayList(*ASTNode) = null,

    is_array: bool = false,
    is_global: bool = false,
    is_const: bool = false,
    size: usize = 0,

    pub fn makeAllNull(self: *ASTNode) void {
        self.left = null;
        self.middle = null;
        self.right = null;
        self.children = null;
        self.token = null;
    }
};
