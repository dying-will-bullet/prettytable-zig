const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    // Create ad table
    var table = Table.init(allocator);
    defer table.deinit();

    // add some rows
    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "A", "B", "C" },
        &[_][]const u8{ "foo", "foo\nbar", "bar" },
    });
    // add single row
    try table.addRow(&[_][]const u8{ "1", "2", "3" });

    try table.printStdout(io);
    // +-----+-----+-----+
    // | A   | B   | C   |
    // +-----+-----+-----+
    // | foo | foo | bar |
    // |     | bar |     |
    // +-----+-----+-----+
    // | 1   | 2   | 3   |
    // +-----+-----+-----+
}
