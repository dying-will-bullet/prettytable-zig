const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main() !void {
    var table = Table.init(std.heap.page_allocator);
    defer table.deinit();

    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "1", "2", "3" },
        &[_][]const u8{ "4", "5", "6" },
    });

    try table.setCellStyle(0, 0, .{ .bold = true, .fg = .yellow });
    try table.setCellStyle(0, 1, .{ .bold = true, .fg = .red });
    try table.setCellStyle(0, 2, .{ .bold = true, .fg = .magenta });

    try table.setCellStyle(1, 0, .{ .fg = .black, .bg = .cyan });
    try table.setCellStyle(1, 1, .{ .fg = .black, .bg = .blue });
    try table.setCellStyle(1, 2, .{ .fg = .black, .bg = .white });
    _ = try table.print_tty(true);
}
