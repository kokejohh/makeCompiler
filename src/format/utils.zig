const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");

const Token = struct_script.Token;
const ASTNode = struct_script.ASTNode;
const ASTNodeType = enum_script.ASTNodeType;
const ASTError = error_script.ASTError;

pub fn createASTNode(
    allocator: *std.mem.Allocator,
    node_type: ASTNodeType,
    token: Token,
    left: ?*ASTNode,
    middle: ?*ASTNode,
    right: ?*ASTNode,
    children: ?*std.ArrayList(*ASTNode),
    is_array: bool,
    is_global: bool,
    is_const: bool,
    size: usize,
) !*ASTNode {
    var node: *ASTNode = try allocator.*.create(ASTNode);
    node.node_type = node_type;
    node.token = token;
    node.left = left;
    node.middle = middle;
    node.right = right;
    node.children = children;
    node.is_array = is_array;
    node.is_global = is_global;
    node.is_const = is_const;
    node.size = size;

    return node;
}

pub fn createDefaultAstNode(allocator: *std.mem.Allocator) ASTError!*ASTNode {
    var node: *ASTNode = allocator.create(ASTNode) catch {
        return ASTError.OutOfMemory;
    };
    node.node_type = ASTNodeType.Invalid;
    node.token = null;
    node.left = null;
    node.middle = null;
    node.right = null;
    node.children = null;
    node.is_array = false;
    node.is_global = false;
    node.is_const = false;
    node.size = 0;

    return node;
}

pub fn copyNodeValues(dest_node: *ASTNode, src_node: *const ASTNode) void {
    dest_node.children = src_node.children;
    dest_node.is_array = src_node.is_array;
    dest_node.is_const = src_node.is_const;
    dest_node.children = src_node.children;
    dest_node.left = src_node.left;
    dest_node.middle = src_node.middle;
    dest_node.right = src_node.right;
    dest_node.size = src_node.size;
    dest_node.token = src_node.token;
}
