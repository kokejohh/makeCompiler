const std = @import("std");
const struct_script = @import("../core/structs.zig");
const error_script = @import("../core/errors.zig");

const ASTNode = struct_script.ASTNode;
const ConvertData = struct_script.ConvertData;
const ConvertError = error_script.ConvertError;

pub fn processReturn(allocator: std.mem.Allocator, convert_data: *ConvertData, node: *ASTNode) ConvertError!void {
    convert_data.error_function = "processReturn";

    const node_right = node.right orelse {
        return ConvertError.NodeIsNull;
    };

    const node_right_token = node_right.token orelse {
        return ConvertError.NodeIsNull;
    };

    convert_data.generated_code.appendFmt(allocator, "\tret i32 {s}\n", .{
        node_right_token.text,
    }) catch return ConvertError.OutOfMemory;
}
