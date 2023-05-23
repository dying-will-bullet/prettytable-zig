const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main() !void {
    var table1 = Table.init(std.heap.page_allocator);
    defer table1.deinit();

    try table1.addRows(&[_][]const []const u8{
        &[_][]const u8{ "foobar", "foo", "bar" },
        &[_][]const u8{ "1", "2" },
    });

    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buf.deinit();
    var out = buf.writer();
    _ = try table1.print(out);

    var table2 = Table.init(std.heap.page_allocator);
    defer table2.deinit();

    try table2.addRows(&[_][]const []const u8{
        &[_][]const u8{ "A", "B", "C" },
        &[_][]const u8{ "This is\na multiline\ncell", "2", buf.items },
    });

    try table2.printstd();

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
