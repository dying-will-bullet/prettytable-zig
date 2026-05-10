const std = @import("std");
const TableFormat = @import("./format.zig").TableFormat;
const Row = @import("./row.zig").Row;
const Cell = @import("./cell.zig").Cell;
const mkRow = @import("./row.zig").row;
const mkRowWithAlign = @import("./row.zig").rowWithAlign;
const FORMAT_DEFAULT = @import("./format.zig").FORMAT_DEFAULT;
const LinePosition = @import("./format.zig").LinePosition;
const Style = @import("./style.zig").Style;
const Alignment = @import("./format.zig").Alignment;
const testing = std.testing;
const eql = std.mem.eql;

pub const Table = struct {
    allocator: std.mem.Allocator,

    format: TableFormat,
    titles: ?Row,
    rows: std.ArrayList(Row),
    // TODO: this is not a good way
    _data: std.ArrayList([]const u8),

    const Self = @This();

    /// Options for `readFrom` and `readDelimited`.
    pub const ReadOptions = struct {
        /// Column separator used to split each input line.
        separator: []const u8 = ",",
        /// Whether the first parsed line should be treated as the table title.
        has_title: bool = false,
    };

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .rows = .empty,
            .titles = null,
            .format = FORMAT_DEFAULT,
            ._data = .empty,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.titles != null) {
            self.titles.?.deinit();
        }
        for (self.rows.items) |*row| {
            row.deinit();
        }

        self.rows.deinit(self.allocator);

        for (self._data.items) |data| {
            self.allocator.free(data);
        }

        self._data.deinit(self.allocator);
    }

    fn getColumnNum(self: Self) usize {
        var cnum: usize = 0;
        if (self.titles != null) {
            cnum += 1;
        }

        for (self.rows.items) |row| {
            const l = row.columnCount();
            if (l > cnum) {
                cnum = l;
            }
        }

        return cnum;
    }

    /// Get the number of rows
    pub fn len(self: Self) usize {
        return self.rows.items.len;
    }

    /// Check if the table slice is empty
    pub fn isEmpty(self: Self) bool {
        return self.rows.len == 0;
    }

    /// Get an immutable reference to a row
    pub fn getRow(self: Self, row: usize) ?Row {
        return self.rows.get(row);
    }
    /// Append a row in the table, transferring ownership of this row to the table
    pub fn addRow(self: *Self, data: []const []const u8) !void {
        const row = try mkRow(
            self.allocator,
            data,
        );

        try self.rows.append(self.allocator, row);
    }

    /// Append a row in the table, transferring ownership of this row to the table
    pub fn addRows(self: *Self, data: []const []const []const u8) !void {
        for (data) |d| {
            const row = try mkRow(
                self.allocator,
                d,
            );

            try self.rows.append(self.allocator, row);
        }
    }

    // pub fn addColumn(self: *Self, data: []const []const u8) !void {
    //     var max_len = 0;
    //     for (self.rows.items) |row| {
    //         const l = row.len();
    //         if (l > max_len) {
    //             max_len = l;
    //         }
    //     }

    //     var r = 0;
    //     for (data) |d| {
    //         if (r >= self.len()) {
    //             var result = try self.allocator.alloc([]const u8, max_len);
    //             std.mem.copy(u8, result[0..max_len-1], home_dir);
    //             std.mem.copy(u8, result[max_len-1..], );

    //             const row = try mkRow(
    //                 self.allocator,
    //                 data,
    //             );
    //         }

    //         r += 1;
    //     }

    //     try self.rows.append(row);
    // }

    /// Insert `row` at the position `index`, and return a mutable reference to this row.
    /// If index is higher than current numbers of rows, `row` is appended at the end of the table
    pub fn insertRow(self: *Self, index: usize, cellData: []const []const u8) !void {
        if (index < self.len()) {
            const row = try mkRow(
                self.allocator,
                cellData,
            );

            try self.rows.insert(self.allocator, index, row);
        } else {
            try self.addRow(cellData);
        }
    }

    /// Remove the row at position `index`. Silently skip if the row does not exist
    pub fn removeRow(self: *Self, index: usize) void {
        if (index < self.len()) {
            var row = self.rows.orderedRemove(index);
            defer row.deinit();
        }
    }

    pub fn setCellStyle(self: *Self, row: usize, column: usize, style: Style) !void {
        if (row >= self.len()) {
            return;
        }

        var row_ = self.rows.items[row];
        try row_.setCellStyle(column, style);
    }

    /// Modify a single element in the table
    pub fn setCell(self: *Self, row: usize, column: usize, data: []const u8) !void {
        if (row >= self.len()) {
            return;
        }
        const new_cell = try Cell.init(self.allocator, data);

        var row_ = self.rows.items[row];
        try row_.setCell(column, new_cell);
    }

    pub fn getCell(self: *Self, row: usize, column: usize) ?Cell {
        if (row >= self.len()) {
            return null;
        }
        const row_ = self.rows.items[row];
        return row_.getCell(column);
    }

    /// Modify a single element in the table
    // pub fn setElement(&mut self, element: &str, column: usize, row: usize) -> Result<(), &str> {
    //     let rowline = self.get_mut_row(row).ok_or("Cannot find row")?;
    //     // TODO: If a cell already exist, copy it's alignment parameter
    //     rowline.set_cell(Cell::new(element), column)
    // }

    /// Change the table format. Eg : Separators
    pub fn setFormat(self: *Self, format: TableFormat) void {
        self.format = format;
    }

    pub fn setAlign(self: *Self, align_: Alignment) void {
        for (self.rows.items) |row| {
            for (0..row.len()) |idx| {
                var cell = &row.cells.items[idx];
                cell.setAlign(align_);
            }
        }
    }

    pub fn setColumnAlign(self: *Self, idx: usize, align_: Alignment) void {
        for (self.rows.items) |row| {
            if (row.len() > idx) {
                var cell = &row.cells.items[idx];
                cell.setAlign(align_);
            }
        }
    }

    pub fn getFormat(self: Self) TableFormat {
        return self.format;
    }

    /// Set the optional title lines
    pub fn setTitle(self: *Self, title: []const []const u8) !void {
        self.titles = try mkRow(
            self.allocator,
            title,
        );
    }

    /// Unset the title line
    pub fn unsetTtile(self: Self) void {
        self.titles = null;
    }

    /// Get the width of the column at position `col_idx`.
    /// Return 0 if the column does not exists;
    fn getColumnWidth(self: Self, col_idx: usize) usize {
        var width: usize = 0;
        if (self.titles != null) {
            width += self.titles.?.getColumnWidth(col_idx, self.format);
        }

        for (self.rows.items) |row| {
            const l = row.getColumnWidth(col_idx, self.format);
            if (l > width) {
                width = l;
            }
        }
        return width;
    }

    /// Get the width of all columns, and return a slice
    /// with the result for each column
    fn getAllColumnWidth(self: Self, allocator: std.mem.Allocator) !std.ArrayList(usize) {
        var colWidth: std.ArrayList(usize) = .empty;
        const colnum = self.getColumnNum();
        var i: usize = 0;
        while (i < colnum) {
            try colWidth.append(allocator, self.getColumnWidth(i));
            i += 1;
        }
        return colWidth;
    }

    /// Read delimited records from a reader and append them into the table.
    /// Parsed fields are owned by the table and released in `deinit`.
    pub fn readFrom(self: *Self, reader: *std.Io.Reader, options: ReadOptions) !void {
        var flag = options.has_title;
        while (try reader.takeDelimiter('\n')) |line| {
            const i = self._data.items.len;
            var it = std.mem.splitSequence(u8, line, options.separator);
            while (it.next()) |data| {
                const new_data = try self.allocator.alloc(u8, data.len);
                @memcpy(new_data, data);
                try self._data.append(self.allocator, new_data);
            }
            if (flag) {
                try self.setTitle(self._data.items[i..]);
                flag = false;
            } else {
                try self.addRow(self._data.items[i..]);
            }
        }
    }

    /// Read delimited records from an in-memory byte slice.
    /// This is a convenience wrapper over `readFrom`.
    pub fn readDelimited(self: *Self, data: []const u8, options: ReadOptions) !void {
        var reader: std.Io.Reader = .fixed(data);
        try self.readFrom(&reader, options);
    }

    /// Write the table to stdout without ANSI styling.
    /// This helper creates a buffered stdout writer and flushes before returning.
    pub fn printStdout(self: Self, io: std.Io) !void {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        const stdout = &stdout_writer.interface;

        try self.write(stdout);
        try stdout.flush();
    }

    /// Write the table to stdout with ANSI styling enabled.
    /// This helper creates a buffered stdout writer and flushes before returning.
    pub fn printStdoutAnsi(self: Self, io: std.Io) !void {
        var stdout_buffer: [1024]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        const stdout = &stdout_writer.interface;

        try self.writeAnsi(stdout);
        try stdout.flush();
    }

    /// Write the table to any `std.Io.Writer` without ANSI styling.
    pub fn write(self: Self, writer: *std.Io.Writer) !void {
        _ = try self.internalWrite(writer, Row.write);
    }

    /// Write the table to any `std.Io.Writer` with ANSI styling.
    pub fn writeAnsi(self: Self, writer: *std.Io.Writer) !void {
        _ = try self.internalWrite(writer, Row.writeAnsi);
    }

    /// Render the table to an owned byte slice without ANSI styling.
    /// The caller owns the returned memory and must free it with `allocator`.
    pub fn toOwnedSlice(self: Self, allocator: std.mem.Allocator) ![]u8 {
        var out: std.Io.Writer.Allocating = .init(allocator);
        defer out.deinit();
        try self.write(&out.writer);
        return try out.toOwnedSlice();
    }

    /// Render the table to an owned byte slice with ANSI styling.
    /// The caller owns the returned memory and must free it with `allocator`.
    pub fn toOwnedSliceAnsi(self: Self, allocator: std.mem.Allocator) ![]u8 {
        var out: std.Io.Writer.Allocating = .init(allocator);
        defer out.deinit();
        try self.writeAnsi(&out.writer);
        return try out.toOwnedSlice();
    }

    fn internalWrite(self: Self, writer: *std.Io.Writer, f: fn (Row, *std.Io.Writer, TableFormat, []const usize) usize) !usize {
        var height: usize = 0;
        var colWidth = try self.getAllColumnWidth(self.allocator);
        defer colWidth.deinit(self.allocator);

        height += try self.format.writeLineSeparator(writer, colWidth.items, LinePosition.top);
        if (self.titles != null) {
            height += f(self.titles.?, writer, self.format, colWidth.items);
            height += try self.format.writeLineSeparator(writer, colWidth.items, LinePosition.title);
        }

        for (0..self.rows.items.len) |i| {
            const r = self.rows.items[i];
            height += f(r, writer, self.format, colWidth.items);
            if (i + 1 < self.rows.items.len) {
                height += try self.format.writeLineSeparator(writer, colWidth.items, LinePosition.intern);
            }
        }

        height += try self.format.writeLineSeparator(writer, colWidth.items, LinePosition.bottom);

        return height;
    }
};

test "test write table" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "ABC", "DEFG", "HIJKLMN" };

    var table = Table.init(gpa);
    defer table.deinit();
    try table.addRow(&row1);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+-----+------+---------+
        \\| ABC | DEFG | HIJKLMN |
        \\+-----+------+---------+
        \\
    ;
    try testing.expectEqualStrings(
        expect,
        out.written(),
    );
}

test "test table to owned slice" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "ABC", "DEFG", "HIJKLMN" };

    var table = Table.init(gpa);
    defer table.deinit();
    try table.addRow(&row1);

    const output = try table.toOwnedSlice(gpa);
    defer gpa.free(output);

    const expect =
        \\+-----+------+---------+
        \\| ABC | DEFG | HIJKLMN |
        \\+-----+------+---------+
        \\
    ;
    try testing.expectEqualStrings(expect, output);
}

test "test write ansi table" {
    const gpa = testing.allocator;

    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&[_][]const u8{"1"});
    try table.setCellStyle(0, 0, .{ .bold = true, .fg = .red });

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.writeAnsi(&out.writer);

    const expect = [_]u8{ 43, 45, 45, 45, 43, 10, 124, 32, 27, 91, 51, 49, 59, 52, 57, 59, 49, 109, 49, 27, 91, 48, 109, 32, 124, 10, 43, 45, 45, 45, 43, 10 };
    try testing.expect(eql(u8, out.written(), &expect));
}

test "test write mulitline table" {
    const gpa = testing.allocator;
    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "ABC", "DEFG", "HIJKLMN" },
        &[_][]const u8{ "foobar", "foo", "bar" },
        &[_][]const u8{ "1", "2", "3" },
    });

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+--------+------+---------+
        \\| ABC    | DEFG | HIJKLMN |
        \\+--------+------+---------+
        \\| foobar | foo  | bar     |
        \\+--------+------+---------+
        \\| 1      | 2    | 3       |
        \\+--------+------+---------+
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test write table with title" {
    const gpa = testing.allocator;
    const title = [_][]const u8{ "col1", "col2", "col3" };
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&row1);
    try table.setTitle(&title);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+--------+------+------+
        \\| col1   | col2 | col3 |
        \\+========+======+======+
        \\| foobar | foo  | bar  |
        \\+--------+------+------+
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test write table with format" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };

    var table = Table.init(gpa);
    defer table.deinit();
    try table.addRow(&row1);
    table.setFormat(@import("./format.zig").FORMAT_BOX_CHARS);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\┌────────┬─────┬─────┐
        \\│ foobar │ foo │ bar │
        \\└────────┴─────┴─────┘
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test write table with mulitline cell" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "foo\nbar", "foo", "bar" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&row1);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+-----+-----+-----+
        \\| foo | foo | bar |
        \\| bar |     |     |
        \\+-----+-----+-----+
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test write table with inconsistent columns" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };
    const row2 = [_][]const u8{ "1", "2" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+--------+-----+-----+
        \\| foobar | foo | bar |
        \\+--------+-----+-----+
        \\| 1      | 2   |     |
        \\+--------+-----+-----+
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test nest table" {
    const gpa = testing.allocator;
    // Nest Table
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };
    const row2 = [_][]const u8{ "1", "2" };

    var table1 = Table.init(testing.allocator);
    defer table1.deinit();

    try table1.addRow(&row1);
    try table1.addRow(&row2);

    var out1: std.Io.Writer.Allocating = .init(gpa);
    defer out1.deinit();
    try table1.write(&out1.writer);

    // Table 2
    const row3 = [_][]const u8{ "A", "B", "C" };
    const row4 = [_][]const u8{ "1", "2", out1.written() };

    var table2 = Table.init(testing.allocator);
    defer table2.deinit();

    try table2.addRow(&row3);
    try table2.addRow(&row4);

    var out2: std.Io.Writer.Allocating = .init(gpa);
    defer out2.deinit();
    try table2.write(&out2.writer);

    const expect =
        \\+---+---+------------------------+
        \\| A | B | C                      |
        \\+---+---+------------------------+
        \\| 1 | 2 | +--------+-----+-----+ |
        \\|   |   | | foobar | foo | bar | |
        \\|   |   | +--------+-----+-----+ |
        \\|   |   | | 1      | 2   |     | |
        \\|   |   | +--------+-----+-----+ |
        \\|   |   |                        |
        \\+---+---+------------------------+
        \\
    ;
    try testing.expectEqualStrings(expect, out2.written());
}

test "test insert and remove row" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };
    const row2 = [_][]const u8{ "1", "2" };
    const row3 = [_][]const u8{ "ABC", "DEFG", "HIJKLMN" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);
    try table.insertRow(0, &row3);
    table.removeRow(1);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+-----+------+---------+
        \\| ABC | DEFG | HIJKLMN |
        \\+-----+------+---------+
        \\| 1   | 2    |         |
        \\+-----+------+---------+
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test get and set cell" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };
    const row2 = [_][]const u8{ "1", "2" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);

    try testing.expect(table.getCell(0, 0) != null);

    try table.setCell(0, 0, "FOOBAR");

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+--------+-----+-----+
        \\| FOOBAR | foo | bar |
        \\+--------+-----+-----+
        \\| 1      | 2   |     |
        \\+--------+-----+-----+
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test table alignment" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "foo", "foooooo", "bar" };
    const row2 = [_][]const u8{ "1", "2", "3" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);

    table.setAlign(Alignment.right);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+-----+---------+-----+
        \\| foo | foooooo | bar |
        \\+-----+---------+-----+
        \\|   1 |       2 |   3 |
        \\+-----+---------+-----+
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test column alignment" {
    const gpa = testing.allocator;
    const row1 = [_][]const u8{ "foo", "foooooo", "bar" };
    const row2 = [_][]const u8{ "1", "2", "3" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);

    table.setColumnAlign(1, Alignment.right);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    const expect =
        \\+-----+---------+-----+
        \\| foo | foooooo | bar |
        \\+-----+---------+-----+
        \\| 1   |       2 | 3   |
        \\+-----+---------+-----+
        \\
    ;
    try testing.expectEqualStrings(expect, out.written());
}

test "test read from" {
    const gpa = testing.allocator;
    const data =
        \\quincy, 1, hot dogs
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\mrugesh, 4, ice cream
        \\
    ;

    var reader: std.Io.Reader = .fixed(data);

    var table = Table.init(gpa);
    defer table.deinit();

    try table.readFrom(&reader, .{ .separator = ",", .has_title = false });

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);
    const expect =
        \\+---------+----+------------+
        \\| quincy  |  1 |  hot dogs  |
        \\+---------+----+------------+
        \\| beau    |  2 |  cereal    |
        \\+---------+----+------------+
        \\| abbey   |  3 |  pizza     |
        \\+---------+----+------------+
        \\| mrugesh |  4 |  ice cream |
        \\+---------+----+------------+
        \\
    ;

    try testing.expectEqualStrings(expect, out.written());
}

test "test read from with title" {
    const gpa = testing.allocator;
    const data =
        \\name, id, favorite food
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\
    ;

    var reader: std.Io.Reader = .fixed(data);

    var table = Table.init(gpa);
    defer table.deinit();

    try table.readFrom(&reader, .{ .separator = ",", .has_title = true });

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);
    const expect =
        \\+-------+-----+----------------+
        \\| name  |  id |  favorite food |
        \\+=======+=====+================+
        \\| beau  |  2  |  cereal        |
        \\+-------+-----+----------------+
        \\| abbey |  3  |  pizza         |
        \\+-------+-----+----------------+
        \\
    ;

    try testing.expectEqualStrings(expect, out.written());
}

test "test read delimited with title" {
    const gpa = testing.allocator;
    const data =
        \\name, id, favorite food
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\
    ;

    var table = Table.init(gpa);
    defer table.deinit();

    try table.readDelimited(data, .{ .separator = ",", .has_title = true });

    const output = try table.toOwnedSlice(gpa);
    defer gpa.free(output);

    const expect =
        \\+-------+-----+----------------+
        \\| name  |  id |  favorite food |
        \\+=======+=====+================+
        \\| beau  |  2  |  cereal        |
        \\+-------+-----+----------------+
        \\| abbey |  3  |  pizza         |
        \\+-------+-----+----------------+
        \\
    ;

    try testing.expectEqualStrings(expect, output);
}

test "test color" {
    const gpa = testing.allocator;
    var table = Table.init(gpa);
    defer table.deinit();

    try table.addRow(&[_][]const u8{"1"});
    try table.setCellStyle(0, 0, .{ .bold = true, .fg = .red });

    const output = try table.toOwnedSliceAnsi(gpa);
    defer gpa.free(output);
    const expect = [_]u8{ 43, 45, 45, 45, 43, 10, 124, 32, 27, 91, 51, 49, 59, 52, 57, 59, 49, 109, 49, 27, 91, 48, 109, 32, 124, 10, 43, 45, 45, 45, 43, 10 };

    try testing.expect(eql(u8, output, &expect));
}

test "test table with unicode characters" {
    const gpa = testing.allocator;

    const row1 = [_][]const u8{ "姓名", "年龄", "职业" };
    const row2 = [_][]const u8{ "张三", "25", "工程师" };
    const row3 = [_][]const u8{ "李四", "30", "设计师" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.setTitle(&row1);
    try table.addRow(&row2);
    try table.addRow(&row3);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    // Verify output contains correct Unicode characters
    try testing.expect(std.mem.indexOf(u8, out.written(), "姓名") != null);
    try testing.expect(std.mem.indexOf(u8, out.written(), "张三") != null);
    try testing.expect(std.mem.indexOf(u8, out.written(), "工程师") != null);
}

test "test table with emoji" {
    const gpa = testing.allocator;

    const row1 = [_][]const u8{ "Name", "Mood", "Status" };
    const row2 = [_][]const u8{ "Alice", "😊", "Happy" };
    const row3 = [_][]const u8{ "Bob", "😢", "Sad" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.setTitle(&row1);
    try table.addRow(&row2);
    try table.addRow(&row3);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    // Verify output contains correct emoji
    try testing.expect(std.mem.indexOf(u8, out.written(), "😊") != null);
    try testing.expect(std.mem.indexOf(u8, out.written(), "😢") != null);
}

test "test table mixed unicode and ascii" {
    const gpa = testing.allocator;

    const row1 = [_][]const u8{ "Product", "Price", "Review" };
    const row2 = [_][]const u8{ "苹果", "$2.99", "很好 👍" };
    const row3 = [_][]const u8{ "香蕉", "$1.99", "不错 😊" };

    var table = Table.init(gpa);
    defer table.deinit();

    try table.setTitle(&row1);
    try table.addRow(&row2);
    try table.addRow(&row3);

    var out: std.Io.Writer.Allocating = .init(gpa);
    defer out.deinit();
    try table.write(&out.writer);

    // Verify output contains mixed characters
    try testing.expect(std.mem.indexOf(u8, out.written(), "苹果") != null);
    try testing.expect(std.mem.indexOf(u8, out.written(), "👍") != null);
    try testing.expect(std.mem.indexOf(u8, out.written(), "😊") != null);
}
