const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var table1 = Table.init(allocator);
    defer table1.deinit();

    try table1.addRows(&[_][]const []const u8{
        &[_][]const u8{ "foobar", "foo", "bar" },
        &[_][]const u8{ "1", "2" },
    });

    var out: std.Io.Writer.Allocating = .init(allocator);
    defer out.deinit();
    _ = try table1.print(&out.writer);

    var table2 = Table.init(allocator);
    defer table2.deinit();

    try table2.addRows(&[_][]const []const u8{
        &[_][]const u8{ "A", "B", "C" },
        &[_][]const u8{ "This is\na multiline\ncell", "2", out.written() },
    });

    try table2.printstd(io);

    // +-------------+---+------------------------+
    // | A           | B | C                      |
    // +-------------+---+------------------------+
    // | This is     | 2 | +--------+-----+-----+ |
    // | a multiline |   | | foobar | foo | bar | |
    // | cell        |   | +--------+-----+-----+ |
    // |             |   | | 1      | 2   |     | |
    // |             |   | +--------+-----+-----+ |
    // |             |   |                        |
    // +-------------+---+------------------------+
}
