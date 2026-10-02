const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const debugging_script = @import("../debugging/debugging.zig");
const llvm_function_script = @import("llvm_function.zig");

const ASTData = struct_script.ASTData;
const ASTNode = struct_script.ASTNode;
const ASTNodeType = enum_script.ASTNodeType;
const StringBuilder = struct_script.StringBuilder;
const ConvertData = struct_script.ConvertData;
const ConvertError = error_script.ConvertError;

pub fn convert(allocator: std.mem.Allocator, ast_nodes: *std.ArrayList(*ASTNode), code: []const u8) ConvertError!void {
    std.debug.print("\tConverting\t\t\t", .{});

    var generated_code: StringBuilder = StringBuilder.init(allocator) catch return ConvertError.OutOfMemory;
    var convert_data: ConvertData = ConvertData{
        .ast_nodes = ast_nodes,
        .generated_code = &generated_code,
    };

    convert_data.error_function = "convert";

    const node_count: usize = ast_nodes.items.len;
    if (node_count == 0) {
        return ConvertError.NoASTNodes;
    }

    convert_data.generated_code.appendLine(allocator, "declare i32 @printf(i8*, ...)") catch return ConvertError.OutOfMemory;

    while (convert_data.node_index < node_count) {
        const previous_index: usize = convert_data.node_index;

        processGlobalNode(allocator, &convert_data) catch |err| {
            std.debug.print("Error\n", .{});
            debugging_script.printConvertError(allocator, convert_data, code) catch |err2| {
                std.debug.print("error printing convert data: {}\n", .{err2});
            };
            return err;
        };

        if (previous_index == convert_data.node_index) {
            convert_data.node_index += 1;
        }
    }

    std.debug.print("Done\n", .{});

    const generated_output: []u8 = generated_code.toOwnedSlice(allocator) catch return ConvertError.OutOfMemory;
    std.debug.print("Generated Code: \n{s}\n", .{generated_output});
}

fn processGlobalNode(allocator: std.mem.Allocator, convert_data: *ConvertData) ConvertError!void {
    convert_data.error_function = "processGlobalNode";

    const node: *ASTNode = convert_data.getNode() orelse {
        return ConvertError.NodeIsNull;
    };

    switch (node.node_type) {
        .FunctionDeclaration => try llvm_function_script.processFunctionDeclaration(allocator, convert_data, node),
        .Declaration => return,
        else => return ConvertError.UnimplementedNodeType,
    }
}
