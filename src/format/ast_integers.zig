const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const ast_util_script = @import("utils.zig");
const expression_script = @import("../core/expressions.zig");

const Token = struct_script.Token;
const TokenType = enum_script.TokenType;
const ASTNode = struct_script.ASTNode;
const ASTData = struct_script.ASTData;
const ASTError = error_script.ASTError;
const ASTNodeType = enum_script.ASTNodeType;

pub fn getValueNodeI32(allocator: *std.mem.Allocator, ast_data: *ASTData) !*ASTNode {
    const value_node: *ASTNode = try expression_script.parseBinaryExprAny(allocator, ast_data, 0, ASTNodeType.BinaryExpression);
    return value_node;
}

pub fn processIntNoValue(
    allocator: *std.mem.Allocator,
    ast_data: *ASTData,
    type_node: *ASTNode,
    second_token: Token,
    third_token: Token,
    is_global: bool,
) ASTError!*ASTNode {
    if (third_token.type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected '=' or ';' in declaration";
        ast_data.error_token = third_token;
        return ASTError.UnexpectedType;
    }

    var default_text: []u8 = allocator.alloc(u8, 1) catch return ASTError.OutOfMemory;
    default_text[0] = '0';

    const var_node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);

    var_node.node_type = ASTNodeType.IntegerLiteral;
    var_node.token = .{
        .text = default_text[0..],
        .char_number = 0,
        .line_number = 0,
        .type = TokenType.IntegerValue,
    };

    var default_node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);

    default_node.node_type = ASTNodeType.Declaration;
    default_node.token = second_token;
    default_node.left = type_node;
    default_node.right = var_node;
    default_node.is_global = is_global;

    return default_node;
}

pub fn processIntDeclaration(allocator: *std.mem.Allocator, ast_data: *ASTData, first_token: Token, is_global: bool, is_const: bool) ASTError!*ASTNode {
    ast_data.error_function = "processIntDeclaration";

    const type_node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.VarType;
    type_node.token = first_token;

    const second_token: Token = try ast_data.getNextToken();
    if (second_token.type != TokenType.Identifier) {
        ast_data.error_detail = "Missing expected identifier in declaration";
        ast_data.error_token = second_token;
        return ASTError.UnexpectedType;
    }

    const third_token: Token = try ast_data.getNextToken();
    try ast_data.incrementIndex();

    if (third_token.type != TokenType.Equals) {
        return processIntNoValue(allocator, ast_data, type_node, second_token, third_token, is_global);
    }

    const value_node: *ASTNode = try getValueNodeI32(allocator, ast_data);

    const fourth_token: Token = try ast_data.getToken();
    ast_data.token_index += 1;

    if (fourth_token.type != TokenType.Semicolon) {
        ast_data.error_detail = "Missing expected ';' in declaration";
        ast_data.error_token = fourth_token;
        return ASTError.UnexpectedType;
    }

    var node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);

    node.node_type = ASTNodeType.Declaration;
    node.token = second_token;
    node.left = type_node;
    node.right = value_node;
    node.is_global = is_global;
    node.is_const = is_const;

    return node;
}
