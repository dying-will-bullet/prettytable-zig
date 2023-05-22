const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main() !void {
    var data =
        \\name, id, favorite food
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\
    ;

    var s = std.io.fixedBufferStream(data);
    var reader = s.reader();
    var table = Table.init(std.heap.page_allocator);
    defer table.deinit();

    var read_buf: [1024]u8 = undefined;
    try table.readFrom(reader, &read_buf, ",", true);

    table.printstd();
    // +-------+-----+----------------+
    // | name  |  id |  favorite food |
    // +=======+=====+================+
    // | beau  |  2  |  cereal        |
    // +-------+-----+----------------+
    // | abbey |  3  |  pizza         |
    // +-------+-----+----------------+

}
