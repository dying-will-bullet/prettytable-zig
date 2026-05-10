const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const data =
        \\name, id, favorite food
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\
    ;

    var table = Table.init(allocator);
    defer table.deinit();

    try table.readDelimited(data, .{ .separator = ",", .has_title = true });

    try table.printStdout(io);
    // +-------+-----+----------------+
    // | name  |  id |  favorite food |
    // +=======+=====+================+
    // | beau  |  2  |  cereal        |
    // +-------+-----+----------------+
    // | abbey |  3  |  pizza         |
    // +-------+-----+----------------+

}
