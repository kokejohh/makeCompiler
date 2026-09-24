const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const debugging_script = @import("../debugging/debugging.zig");
const ast_integer_script = @import("ast_integers.zig");

const Token = struct_script.Token;
const ASTData = struct_script.ASTData;
const ASTNode = struct_script.ASTNode;
const TokenType = enum_script.TokenType;
const ASTError = error_script.ASTError;

pub fn buildASTs(allocator: *std.mem.Allocator, token_list: *const std.ArrayList(Token), code: []const u8) !*std.ArrayList(*ASTNode) {
    std.debug.print("Format\n", .{});
    _ = code;

    const ast_node: *std.ArrayList(*ASTNode) = try allocator.*.create(std.ArrayList(*ASTNode));
    ast_node.* = try std.ArrayList(*ASTNode).initCapacity(allocator.*, 0);

    var ast_data = ASTData{
        .ast_node = ast_node,
        .token_index = 0,
        .token_list = token_list,
    };

    const token_count: usize = token_list.items.len;
    while (ast_data.token_index < token_count) {
        const index_before: usize = ast_data.token_index;

        processGlobalTokenAST(allocator, &ast_data, false) catch |err| {
            std.debug.print("Error\n", .{});
            //try debugging_script.printASTError(allocator, ast_data, code);
            return err;
        };

        if (index_before == ast_data.token_index) {
            ast_data.token_index += 1;
        }
    }

    std.debug.print("Done\n", .{});

    return ast_node;
}

fn processGlobalTokenAST(allocator: *std.mem.Allocator, ast_data: *ASTData, is_const: bool) !void {
    ast_data.error_function = "processGlobalTokenAST";

    const first_token: Token = try ast_data.getToken();

    switch (first_token.type) {
        TokenType.Const => {
            ast_data.token_index += 1;
            try processGlobalTokenAST(allocator, ast_data, true);
        },
        TokenType.i32 => {
            const declaration_node: *ASTNode = try ast_integer_script.processIntDeclaration(allocator, ast_data, first_token, true, is_const);
            try ast_data.ast_node.append(allocator.*, declaration_node);
        },
        TokenType.Multiply => {
            //const pointer_node: *ASTNode = try ast_pointer_script.processPointerDeclaration(ast_data, first_token, true, is);
            //try ast_data.ast_node.append(allocator.*, pointer_node);
        },
        TokenType.Func => {
            //try ast_function_script.processFunctionDeclaration(allocator, ast_data);
        },
        else => {
            ast_data.error_detail = "unimplemented type in ast";
            ast_data.error_token = first_token;
            return ASTError.UnimplementedType;
        },
    }
}
