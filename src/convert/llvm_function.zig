const std = @import("std");
const struct_script = @import("../core/structs.zig");
const enum_script = @import("../core/enums.zig");
const error_script = @import("../core/errors.zig");
const llvm_util_script = @import("llvm_utils.zig");
const llvm_body_script = @import("llvm_body.zig");

const Token = struct_script.Token;
const ASTNode = struct_script.ASTNode;
const ASTNodeType = enum_script.ASTNodeType;
const ConvertData = struct_script.ConvertData;
const ConvertError = error_script.ConvertError;

pub fn processFunctionDeclaration(allocator: std.mem.Allocator, convert_data: *ConvertData, node: *ASTNode) !void {
    convert_data.error_function = "processFunctionDeclaration";

    //node_tye: ASTNodeType.FunctionDeclaration,
    //token: third_token, - function name,
    //left: &type_node, - return type node,
    //middle: nil, - parameters,
    //right: function_body_node, - function body

    try writeFunctionNameAndParameters(allocator, convert_data, node);

    const node_right = node.right orelse {
        convert_data.error_detail = "node.right is null";
        return ConvertError.NodeIsNull;
    };

    convert_data.generated_code.appendLine(allocator, "entry:") catch return ConvertError.OutOfMemory;
    try llvm_body_script.processBody(allocator, convert_data, node_right);
    convert_data.generated_code.append(allocator, "\r}\n\n") catch return ConvertError.OutOfMemory;
}

fn writeFunctionNameAndParameters(allocator: std.mem.Allocator, convert_data: *ConvertData, node: *ASTNode) ConvertError!void {
    convert_data.error_function = "writeFunctionNameAndParameters";

    const node_left = node.left orelse {
        convert_data.error_detail = "node.left is null";
        return ConvertError.NodeIsNull;
    };

    const function_name = node.token orelse {
        convert_data.error_detail = "node.token is null";
        return ConvertError.NodeIsNull;
    };

    const return_type = node_left.token orelse {
        convert_data.error_detail = "node.left.token is null";
        return ConvertError.NodeIsNull;
    };

    const return_type_text = llvm_util_script.convertToLLVMType(return_type) orelse {
        convert_data.error_token = return_type;
        return ConvertError.InvalidReturnType;
    };

    convert_data.generated_code.appendFmt(allocator, "define {s} @{s}(", .{
        return_type_text,
        function_name.text,
    }) catch return ConvertError.OutOfMemory;

    convert_data.generated_code.append(allocator, ") {\n\t") catch return ConvertError.OutOfMemory;
}
