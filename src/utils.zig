const builtin = @import("builtin");

// https://github.com/ziglang/zig/blob/b57081f039bd3f8f82210e8896e336e3c3a6869b/lib/std/cstr.zig#L7C1-L10C3
pub const line_sep = switch (builtin.os.tag) {
    .windows => "\r\n",
    else => "\n",
};
