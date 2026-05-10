<!-- <img align="left" width="200" height="200" src="https://github.com/Hanaasagi/prettytable-zig/assets/9482395/ae0f259c-08b4-437f-bb9c-281b70bf6271"> -->

<img align="left" width="200" height="200" src="https://github.com/Hanaasagi/prettytable-zig/assets/9482395/6e39d461-1c0e-4d86-ba57-885388952bd7">

<h1 align="center"> prettytable-zig </h1>

> A formatted and aligned table printer library for Zig.
> This library is an implementation of [prettytable](https://github.com/jazzband/prettytable) in the Zig programming language.

[![CI](https://github.com/Hanaasagi/prettytable-zig/actions/workflows/ci.yaml/badge.svg)](https://github.com/Hanaasagi/prettytable-zig/actions/workflows/ci.yaml)
![](https://img.shields.io/badge/language-zig-%23ec915c)
![](https://img.shields.io/badge/version-0.3.0)

<br>

**NOTE: Minimum Supported Zig Version: zig 0.16.0. Any suggestions or feedback are welcome.**

# Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
  - [Row Operations](#row-operations)
  - [Modify cell data](#modify-cell-data)
  - [Alignment](#alignment)
  - [Unicode Support](#unicode-support)
  - [Read from file/stream/...](#read-from-filestream)
  - [Get the table as string(bytes)](#get-the-table-as-stringbytes)
  - [Change print format](#change-print-format)
  - [Change cell style](#change-cell-style)
- [API](#api)
- [LICENSE](#license)

## Features

- Automatic alignment
- Customizable border
- Color and style
- **Unicode width support** - Correct display width calculation for Unicode characters including Chinese, Japanese, Korean, and emoji

## Getting Started

Let's start with an example. All example code can be found in the `examples` directory and can be run with `zig build examples`.

```zig
const std = @import("std");
const pt = @import("prettytable");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var table = pt.Table.init(allocator);
    defer table.deinit();

    try table.setTitle(&.{
        "City", "Country", "Longitude", "Latitude", " Temperature", "Humidity",
    });

    try table.addRows(&.{
        &.{ "Caconda", "AO", "15.06", "-13.73", "26.15", "35" },
        &.{ "Diamantino", "BR", "-56.44", "-14.4", "29.4", "74" },
        &.{ "Hirara", "JP", "125.28", "24.8", "21.77", "100" },
        &.{ "Abha", "SA", "42.5", "18.22", "14.03", "100" },
    });

    try table.printstd(io);
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

### Unicode Support

**prettytable-zig** now supports Unicode width calculation for proper alignment of international characters and emoji. The library automatically handles the display width of:

- **Chinese characters**: 你好 (each character takes 2 display columns)
- **Japanese characters**: こんにちは (hiragana, katakana, kanji)
- **Korean characters**: 안녕하세요 (Hangul characters)
- **Emoji**: 😊🍎🔥 (most emoji take 2 display columns)
- **Mixed content**: combinations of ASCII and Unicode characters

Example with Unicode characters:

```zig
const std = @import("std");
const pt = @import("prettytable");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var table = pt.Table.init(allocator);
    defer table.deinit();

    try table.setTitle(&.{ "Name", "Greeting", "Mood" });
    try table.addRow(&.{ "Alice", "Hello", "😊" });
    try table.addRow(&.{ "张三", "你好", "😄" });
    try table.addRow(&.{ "田中", "こんにちは", "🙂" });
    try table.addRow(&.{ "김철수", "안녕하세요", "😃" });

    try table.printstd(io);
}
```

Output:
```
+--------+------------+------+
| Name   | Greeting   | Mood |
+========+============+======+
| Alice  | Hello      | 😊   |
+--------+------------+------+
| 张三   | 你好       | 😄   |
+--------+------------+------+
| 田中   | こんにちは | 🙂   |
+--------+------------+------+
| 김철수 | 안녕하세요 | 😃   |
+--------+------------+------+
```

The Unicode support is powered by the [zg library](https://codeberg.org/atman/zg) and is available automatically.

### Read from file/stream/...

You can use the `readFrom` function to read data from `Reader` and construct a table.
One scenario is to read data from a CSV file.

```zig
    const data =
        \\name, id, favorite food
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\
    ;

    var reader: std.Io.Reader = .fixed(data);
    var table = Table.init(init.gpa);
    defer table.deinit();

    try table.readFrom(&reader, ",", true);

    try table.printstd(io);
```

### Get the table as string(bytes)

```zig
    var out: std.Io.Writer.Allocating = .init(init.gpa);
    defer out.deinit();
    _ = try table.print(&out.writer);

    // out.written() is the bytes of table
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

[Online Docs](https://dying-will-bullet.github.io/prettytable-zig/)

## LICENSE

MIT
