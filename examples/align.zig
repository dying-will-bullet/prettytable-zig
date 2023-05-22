const std = @import("std");
const Table = @import("prettytable").Table;
const Alignment = @import("prettytable").Alignment;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main() !void {
    var table = Table.init(std.heap.page_allocator);
    defer table.deinit();

    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "foo", "foooooo", "bar" },
        &[_][]const u8{ "1", "2", "3" },
    });

    table.setAlign(Alignment.right);

    table.printstd();
    // +-----+---------+-----+
    // | foo | foooooo | bar |
    // +-----+---------+-----+
    // |   1 |       2 |   3 |
    // +-----+---------+-----+

}
