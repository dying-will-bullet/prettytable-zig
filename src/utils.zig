const builtin = @import("builtin");
const std = @import("std");
const options = @import("options");

// https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/lib/std/cstr.zig#L7C1-L10C3
pub const line_sep = switch (builtin.os.tag) {
    .windows => if (builtin.is_test) "\n" else "\r\n",
    else => "\n",
};

pub const getStringWidth = switch (options.unicode_backend) {
    .zg, .external_zg => @import("./utils/zg_string_width.zig").getStringWidth,
    .uucode, .external_uucode => @import("./utils/uucode_string_width.zig").getStringWidth,
};

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
