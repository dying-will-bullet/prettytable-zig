pub const Table = @import("./table.zig").Table;
pub const Cell = @import("./cell.zig").Cell;
pub const Row = @import("./row.zig").Row;
pub const Alignment = @import("./format.zig").Alignment;
pub const Color = @import("./style.zig").Color;
pub const Style = @import("./style.zig").Style;

// Some builtin format
pub const FORMAT_DEFAULT = @import("./format.zig").FORMAT_DEFAULT;
pub const FORMAT_NO_TITLE = @import("./format.zig").FORMAT_NO_TITLE;
pub const FORMAT_NO_LINESEP_WITH_TITLE = @import("./format.zig").FORMAT_NO_LINESEP_WITH_TITLE;
pub const FORMAT_NO_LINESEP = @import("./format.zig").FORMAT_NO_LINESEP;
pub const FORMAT_NO_COLSEP = @import("./format.zig").FORMAT_NO_COLSEP;
pub const FORMAT_CLEAN = @import("./format.zig").FORMAT_CLEAN;
pub const FORMAT_BORDERS_ONLY = @import("./format.zig").FORMAT_BORDERS_ONLY;
pub const FORMAT_NO_BORDER = @import("./format.zig").FORMAT_NO_BORDER;
pub const FORMAT_NO_BORDER_LINE_SEPARATOR = @import("./format.zig").FORMAT_NO_BORDER_LINE_SEPARATOR;
pub const FORMAT_BOX_CHARS = @import("./format.zig").FORMAT_BOX_CHARS;

// pub fn main() !void {
//     const std = @import("std");
//     // Create ad table
//     var table = Table.init(std.heap.page_allocator);
//     defer table.deinit();

//     // add single row
//     try table.addRow(&[_][]const u8{ "1", "2", "3" });
//     try table.addRow(&[_][]const u8{ "4", "5", "6" });
//     try table.setCellStyle(0, 1, .{ .bold = true, .fg = .red });

//     try table.print_tty(true);
//     // +-----+-----+-----+
//     // | A   | B   | C   |
//     // +-----+-----+-----+
//     // | foo | foo | bar |
//     // |     | bar |     |
//     // +-----+-----+-----+
//     // | 1   | 2   | 3   |
//     // +-----+-----+-----+
// }
