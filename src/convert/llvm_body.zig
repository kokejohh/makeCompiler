const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const llvm_return = @import("llvm_return.zig");

const ASTNode = struct_script.ASTNode;
const ASTNodeType = enum_script.ASTNodeType;
const ConvertData = struct_script.ConvertData;
const ConvertError = error_script.ConvertError;

//pub fn processBody(allocator: std.mem.Allocator, convert_data: *ConvertData, node: *ASTNode) ConvertError!void {
pub fn processBody(allocator: std.mem.Allocator, convert_data: *ConvertData, node: *ASTNode) ConvertError!void {
    convert_data.error_function = "processBody";

    const node_children = node.children orelse {
        convert_data.error_detail = "node.children is null";
        return ConvertError.NodeIsNull;
    };

    const child_count: usize = node_children.items.len;
    if (child_count == 0) {
        return;
    }

    for (0..child_count) |i| {
        const child: *ASTNode = node.children.?.items[i];
        try processFunctionBodyNode(allocator, convert_data, child);
    }
}

fn processFunctionBodyNode(allocator: std.mem.Allocator, convert_data: *ConvertData, node: *ASTNode) ConvertError!void {
    const node_type: ASTNodeType = node.node_type;

    if (node_type == ASTNodeType.Invalid) {
        convert_data.error_token = node.token;
        return ConvertError.InvalidNodeType;
    }

    switch (node_type) {
        .Return => try llvm_return.processReturn(allocator, convert_data, node),
        else => return,
    }
}
