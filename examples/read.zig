const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const data =
        \\name, id, favorite food
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\
    ;

    var reader: std.Io.Reader = .fixed(data);
    var table = Table.init(std.heap.page_allocator);
    defer table.deinit();

    try table.readFrom(&reader, ",", true);

    try table.printstd(io);
    // +-------+-----+----------------+
    // | name  |  id |  favorite food |
    // +=======+=====+================+
    // | beau  |  2  |  cereal        |
    // +-------+-----+----------------+
    // | abbey |  3  |  pizza         |
    // +-------+-----+----------------+

}
