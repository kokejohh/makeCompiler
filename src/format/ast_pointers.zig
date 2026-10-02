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

pub fn processPointerDeclaration(
    allocator: *std.mem.Allocator,
    ast_data: *ASTData,
    first_token: Token,
    is_global: bool,
    is_const: bool,
) !*ASTNode {
    ast_data.error_function = "processPointerDeclaration";
    const type_node: ?*ASTNode = null; //try expression_script.createComplexDeclaration(allocator, ast_data);
    const name_token: Token = try ast_data.getToken();

    if (name_token.type != TokenType.Identifier) {
        ast_data.error_detail = "Expected varname after array type";
        return ASTError.MissingExpectedType;
    }

    const equals_token: Token = try ast_data.getNextToken();

    if (equals_token.type != TokenType.Equals) {
        ast_data.error_detail = "Expected equals after array name, uninitialized arrays not implemented yet";
        return ASTError.MissingExpectedType;
    }
    ast_data.token_index += 1;

    const value_node: *ASTNode = try expression_script.parseBinaryEXprAny(allocator, ast_data, 0, ASTNodeType.BinaryExpression);
    const end_token: Token = try ast_data.getToken();

    if (end_token.type != TokenType.Semicolon) {
        ast_data.token_index -= 1;

        if (end_token.type != TokenType.Semicolon) {
            ast_data.error_detail = "Missing expected ';' after declaration";
            return ASTError.MissingExpectedType;
        }
    }
    ast_data.token_index += 1;

    type_node.?.token = first_token;

    var node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);
    node.node_type = ASTNodeType.PointerDeclaration;
    node.token = name_token;
    node.left = type_node.?;
    node.right = value_node;
    node.is_global = is_global;
    node.is_const = is_const;

    return node;
}
