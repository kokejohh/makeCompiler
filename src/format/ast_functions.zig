const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const expression_script = @import("../core/expressions.zig");
const token_script = @import("../core/token_utils.zig");
const ast_util_script = @import("utils.zig");
const ast_integer_script = @import("ast_integers.zig");
const ast_return_script = @import("ast_returns.zig");

const Token = struct_script.Token;
const TokenType = enum_script.TokenType;
const ASTData = struct_script.ASTData;
const ASTNode = struct_script.ASTNode;
const ASTError = error_script.ASTError;
const ASTNodeType = enum_script.ASTNodeType;

fn processFunctionTokenAST(allocator: *std.mem.Allocator, ast_data: *ASTData, first_token: Token, block_node: *ASTNode, is_global: bool, is_const: bool) ASTError!void {
    ast_data.error_function = "processFunctionTokenAST";

    switch (first_token.type) {
        TokenType.Const => {
            ast_data.token_index += 1;
            const possible_next_token: Token = try ast_data.getToken();
            try processFunctionTokenAST(
                allocator,
                ast_data,
                possible_next_token,
                block_node,
                is_global,
                true,
            );
        },
        TokenType.u32, TokenType.i16, TokenType.i8, TokenType.i64, TokenType.u64, TokenType.i32, TokenType.u8, TokenType.Usize => {
            const int_declaration_node: *ASTNode = try ast_integer_script.processIntDeclaration(allocator, ast_data, first_token, is_global, is_const);
            block_node.children.?.append(allocator.*, int_declaration_node) catch return ASTError.OutOfMemory;
        },
        TokenType.f64, TokenType.f32 => {},
        TokenType.Return => {
            const return_node = try ast_return_script.processReturn(allocator, ast_data);
            block_node.children.?.append(allocator.*, return_node) catch return ASTError.OutOfMemory;
        },
        TokenType.Bool => {},
        TokenType.Print => {},
        TokenType.Println => {},
        TokenType.If => {},
        TokenType.While => {},
        TokenType.For => {},
        TokenType.Identifier => {},
        TokenType.LeftSquareBracket => {},
        TokenType.String => {},
        TokenType.Char => {},
        TokenType.Comment => {},
        TokenType.Continue => {},
        TokenType.Break => {},
        TokenType.Multiply => {},
        else => {
            ast_data.error_detail = "Unimplemented type in function";
            ast_data.error_token = first_token;
            return ASTError.UnimplementedType;
        },
    }
}
pub fn processFunctionDeclaration(allocator: *std.mem.Allocator, ast_data: *ASTData) ASTError!void {
    ast_data.error_function = "processFunctionDeclaration";

    const varTypeToken: Token = try ast_data.getNextToken();

    if (token_script.isVarType(varTypeToken.type) == false) {
        ast_data.error_detail = "Missing expected function type";
        return ASTError.MissingExpectedType;
    }

    const type_node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);
    type_node.node_type = ASTNodeType.ReturnType;
    type_node.token = varTypeToken;

    const var_name_token: Token = try ast_data.getNextToken();
    if (var_name_token.type != TokenType.Identifier) {
        ast_data.error_detail = "Missing expected function name";
        return ASTError.MissingExpectedType;
    }

    const left_parenthesis_token: Token = try ast_data.getNextToken();
    if (left_parenthesis_token.type != TokenType.LeftParenthesis) {
        ast_data.error_detail = "Missing expected '('";
        return ASTError.MissingExpectedType;
    }
    ast_data.token_index += 1;

    const parameters_node: ?*ASTNode = null; // try expression_script.fillParameters(allocator, ast_data);

    const right_parenthesis_token: Token = try ast_data.getToken();
    if (right_parenthesis_token.type != TokenType.RightParenthesis) {
        ast_data.error_detail = "Missing expected ')'";
        return ASTError.MissingExpectedType;
    }

    const left_brace_token: Token = try ast_data.getNextToken();
    if (left_brace_token.type != TokenType.LeftBrace) {
        ast_data.error_detail = "Missing expected '{'";
        return ASTError.MissingExpectedType;
    }
    ast_data.token_index += 1;

    const function_body_node: *ASTNode = try buildBodyBlock(allocator, ast_data, ASTNodeType.FunctionBody);

    const right_brace_token: Token = try ast_data.getToken();
    if (right_brace_token.type != TokenType.RightBrace) {
        ast_data.error_detail = "Missing expected '}'";
        return ASTError.MissingExpectedType;
    }
    ast_data.token_index += 1;

    const function_node: *ASTNode = try ast_util_script.createDefaultAstNode(allocator);
    function_node.node_type = ASTNodeType.FunctionDeclaration;
    function_node.token = var_name_token;
    function_node.left = type_node;
    function_node.middle = parameters_node;
    function_node.right = function_body_node;

    ast_data.ast_nodes.append(allocator.*, function_node) catch return ASTError.OutOfMemory;
}

pub fn buildBodyBlock(allocator: *std.mem.Allocator, ast_data: *ASTData, node_type: ASTNodeType) ASTError!*ASTNode {
    ast_data.error_function = "buildBodyBlock";

    const token_count: usize = ast_data.token_list.items.len;
    const block_node: *ASTNode = ast_util_script.createDefaultAstNode(allocator) catch return ASTError.OutOfMemory;

    const child_list: *std.ArrayList(*ASTNode) = allocator.create(std.ArrayList(*ASTNode)) catch {
        return ASTError.OutOfMemory;
    };

    child_list.* = std.ArrayList(*ASTNode).initCapacity(allocator.*, 0) catch {
        return ASTError.OutOfMemory;
    };
    block_node.children = child_list;
    block_node.node_type = node_type;

    while (ast_data.token_index < token_count) {
        const index_before: usize = ast_data.token_index;
        const token: Token = ast_data.token_list.items[ast_data.token_index];
        if (token.type == TokenType.RightBrace) {
            break;
        }
        try processFunctionTokenAST(
            allocator,
            ast_data,
            token,
            block_node,
            false,
            false,
        );

        if (index_before == ast_data.token_index) {
            ast_data.token_index += 1;
        }
    }
    return block_node;
}
