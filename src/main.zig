const std = @import("std");
const struct_script = @import("core/structs.zig");
const parse_script = @import("parse/parses.zig");
const code_sample_script = @import("core/code_samples.zig");
const debugging = @import("debugging/debugging.zig");

const Token = struct_script.Token;

const makeCompiler = @import("makeCompiler");

fn convertCode(code: []const u8) void {
    std.debug.print("Code: \n{s}\n", .{code});

    const page_allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(page_allocator);
    defer arena.deinit();

    var arena_allocator = arena.allocator();

    const token_list: *std.ArrayList(Token) = parse_script.parseToTokens(&arena_allocator, code) catch |err| {
        std.debug.print("Error {}\n", .{err});
        return;
    };
    debugging.printTokens(token_list);
}
pub fn main() !void {
    convertCode(code_sample_script.RETURN_ZERO);
    convertCode(code_sample_script.RETURN_ZERO_WITH_INT);
    convertCode(code_sample_script.RETURN_10_PLUS_10);
    convertCode(code_sample_script.HELLO_WORLD);
    convertCode(code_sample_script.GLOBAL);
}
