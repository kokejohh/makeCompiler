const std = @import("std");
const struct_script = @import("../core/structs.zig");

const Token = struct_script.Token;
const ASTData = struct_script.ASTData;
const ASTNode = struct_script.ASTNode;
const ConvertData = struct_script.ConvertData;

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

pub fn printASTNodes(allocator: std.mem.Allocator, ast_nodes: *const std.ArrayList(*ASTNode)) !void {
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

fn printASTNode(allocator: std.mem.Allocator, node: ?*ASTNode, indent: usize, ast_type_text: []const u8) !void {
    if (node == null) {
        return;
    }

    const padding: *std.ArrayList(u8) = try allocator.create(std.ArrayList(u8));
    padding.* = try std.ArrayList(u8).initCapacity(allocator, indent);

    for (0..indent) |i| {
        try addSpacing(allocator, indent, padding, i);
    }

    if (padding.items.len > 0) {
        std.debug.print("{s}", .{padding.items});
    }

    std.debug.print("{} ", .{node.?.node_type});

    if (node.?.token) |token| {
        std.debug.print("'{s}' - {s}\n", .{
            token.text,
            ast_type_text,
        });
    } else {
        std.debug.print("NA - {s}\n", .{ast_type_text});
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

fn addSpacing(allocator: std.mem.Allocator, indent: usize, padding: *std.ArrayList(u8), i: usize) !void {
    if (i + 1 == indent) {
        try padding.append(allocator, '|');
        try padding.append(allocator, '-');
        return;
    }

    if (i == 2) {
        try padding.append(allocator, '|');
        try padding.append(allocator, ' ');
        return;
    }

    if (i == 3) {
        try padding.append(allocator, '|');
        try padding.append(allocator, ' ');
        return;
    }

    try padding.append(allocator, ' ');
    try padding.append(allocator, ' ');
}

pub fn printASTError(allocator: *std.mem.Allocator, ast_data: ASTData, code: []const u8) !void {
    const error_token: ?Token = ast_data.error_token;

    const line_number: usize = getLineNumber(error_token);
    const char_number: usize = getCharNumber(error_token);
    const temp_error_detail: ?[]const u8 = ast_data.error_detail;
    var error_detail: []const u8 = undefined;

    if (temp_error_detail == null) {
        error_detail = "NA";
    } else {
        error_detail = temp_error_detail.?;
    }

    const normalized_code: []u8 = try std.mem.replaceOwned(u8, allocator.*, code, "\r\n", "\n");
    defer allocator.free(normalized_code);

    var line_iterator = std.mem.splitScalar(u8, normalized_code, '\n');
    var code_lines = try std.ArrayList([]const u8).initCapacity(allocator.*, 0);

    while (line_iterator.next()) |line| {
        try code_lines.append(allocator.*, line);
    }

    std.debug.print("\tError on line {}, {}: {s}\n", .{
        line_number,
        char_number,
        error_detail,
    });

    printCodeLines(line_number, &code_lines);

    printErrorToken(error_token);

    if (ast_data.error_function) |error_function| {
        std.debug.print("\tFunction: {s}\n", .{error_function});
    }
    //PrintErrorTrace(ast_data,error_trace);
}

pub fn printConvertError(allocator: std.mem.Allocator, convert_data: ConvertData, code: []const u8) !void {
    const error_token: ?Token = convert_data.error_token;
    const line_number: usize = getLineNumber(error_token);
    const char_number: usize = getCharNumber(error_token);
    const error_detail: []const u8 = convert_data.error_detail orelse "NA";

    const normalized_code: []u8 = try std.mem.replaceOwned(u8, allocator, code, "\r\n", "\n");
    defer allocator.free(normalized_code);

    var line_iterator = std.mem.splitScalar(u8, normalized_code, '\n');
    var code_lines = try std.ArrayList([]const u8).initCapacity(allocator, 0);

    while (line_iterator.next()) |line| {
        try code_lines.append(allocator, line);
    }

    std.debug.print("\tError on line {}, {}: {s}\n", .{
        line_number,
        char_number,
        error_detail,
    });

    printCodeLines(line_number, &code_lines);

    printErrorToken(error_token);

    if (convert_data.error_function) |error_function| {
        std.debug.print("\tFunction: {s}\n", .{error_function});
    }
}

fn getLineNumber(error_token: ?Token) usize {
    if (error_token == null) {
        return 0;
    }
    return error_token.?.line_number;
}

fn getCharNumber(error_token: ?Token) usize {
    if (error_token == null) {
        return 0;
    }
    return error_token.?.char_number;
}

fn printCodeLines(line_number: usize, code_lines: *std.ArrayList([]const u8)) void {
    var previous_line: []const u8 = "...";
    var previous_index_in_range: bool = false;

    if (line_number > 0) {
        previous_index_in_range = line_number - 1 >= 0 and line_number - 1 < code_lines.items.len;
    }

    if (previous_index_in_range) {
        previous_line = code_lines.items[line_number - 1];
    }

    var code_line: []const u8 = "...";
    const index_in_range: bool = line_number >= 0 and line_number < code_lines.items.len;

    if (index_in_range) {
        code_line = code_lines.items[line_number];
    }
    std.debug.print("\tline {}: {s}\t\tline {}: {s}\n\n", .{ line_number, previous_line, line_number + 1, code_line });
}

fn printErrorToken(error_token: ?Token) void {
    std.debug.print("\tToken: ", .{});
    if (error_token != null) {
        std.debug.print("{s}\n", .{error_token.?.text});
    } else {
        std.debug.print("Error token not set\n", .{});
    }
}
