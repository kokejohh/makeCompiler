const std = @import("std");
const struct_script = @import("../core/structs.zig");

const Token = struct_script.Token;
const ASTData = struct_script.ASTData;
const ASTNode = struct_script.ASTNode;

pub fn printTokens(token_list: *std.ArrayList(Token)) void {
    std.debug.print("\nPrinting Tokens:\n", .{});

    const LENGTH: usize = token_list.items.len;
    if (LENGTH == 0) {
        std.debug.print("\tzero length: {}\n", .{LENGTH});
        return;
    }

    for (0..LENGTH) |i| {
        const token: Token = token_list.items[i];
        std.debug.print("\tText: '{s}' type: '{}'\n", .{
            token.text,
            token.type,
        });
    }
}

pub fn isInfiniteWhileLoop(count: *usize, cap: usize) bool {
    count.* += 1;
    if (count.* >= cap) {
        return true;
    }
    return false;
}

pub fn printASTNodes(allocator: *std.mem.Allocator, ast_nodes: *const std.ArrayList(*ASTNode)) !void {
    std.debug.print("\nPrinting AST Nodes:\n", .{});

    const node_count: usize = ast_nodes.items.len;

    if (node_count == 0) {
        std.debug.print("\tNo nodes\n", .{});
        return;
    }
    for (0..node_count) |i| {
        const node: ?*ASTNode = ast_nodes.items[i];
        try printASTNode(allocator, node, 3, "base");
    }
}

fn printASTNode(allocator: *std.mem.Allocator, node: ?*ASTNode, indent: usize, ast_type_text: []const u8) !void {
    if (node == null) {
        return;
    }

    const padding: *std.ArrayList(u8) = try allocator.create(std.ArrayList(u8));
    padding.* = try std.ArrayList(u8).initCapacity(allocator.*, indent);

    for (0..indent) |i| {
        try addSpacing(allocator, indent, padding, i);
    }

    if (padding.items.len > 0) {
        std.debug.print("{s}", .{padding.items});
    }

    std.debug.print("{}", .{node.?.node_type});

    if (node.?.token) |token| {
        std.debug.print("'{s}' - {s}\n", .{
            token.text,
            ast_type_text,
        });
    }

    if (node.?.left) |left| {
        try printASTNode(allocator, left, indent + 1, "left");
    }
    if (node.?.middle) |middle| {
        try printASTNode(allocator, middle, indent + 1, "middle");
    }
    if (node.?.right) |right| {
        try printASTNode(allocator, right, indent + 1, "right");
    }

    if (node.?.children) |children| {
        const children_count: usize = children.items.len;
        if (children_count > 1000) {
            std.debug.print("WARRNING: count: {}\n", .{children});
            return;
        }

        for (0..children_count) |i| {
            const child: *ASTNode = children.items[i];

            const child_addr: usize = @intFromPtr(child);
            if (child_addr < 0x1000) {
                std.debug.print("{s}[INVALID CHLILD POINTER at index {}] - child\n", .{ padding.items, i });
            }

            try printASTNode(allocator, child, indent + 1, "child");
        }
    }
}

fn addSpacing(allocator: *std.mem.Allocator, indent: usize, padding: *std.ArrayList(u8), i: usize) !void {
    if (i + 1 == indent) {
        try padding.append(allocator.*, '|');
        try padding.append(allocator.*, '-');
        return;
    }

    if (i == 2) {
        try padding.append(allocator.*, '|');
        try padding.append(allocator.*, ' ');
        return;
    }

    if (i == 3) {
        try padding.append(allocator.*, '|');
        try padding.append(allocator.*, ' ');
        return;
    }

    try padding.append(allocator.*, ' ');
    try padding.append(allocator.*, ' ');
}
