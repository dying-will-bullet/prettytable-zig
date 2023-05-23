const std = @import("std");
const pt = @import("prettytable");
const Table = pt.Table;

pub fn main() !void {
    var table = Table.init(std.heap.page_allocator);
    defer table.deinit();

    try table.setTitle(&[_][]const u8{ "col1", "col2", "col3" });
    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "ABCD", "EFG", "HI" },
        &[_][]const u8{ "foo", "bar", "foobar" },
    });

    std.debug.print("\n\n{s}\n", .{"FORMAT_DEFAULT"});
    table.setFormat(pt.FORMAT_DEFAULT);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_NO_TITLE"});
    table.setFormat(pt.FORMAT_NO_TITLE);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_NO_LINESEP_WITH_TITLE"});
    table.setFormat(pt.FORMAT_NO_LINESEP_WITH_TITLE);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_NO_LINESEP"});
    table.setFormat(pt.FORMAT_NO_LINESEP);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_NO_COLSEP"});
    table.setFormat(pt.FORMAT_NO_COLSEP);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_CLEAN"});
    table.setFormat(pt.FORMAT_CLEAN);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_BORDERS_ONLY"});
    table.setFormat(pt.FORMAT_BORDERS_ONLY);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_NO_BORDER"});
    table.setFormat(pt.FORMAT_NO_BORDER);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_NO_BORDER_LINE_SEPARATOR"});
    table.setFormat(pt.FORMAT_NO_BORDER_LINE_SEPARATOR);
    try table.printstd();

    std.debug.print("\n\n{s}\n", .{"FORMAT_BOX_CHARS"});
    table.setFormat(pt.FORMAT_BOX_CHARS);
    try table.printstd();

    // FORMAT_DEFAULT
    // +------+------+--------+
    // | col1 | col2 | col3   |
    // +======+======+========+
    // | ABCD | EFG  | HI     |
    // +------+------+--------+
    // | foo  | bar  | foobar |
    // +------+------+--------+

    // FORMAT_NO_TITLE
    // +------+------+--------+
    // | col1 | col2 | col3   |
    // +------+------+--------+
    // | ABCD | EFG  | HI     |
    // +------+------+--------+
    // | foo  | bar  | foobar |
    // +------+------+--------+

    // FORMAT_NO_LINESEP_WITH_TITLE
    // +------+------+--------+
    // | col1 | col2 | col3   |
    // +------+------+--------+
    // | ABCD | EFG  | HI     |
    // | foo  | bar  | foobar |
    // +------+------+--------+

    // FORMAT_NO_LINESEP
    // +------+------+--------+
    // | col1 | col2 | col3   |
    // | ABCD | EFG  | HI     |
    // | foo  | bar  | foobar |
    // +------+------+--------+

    // FORMAT_NO_COLSEP
    // --------------------
    //  col1  col2  col3
    // ====================
    //  ABCD  EFG   HI
    // --------------------
    //  foo   bar   foobar
    // --------------------

    // FORMAT_CLEAN
    //  col1  col2  col3
    //  ABCD  EFG   HI
    //  foo   bar   foobar

    // FORMAT_BORDERS_ONLY
    // +--------------------+
    // | col1  col2  col3   |
    // +====================+
    // | ABCD  EFG   HI     |
    // | foo   bar   foobar |
    // +--------------------+

    // FORMAT_NO_BORDER
    //  col1 | col2 | col3
    // ======+======+========
    //  ABCD | EFG  | HI
    // ------+------+--------
    //  foo  | bar  | foobar

    // FORMAT_NO_BORDER_LINE_SEPARATOR
    //  col1 | col2 | col3
    // ------+------+--------
    //  ABCD | EFG  | HI
    //  foo  | bar  | foobar

    // FORMAT_BOX_CHARS
    // ┌──────┬──────┬────────┐
    // │ col1 │ col2 │ col3   │
    // ├──────┼──────┼────────┤
    // │ ABCD │ EFG  │ HI     │
    // ├──────┼──────┼────────┤
    // │ foo  │ bar  │ foobar │
    // └──────┴──────┴────────┘
}
