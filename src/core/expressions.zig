const std = @import("std");
const struct_script = @import("structs.zig");
const enum_script = @import("enums.zig");
const error_script = @import("errors.zig");
const ast_util_script = @import("../format/utils.zig");
const debugging_script = @import("../debugging/debugging.zig");
const token_util_script = @import("token_utils.zig");

const Token = struct_script.Token;
const TokenType = enum_script.TokenType;
const ASTNode = struct_script.ASTNode;
const ASTData = struct_script.ASTData;
const ASTNodeType = enum_script.ASTNodeType;
const ASTError = error_script.ASTError;

pub fn parsePrimaryAny(allocator: *std.mem.Allocator, ast_data: *ASTData, node_type: ASTNodeType) ASTError!?*ASTNode {
    _ = node_type;

    if (ast_data.token_index >= ast_data.token_list.items.len) {
        return ASTError.UnexpectedEndOfFile;
    }

    const token: Token = ast_data.token_list.items[ast_data.token_index];
    var node: *ASTNode = ast_util_script.createDefaultAstNode(allocator) catch {
        return ASTError.OutOfMemory;
    };

    switch (token.type) {
        //TokenType.False, TokenType.True => {
        //node.node_type = ASTNodeType.BoolLiteral;
        //node.token = token;
        //},
        TokenType.IntegerValue => {
            node.node_type = ASTNodeType.IntegerLiteral;
            node.token = token;
        },
        //TokenType.Idenfitier => {
        //try parseProcessIdentifier(allocator, ast_data, node, token);
        //},
        TokenType.StringValue => {
            node.node_type = ASTNodeType.IntegerLiteral;
            node.token = token;
        },
        TokenType.CharValue => {
            node.node_type = ASTNodeType.CharLiteral;
            node.token = token;
        },
        //TokenType.LeftParenthesis => {
        //return processParsePrimaryLeftParenthesis(allocator, ast_data, node_type);
        //},
        //TokenType.RightParenthesis => return null,
        //TokenType.And => return ProcessReference(allocator, ast_date, token);
        //Token.Minus => return ProcessMinus(allocator, ast_data, token);\
        else => {
            ast_data.error_detail = "Unexpected type in expression, {token.Type}";
            ast_data.error_token = token;
            return ASTError.UnexpectedType;
        },
    }
    ast_data.token_index += 1;
    return node;
}

pub fn parseBinaryExprAny(allocator: *std.mem.Allocator, ast_data: *ASTData, min_prec: usize, node_type: ASTNodeType) ASTError!*ASTNode {
    var left: ?*ASTNode = try parsePrimaryAny(allocator, ast_data, node_type);

    var while_count: usize = 0;
    const max: usize = 1000;

    while (ast_data.token_index < ast_data.token_list.items.len) {
        if (debugging_script.isInfiniteWhileLoop(&while_count, max) == true) {
            return ASTError.InfiniteWhileLoop;
        }

        const operator_token: Token = ast_data.token_list.items[ast_data.token_index];

        if (token_util_script.isBinaryOperatorBool(operator_token.type) == false) {
            break;
        }

        const precedence: usize = token_util_script.getPrecedenceBool(operator_token.type);

        if (precedence < min_prec) {
            break;
        }

        ast_data.token_index += 1;
        const right: ?*ASTNode = try parseBinaryExprAny(allocator, ast_data, precedence + 1, node_type);

        if (right == null) {
            ast_data.error_detail = "Missing value after equation symbol";
            ast_data.error_token = operator_token;
            return ASTError.UnexpectedType;
        }

        var new_node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);

        new_node.node_type = node_type;
        new_node.token = operator_token;
        new_node.left = left;
        new_node.right = right;

        left = new_node;
    }
    return left.?;
}
