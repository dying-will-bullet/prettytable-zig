const builtin = @import("builtin");
const std = @import("std");
const DisplayWidth = @import("DisplayWidth");

// https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/lib/std/cstr.zig#L7C1-L10C3
pub const line_sep = switch (builtin.os.tag) {
    .windows => if (builtin.is_test) "\n" else "\r\n",
    else => "\n",
};

// Unicode display width calculator instance
var display_width_instance: ?DisplayWidth = null;

/// Get display width of a string
pub fn getStringWidth(text: []const u8) usize {
    return DisplayWidth.strWidth(text);
}

// Test Unicode width calculation
test "Unicode width calculation" {

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
    try std.testing.expectEqual(@as(usize, 4), getStringWidth("你好")); // 6 bytes for 2 chinese characters

    _ = allocator; // Avoid unused warning
}
