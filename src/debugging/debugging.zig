const std = @import("std");
const struct_script = @import("../core/structs.zig");

const Token = struct_script.Token;
//const ASTData = struct_script.ASTDATA;
//const ASTNode = struct_script.ASTNode;

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
            token.Type,
        });
    }
}
