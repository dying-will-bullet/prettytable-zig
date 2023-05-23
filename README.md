<img align="left" width="200" height="200" src="https://github.com/Hanaasagi/prettytable-zig/assets/9482395/ae0f259c-08b4-437f-bb9c-281b70bf6271">

<h1 align="center"> prettytable-zig </h1>

> A formatted and aligned table printer library for Zig.
This library is an implementation of [prettytable](https://github.com/jazzband/prettytable) in the Zig programming language.

[![CI](https://github.com/Hanaasagi/prettytable-zig/actions/workflows/ci.yaml/badge.svg)](https://github.com/Hanaasagi/prettytable-zig/actions/workflows/ci.yaml)
![](https://img.shields.io/badge/language-zig-%23ec915c)
![](https://img.shields.io/badge/version-0.1.0--beta.0-%23f05b72)

<br>

**NOTE: Minimum Supported Zig Version -> 0.11**


Table of Contents
=================

* [Features](#features)
* [Getting Started](#getting-started)
  * [Row Operations](#row-operations)
  * [Modify cell data](#modify-cell-data)
  * [Alignment](#alignment)
  * [Read from file/stream/...](#read-from-filestream)
  * [Get the table as string(bytes)](#get-the-table-as-stringbytes)
  * [Change print format](#change-print-format)
  * [Change cell style](#change-cell-style)
* [API](#api)
* [LICENSE](#license)


## Features

- Automatic alignment
- Customizable border
- Color and style 


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

### Alignment

The table is aligned to the left by default. You can change the alignment of the entire table.

```zig
    // table.setAlign(Alignment.left);
    // table.setAlign(Alignment.center);
    table.setAlign(Alignment.right);
```

Or you can change the alignment of a specific column.

```zig
    table.setColumnAlign(1, Alignment.right);

```

### Read from file/stream/...

You can use the `readFrom` function to read data from `Reader` and construct a table.
One scenario is to read data from a CSV file.

```zig
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

### Change cell style

It supports bold, italic, underline styles, and can also set colors.

Color list:

- `black`
- `red`
- `green`
- `yellow`
- `blue`
- `magenta`
- `cyan`
- `white`

If the above names are capitalized, such as `RED`, it indicates a bright color.

```zig
    try table.setCellStyle(0, 0, .{ .bold = true, .fg = .yellow });
    try table.setCellStyle(0, 1, .{ .bold = true, .fg = .red });
    try table.setCellStyle(0, 2, .{ .bold = true, .fg = .magenta });

    try table.setCellStyle(1, 0, .{ .fg = .black, .bg = .cyan });
    try table.setCellStyle(1, 1, .{ .fg = .black, .bg = .blue });
    try table.setCellStyle(1, 2, .{ .fg = .black, .bg = .white });
```

Output:

![2023-05-23_19-33](https://github.com/Hanaasagi/prettytable-zig/assets/9482395/72de3f62-7970-4e73-affd-8ee6d5347799)


## API

TODO: Documentation generator

## LICENSE

MIT
