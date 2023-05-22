# prettytable-zig

[![CI](https://github.com/Hanaasagi/prettytable-zig/actions/workflows/ci.yaml/badge.svg)](https://github.com/Hanaasagi/prettytable-zig/actions/workflows/ci.yaml)

A formatted and aligned table printer library for Zig.
This library is an implementation of [prettytable](https://github.com/jazzband/prettytable) in the Zig programming language.

## Getting Started

Let's start with an example.

```zig
const std = @import("std");
const pt = @import("prettytable");

pub fn main() !void {
    var table = pt.Table.init(std.heap.page_allocator);
    defer table.deinit();

    try table.setTitle(&[_][]const u8{
        "City", "Country", "Longitude", "Latitude", " Temperature", "Humidity",
    });

    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "Caconda", "AO", "15.06", "-13.73", "26.15", "35" },
        &[_][]const u8{ "Diamantino", "BR", "-56.44", "-14.4", "29.4", "74" },
        &[_][]const u8{ "Hirara", "JP", "125.28", "24.8", "21.77", "100" },
        &[_][]const u8{ "Abha", "SA", "42.5", "18.22", "14.03", "100" },
    });

    table.printstd();
}
```

Output:

```
+---------------+---------+-----------+----------+--------------+----------+
| City          | Country | Longitude | Latitude |  Temperature | Humidity |
+===============+=========+===========+==========+==============+==========+
| Prince Rupert | CA      | -130.32   | 54.32    | 7.0          | 87       |
+---------------+---------+-----------+----------+--------------+----------+
| Caconda       | AO      | 15.06     | -13.73   | 26.15        | 35       |
+---------------+---------+-----------+----------+--------------+----------+
| Diamantino    | BR      | -56.44    | -14.4    | 29.4         | 74       |
+---------------+---------+-----------+----------+--------------+----------+
| Hirara        | JP      | 125.28    | 24.8     | 21.77        | 100      |
+---------------+---------+-----------+----------+--------------+----------+
| Abha          | SA      | 42.5      | 18.22    | 14.03        | 100      |
+---------------+---------+-----------+----------+--------------+----------+
```

### Row Operations

Add a row to the table.

```zig
    try table.addRow(
        &[_][]const u8{ "Kaseda", "JP", "130.32", "31.42", "13.37", "100" },
    );

```

Insert a row.

```zig
    try table.insertRow(
        0,
        &[_][]const u8{ "Kaseda", "JP", "130.32", "31.42", "13.37", "100" },
    );
```

Remove a row from the table.

```zig
    table.removeRow(0);
```

### Modify cell data

```zig
    try table.setCell(0, 5, "100");
```

### Get the table as string(bytes)

```zig
    var buf = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buf.deinit();

    var out = buf.writer();
    _ = try table.print(out);

    // buf.items is the bytes of table
```

### Change print format

```zig
    table.setFormat(pt.FORMAT_BORDERS_ONLY);
```

Output:

```
+---------------------------------------------------------------------+
| City           Country  Longitude  Latitude   Temperature  Humidity |
+=====================================================================+
| Prince Rupert  CA       -130.32    54.32     7.0           87       |
| Caconda        AO       15.06      -13.73    26.15         35       |
| Diamantino     BR       -56.44     -14.4     29.4          74       |
| Hirara         JP       125.28     24.8      21.77         100      |
| Abha           SA       42.5       18.22     14.03         100      |
+---------------------------------------------------------------------+
```

## API

TODO: Documentation generator

## LICENSE

MIT
