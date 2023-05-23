const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main() !void {
    // Create ad table
    var table = Table.init(std.heap.page_allocator);
    defer table.deinit();

    // add some rows
    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "A", "B", "C" },
        &[_][]const u8{ "foo", "foo\nbar", "bar" },
    });
    // add single row
    try table.addRow(&[_][]const u8{ "1", "2", "3" });

    try table.printstd();
    // +-----+-----+-----+
    // | A   | B   | C   |
    // +-----+-----+-----+
    // | foo | foo | bar |
    // |     | bar |     |
    // +-----+-----+-----+
    // | 1   | 2   | 3   |
    // +-----+-----+-----+
}
