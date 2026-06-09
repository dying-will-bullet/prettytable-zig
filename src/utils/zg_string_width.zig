const DisplayWidth = @import("DisplayWidth");

pub fn getStringWidth(text: []const u8) usize {
    return DisplayWidth.strWidth(text);
}
