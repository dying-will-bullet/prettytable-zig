const builtin = @import("builtin");
const std = @import("std");
const DisplayWidth = @import("DisplayWidth");

// https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/lib/std/cstr.zig#L7C1-L10C3
pub const line_sep = switch (builtin.os.tag) {
    .windows => "\r\n",
    else => "\n",
};

// Unicode display width calculator instance
var display_width_instance: ?DisplayWidth = null;

/// Initialize Unicode display width calculator
pub fn initDisplayWidth(allocator: std.mem.Allocator) !void {
    if (display_width_instance == null) {
        display_width_instance = try DisplayWidth.init(allocator);
    }
}

/// Deinitialize Unicode display width calculator
pub fn deinitDisplayWidth(allocator: std.mem.Allocator) void {
    if (display_width_instance) |dw| {
        dw.deinit(allocator);
        display_width_instance = null;
    }
}

/// Get display width of a string
pub fn getStringWidth(text: []const u8) usize {
    if (display_width_instance) |dw| {
        return dw.strWidth(text);
    }
    // If not initialized, fallback to byte length
    return text.len;
}

// Test Unicode width calculation
test "Unicode width calculation" {
    const allocator = std.testing.allocator;

    // Initialize Unicode display width calculator
    try initDisplayWidth(allocator);
    defer deinitDisplayWidth(allocator);

    // Test ASCII characters
    try std.testing.expectEqual(@as(usize, 5), getStringWidth("Hello"));

    // Test Chinese characters
    try std.testing.expectEqual(@as(usize, 4), getStringWidth("你好"));

    // Test emoji
    try std.testing.expectEqual(@as(usize, 2), getStringWidth("😊"));

    // Test mixed characters
    try std.testing.expectEqual(@as(usize, 8), getStringWidth("Hello 😊"));
    try std.testing.expectEqual(@as(usize, 8), getStringWidth("Hello 你"));

    // Test Korean characters
    try std.testing.expectEqual(@as(usize, 10), getStringWidth("안녕하세요"));
}

test "Unicode width fallback" {
    const allocator = std.testing.allocator;

    // Without initializing Unicode width calculator, should fallback to byte length
    try std.testing.expectEqual(@as(usize, 5), getStringWidth("Hello"));
    // Chinese characters have different byte length and display width
    try std.testing.expectEqual(@as(usize, 6), getStringWidth("你好")); // 6 bytes for 2 chinese characters

    _ = allocator; // Avoid unused warning
}
