const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const expression_script = @import("../core/expressions.zig");
const ast_util_script = @import("utils.zig");

const Token = struct_script.Token;
const TokenType = enum_script.TokenType;
const ASTData = struct_script.ASTData;
const ASTNode = struct_script.ASTNode;
const ASTNodeType = enum_script.ASTNodeType;
const ASTError = error_script.ASTError;

pub fn processReturn(allocator: *std.mem.Allocator, ast_data: *ASTData) ASTError!*ASTNode {
    ast_data.error_function = "processReturn";

    const return_token: Token = try ast_data.getToken();
    ast_data.token_index += 1;
    const value_node: *ASTNode = try expression_script.parseBinaryExprAny(
        allocator,
        ast_data,
        0,
        ASTNodeType.ReturnExpression,
    );

    const semicolon_token: Token = try ast_data.getToken();
    if (semicolon_token.type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected ';'";
        return ASTError.MissingExpectedType;
    }
    ast_data.token_index += 1;

    const return_node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);
    return_node.node_type = ASTNodeType.Return;
    return_node.token = return_token;
    return_node.right = value_node;

    return return_node;
}
