const std = @import("std");
const pt = @import("prettytable");

pub fn main(init: std.process.Init) !void {
    var table = pt.Table.init(init.gpa);
    defer table.deinit();

    try table.setTitle(&.{ "Name", "Mood" });
    try table.addRow(&.{ "Alice", "😊" });
    try table.addRow(&.{ "张三", "😄" });

    const output = try table.toOwnedSlice(init.gpa);
    defer init.gpa.free(output);

    if (output.len == 0) return error.EmptyOutput;
}
