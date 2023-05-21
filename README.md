# prettytable-zig

Display tabular data in a visually appealing ASCII table format.

### Tutorial

```zig
const std = @import("std");
const Table = @import("prettytable").Table;
const FORMAT_BOX_CHARS = @import("prettytable").FORMAT_BOX_CHARS;

pub fn main() !void {
    const row1 = [_][]const u8{ "Cell1", "cell2", "Cell3" };
    const row2 = [_][]const u8{ "foo", "bar", "foo\nbar" };

    var table = Table.init(std.heap.page_allocator);
    defer table.deinit();

    table.setFormat(FORMAT_BOX_CHARS);
    try table.addRow(&row1);
    try table.addRow(&row2);

    table.printstd();
}
```

Output:

```
┌───────┬───────┬───────┐
│ Cell1 │ cell2 │ Cell3 │
├───────┼───────┼───────┤
│ foo   │ bar   │ foo   │
│       │       │ bar   │
└───────┴───────┴───────┘
```

### API

### LICENSE

MIT
