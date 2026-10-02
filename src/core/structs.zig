const std = @import("std");
const enum_script = @import("enums.zig");
const error_script = @import("errors.zig");

const TokenType = enum_script.TokenType;
const ASTNodeType = enum_script.ASTNodeType;
const ASTError = error_script.ASTError;

pub const Token = struct {
    text: []const u8,
    type: TokenType,
    line_number: usize,
    char_number: usize,

    pub fn print_value(self: *const Token) void {
        std.debug.print("Token values:\n text: '{s}'\n type: {}\n line no: {}\n", .{
            self.text,
            self.Type,
            self.lineNumber,
        });
    }

    pub fn isType(self: *const Token, tokenType: TokenType) bool {
        return self.Type == tokenType;
    }
};

pub const ParseData = struct {
    token_list: *std.ArrayList(Token),
    last_token: ?Token = null,
    character_index: usize = 0,
    code: []const u8 = "",
    line_count: usize = 0,
    char_count: usize = 0,
    was_comment: bool = false,
};

pub const ConvertData = struct {
    ast_nodes: *std.ArrayList(*ASTNode),
    node_index: usize = 0,
    error_detail: ?[]const u8 = null,
    error_token: ?Token = null,
    error_function: ?[]const u8 = null,
    generated_code: *StringBuilder,

    pub fn getNode(self: *const ConvertData) ?*ASTNode {
        if (self.node_index >= self.ast_nodes.items.len) {
            return null;
        }
        return self.ast_nodes.items[self.node_index];
    }
};

pub const ASTData = struct {
    ast_nodes: *std.ArrayList(*ASTNode),
    token_index: usize,
    token_list: *const std.ArrayList(Token),
    error_detail: ?[]const u8 = null,
    error_token: ?Token = null,
    error_function: ?[]const u8 = null,

    pub fn getToken(self: *ASTData) !Token {
        if (self.token_index >= self.token_list.items.len) {
            return ASTError.IndexOutOfRange;
        }
        const token: Token = self.token_list.items[self.token_index];
        self.error_token = token;
        return token;
    }

    pub fn getNextToken(self: *ASTData) !Token {
        self.token_index += 1;
        if (self.token_index >= self.token_list.items.len) {
            return ASTError.IndexOutOfRange;
        }
        const token: Token = self.token_list.items[self.token_index];
        self.error_token = token;
        return token;
    }

    pub fn setErrorData(self: *ASTData, error_message: []const u8, error_token: Token) void {
        self.error_detail = error_message;
        self.error_token = error_token;
    }

    pub fn incrementIndex(self: *ASTData) !void {
        self.token_index += 1;
        if (self.token_index >= self.token_list.items.len) {
            return ASTError.IndexOutOfRange;
        }
    }
};

pub const ASTNode = struct {
    node_type: ASTNodeType = ASTNodeType.Invalid,

    token: ?Token = null,
    left: ?*ASTNode = null,
    middle: ?*ASTNode = null,
    right: ?*ASTNode = null,
    children: ?*std.ArrayList(*ASTNode) = null,

    is_array: bool = false,
    is_global: bool = false,
    is_const: bool = false,
    size: usize = 0,

    pub fn makeAllNull(self: *ASTNode) void {
        self.left = null;
        self.middle = null;
        self.right = null;
        self.children = null;
        self.token = null;
    }
};

pub const StringBuilder = struct {
    buffer: std.ArrayList(u8),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .buffer = try std.ArrayList(u8).initCapacity(allocator, 0),
        };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        self.buffer.deinit(allocator);
    }

    pub fn append(self: *Self, allocator: std.mem.Allocator, str: []const u8) !void {
        try self.buffer.appendSlice(allocator, str);
    }

    pub fn appendFmt(self: *Self, allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
        const string = try std.fmt.allocPrint(allocator, fmt, args);
        try self.append(allocator, string);
    }

    pub fn appendLine(self: *Self, allocator: std.mem.Allocator, str: []const u8) !void {
        try self.buffer.appendSlice(allocator, str);
        try self.buffer.append(allocator, '\n');
    }

    pub fn appendLineFmt(self: *Self, allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
        const string = try std.fmt.allocPrint(allocator, fmt, args);
        try self.buffer.appendSlice(allocator, string);
        try self.buffer.append(allocator, '\n');
    }

    pub fn toString(self: *Self) []u8 {
        return self.buffer.items;
    }

    pub fn toOwnedSlice(self: *Self, allocator: std.mem.Allocator) ![]u8 {
        return try self.buffer.toOwnedSlice(allocator);
    }

    pub fn clear(self: *Self) void {
        self.buffer.clearRetainingCapacity();
    }

    pub fn len(self: *Self) usize {
        return self.buffer.items.len;
    }
};
