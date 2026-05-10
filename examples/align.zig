const std = @import("std");
const Table = @import("prettytable").Table;
const Alignment = @import("prettytable").Alignment;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var table = Table.init(allocator);
    defer table.deinit();

    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "foo", "foooooo", "bar" },
        &[_][]const u8{ "1", "2", "3" },
    });

    table.setAlign(Alignment.right);

    try table.printstd(io);
    // +-----+---------+-----+
    // | foo | foooooo | bar |
    // +-----+---------+-----+
    // |   1 |       2 |   3 |
    // +-----+---------+-----+

}
