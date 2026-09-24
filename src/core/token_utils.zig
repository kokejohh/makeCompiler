const std = @import("std");
const struct_script = @import("structs.zig");
const error_script = @import("errors.zig");
const enum_script = @import("enums.zig");

const Token = struct_script.Token;
const TokenType = enum_script.TokenType;
const ASTData = struct_script.ASTData;
const ASTError = error_script.ASTError;

pub fn getToken(ast_data: *const ASTData) !Token {
    if (ast_data.token_index >= ast_data.token_list.items.len) {
        return ASTError.IndexOutOfRange;
    }
    return ast_data.token_list.items[ast_data.token_index];
}

pub fn getNextToken(ast_data: *ASTData) !Token {
    ast_data.token_index += 1;
    if (ast_data.token_index >= ast_data.token_index.items.len) {
        return ASTError.IndexOutOfRange;
    }
    return ast_data.token_list.items[ast_data.token_index];
}

pub fn isBinaryOperator(token_type: TokenType) bool {
    return token_type == TokenType.Plus or
        token_type == TokenType.Minus or
        token_type == TokenType.Multiply or
        token_type == TokenType.Divide;
}

pub fn isBinaryOperatorBool(token_type: TokenType) bool {
    return token_type == TokenType.Plus or
        token_type == TokenType.Minus or
        token_type == TokenType.Multiply or
        token_type == TokenType.Divide or
        token_type == TokenType.AndAnd or
        token_type == TokenType.OrOr or
        token_type == TokenType.LessThan or
        token_type == TokenType.LessThanEquals or
        token_type == TokenType.GreaterThan or
        token_type == TokenType.GreaterThanEquals or
        token_type == TokenType.EqualsEquals or
        token_type == TokenType.NotEquals;
}

pub fn getPrecedenceInt(token_type: TokenType) usize {
    switch (token_type) {
        TokenType.Identifier, TokenType.Multiply, TokenType.Divide => return 2,
        TokenType.Plus, TokenType.Minus => return 1,
        else => return 0,
    }
}

pub fn getPrecedenceBool(token_type: TokenType) usize {
    switch (token_type) {
        TokenType.OrOr => return 1,
        TokenType.AndAnd => return 2,
        TokenType.EqualsEquals, TokenType.NotEquals => return 3,
        TokenType.LessThan, TokenType.GreaterThan, TokenType.LessThanEquals, TokenType.GreaterThanEquals => return 4,
        TokenType.Plus, TokenType.Minus => return 5,
        TokenType.Multiply, TokenType.Divide => return 6,
        else => return 0,
    }
}
