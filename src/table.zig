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
const initDisplayWidth = @import("./utils.zig").initDisplayWidth;
const deinitDisplayWidth = @import("./utils.zig").deinitDisplayWidth;
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

    pub fn init(allocator: std.mem.Allocator) Self {
        // Initialize Unicode display width calculator
        initDisplayWidth(allocator) catch {};

        return Self{
            .allocator = allocator,
            .rows = std.ArrayList(Row).init(allocator),
            .titles = null,
            .format = FORMAT_DEFAULT,
            ._data = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        if (self.titles != null) {
            self.titles.?.deinit();
        }
        for (self.rows.items) |row| {
            row.deinit();
        }

        self.rows.deinit();

        for (self._data.items) |data| {
            self.allocator.free(data);
        }

        self._data.deinit();

        // Deinitialize Unicode display width calculator
        deinitDisplayWidth(self.allocator);
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

        try self.rows.append(row);
    }

    /// Append a row in the table, transferring ownership of this row to the table
    pub fn addRows(self: *Self, data: []const []const []const u8) !void {
        for (data) |d| {
            const row = try mkRow(
                self.allocator,
                d,
            );

            try self.rows.append(row);
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

            try self.rows.insert(index, row);
        } else {
            try self.addRow(cellData);
        }
    }

    /// Remove the row at position `index`. Silently skip if the row does not exist
    pub fn removeRow(self: *Self, index: usize) void {
        if (index < self.len()) {
            const row = self.rows.orderedRemove(index);
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
        var colWidth = std.ArrayList(usize).init(allocator);
        const colnum = self.getColumnNum();
        var i: usize = 0;
        while (i < colnum) {
            try colWidth.append(self.getColumnWidth(i));
            i += 1;
        }
        return colWidth;
    }

    pub fn readFrom(self: *Self, reader: anytype, buf: []u8, sep: []const u8, has_title: bool) !void {
        var flag = has_title;
        while (try reader.readUntilDelimiterOrEof(buf, '\n')) |line| {
            const i = self._data.items.len;
            var it = std.mem.splitSequence(u8, line, sep);
            while (it.next()) |data| {
                const new_data = try self.allocator.alloc(u8, data.len);
                @memcpy(new_data, data);
                try self._data.append(new_data);
            }
            if (flag) {
                try self.setTitle(self._data.items[i..]);
                flag = false;
            } else {
                try self.addRow(self._data.items[i..]);
            }
        }
    }

    /// Print the table to standard output. Colors won't be displayed unless
    /// stdout is a tty terminal. This means that if stdout is redirected to a file, or piped
    /// to another program, no color will be displayed.
    /// To force colors rendering, use `print_tty()` method.
    /// Any failure to print is ignored. For better control, use `print_tty()`.
    /// Calling `printstd()` is equivalent to calling `print_tty(false)` and ignoring the result.
    pub fn printstd(self: Self) !void {
        try self.print_tty(false);
    }

    /// Print the table to standard output. Colors won't be displayed unless
    /// stdout is a tty terminal, or `force_colorize` is set to `true`.
    /// In ANSI terminals, colors are displayed using ANSI escape characters. When for example the
    /// output is redirected to a file, or piped to another program, the output is considered
    /// as not beeing tty, and ANSI escape characters won't be displayed unless `force colorize`
    /// is set to `true`.
    /// # Returns
    /// A `Result` holding the number of lines printed, or an `io::Error` if any failure happens
    pub fn print_tty(self: Self, force_colorize: bool) !void {
        // TODO: color

        // _ = force_colorize;
        const stdout = std.io.getStdOut();
        var buf = std.io.bufferedWriter(stdout.writer());
        const w = buf.writer();

        if (force_colorize) {
            _ = try self.printTerm(w);
        } else {
            _ = try self.internalPrint(w, Row.print);
        }
        try buf.flush();
    }

    pub fn print(self: Self, out: anytype) !void {
        _ = try self.internalPrint(out, Row.print);
    }

    pub fn printTerm(self: Self, out: anytype) !void {
        _ = try self.internalPrint(out, Row.printTerm);
    }

    // TODO: anytype
    fn internalPrint(self: Self, out: anytype, f: fn (Row, anytype, TableFormat, []const usize) usize) !usize {
        var height: usize = 0;
        const colWidth = try self.getAllColumnWidth(self.allocator);
        defer colWidth.deinit();

        height += try self.format.printLineSeparator(out, colWidth.items, LinePosition.top);
        if (self.titles != null) {
            height += f(self.titles.?, out, self.format, colWidth.items);
            height += try self.format.printLineSeparator(out, colWidth.items, LinePosition.title);
        }

        for (0..self.rows.items.len) |i| {
            const r = self.rows.items[i];
            height += f(r, out, self.format, colWidth.items);
            if (i + 1 < self.rows.items.len) {
                height += try self.format.printLineSeparator(out, colWidth.items, LinePosition.intern);
            }
        }

        height += try self.format.printLineSeparator(out, colWidth.items, LinePosition.bottom);

        return height;
    }
};

test "test print table" {
    const row1 = [_][]const u8{ "ABC", "DEFG", "HIJKLMN" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\+-----+------+---------+
        \\| ABC | DEFG | HIJKLMN |
        \\+-----+------+---------+
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test print mulitline table" {
    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRows(&[_][]const []const u8{
        &[_][]const u8{ "ABC", "DEFG", "HIJKLMN" },
        &[_][]const u8{ "foobar", "foo", "bar" },
        &[_][]const u8{ "1", "2", "3" },
    });

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

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
    try testing.expect(eql(u8, buf.items, expect));
}

test "test print table with title" {
    const title = [_][]const u8{ "col1", "col2", "col3" };
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);
    try table.setTitle(&title);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\+--------+------+------+
        \\| col1   | col2 | col3 |
        \\+========+======+======+
        \\| foobar | foo  | bar  |
        \\+--------+------+------+
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test print table with format" {
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);
    table.setFormat(@import("./format.zig").FORMAT_BOX_CHARS);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\┌────────┬─────┬─────┐
        \\│ foobar │ foo │ bar │
        \\└────────┴─────┴─────┘
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test print table with mulitline cell" {
    const row1 = [_][]const u8{ "foo\nbar", "foo", "bar" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\+-----+-----+-----+
        \\| foo | foo | bar |
        \\| bar |     |     |
        \\+-----+-----+-----+
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test print table with inconsistent columns" {
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };
    const row2 = [_][]const u8{ "1", "2" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\+--------+-----+-----+
        \\| foobar | foo | bar |
        \\+--------+-----+-----+
        \\| 1      | 2   |     |
        \\+--------+-----+-----+
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test nest table" {
    // Nest Table
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };
    const row2 = [_][]const u8{ "1", "2" };

    var table1 = Table.init(testing.allocator);
    defer table1.deinit();

    try table1.addRow(&row1);
    try table1.addRow(&row2);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    var out = buf.writer();
    _ = try table1.print(out);

    // Table 2
    const row3 = [_][]const u8{ "A", "B", "C" };
    const row4 = [_][]const u8{ "1", "2", buf.items };

    var table2 = Table.init(testing.allocator);
    defer table2.deinit();

    try table2.addRow(&row3);
    try table2.addRow(&row4);

    var buf2 = std.ArrayList(u8).init(testing.allocator);
    defer buf2.deinit();
    out = buf2.writer();

    _ = try table2.print(out);

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
    try testing.expect(eql(u8, buf2.items, expect));
}

test "test insert and remove row" {
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };
    const row2 = [_][]const u8{ "1", "2" };
    const row3 = [_][]const u8{ "ABC", "DEFG", "HIJKLMN" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);
    try table.insertRow(0, &row3);
    table.removeRow(1);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\+-----+------+---------+
        \\| ABC | DEFG | HIJKLMN |
        \\+-----+------+---------+
        \\| 1   | 2    |         |
        \\+-----+------+---------+
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test get and set cell" {
    const row1 = [_][]const u8{ "foobar", "foo", "bar" };
    const row2 = [_][]const u8{ "1", "2" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);

    try testing.expect(table.getCell(0, 0) != null);

    try table.setCell(0, 0, "FOOBAR");

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\+--------+-----+-----+
        \\| FOOBAR | foo | bar |
        \\+--------+-----+-----+
        \\| 1      | 2   |     |
        \\+--------+-----+-----+
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test table alignment" {
    const row1 = [_][]const u8{ "foo", "foooooo", "bar" };
    const row2 = [_][]const u8{ "1", "2", "3" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);

    table.setAlign(Alignment.right);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\+-----+---------+-----+
        \\| foo | foooooo | bar |
        \\+-----+---------+-----+
        \\|   1 |       2 |   3 |
        \\+-----+---------+-----+
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test column alignment" {
    const row1 = [_][]const u8{ "foo", "foooooo", "bar" };
    const row2 = [_][]const u8{ "1", "2", "3" };

    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&row1);
    try table.addRow(&row2);

    table.setColumnAlign(1, Alignment.right);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    const expect =
        \\+-----+---------+-----+
        \\| foo | foooooo | bar |
        \\+-----+---------+-----+
        \\| 1   |       2 | 3   |
        \\+-----+---------+-----+
        \\
    ;
    try testing.expect(eql(u8, buf.items, expect));
}

test "test read from" {
    const data =
        \\quincy, 1, hot dogs
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\mrugesh, 4, ice cream
        \\
    ;

    var s = std.io.fixedBufferStream(data);
    const reader = s.reader();

    var table = Table.init(testing.allocator);
    defer table.deinit();

    var read_buf: [1024]u8 = undefined;
    try table.readFrom(reader, &read_buf, ",", false);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);
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

    try testing.expect(eql(u8, buf.items, expect));
}

test "test read from with title" {
    const data =
        \\name, id, favorite food
        \\beau, 2, cereal
        \\abbey, 3, pizza
        \\
    ;

    var s = std.io.fixedBufferStream(data);
    const reader = s.reader();

    var table = Table.init(testing.allocator);
    defer table.deinit();

    var read_buf: [1024]u8 = undefined;
    try table.readFrom(reader, &read_buf, ",", true);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);
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

    try testing.expect(eql(u8, buf.items, expect));
}

test "test color" {
    var table = Table.init(testing.allocator);
    defer table.deinit();

    try table.addRow(&[_][]const u8{"1"});
    try table.setCellStyle(0, 0, .{ .bold = true, .fg = .red });

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.printTerm(out);
    const expect = [_]u8{ 43, 45, 45, 45, 43, 10, 124, 32, 27, 91, 51, 49, 59, 52, 57, 59, 49, 109, 49, 27, 91, 48, 109, 32, 124, 10, 43, 45, 45, 45, 43, 10 };

    try testing.expect(eql(u8, buf.items, &expect));
}

test "test table with unicode characters" {
    const allocator = testing.allocator;

    const row1 = [_][]const u8{ "姓名", "年龄", "职业" };
    const row2 = [_][]const u8{ "张三", "25", "工程师" };
    const row3 = [_][]const u8{ "李四", "30", "设计师" };

    var table = Table.init(allocator);
    defer table.deinit();

    try table.setTitle(&row1);
    try table.addRow(&row2);
    try table.addRow(&row3);

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    // Verify output contains correct Unicode characters
    try testing.expect(std.mem.indexOf(u8, buf.items, "姓名") != null);
    try testing.expect(std.mem.indexOf(u8, buf.items, "张三") != null);
    try testing.expect(std.mem.indexOf(u8, buf.items, "工程师") != null);
}

test "test table with emoji" {
    const allocator = testing.allocator;

    const row1 = [_][]const u8{ "Name", "Mood", "Status" };
    const row2 = [_][]const u8{ "Alice", "😊", "Happy" };
    const row3 = [_][]const u8{ "Bob", "😢", "Sad" };

    var table = Table.init(allocator);
    defer table.deinit();

    try table.setTitle(&row1);
    try table.addRow(&row2);
    try table.addRow(&row3);

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    // Verify output contains correct emoji
    try testing.expect(std.mem.indexOf(u8, buf.items, "😊") != null);
    try testing.expect(std.mem.indexOf(u8, buf.items, "😢") != null);
}

test "test table mixed unicode and ascii" {
    const allocator = testing.allocator;

    const row1 = [_][]const u8{ "Product", "Price", "Review" };
    const row2 = [_][]const u8{ "苹果", "$2.99", "很好 👍" };
    const row3 = [_][]const u8{ "香蕉", "$1.99", "不错 😊" };

    var table = Table.init(allocator);
    defer table.deinit();

    try table.setTitle(&row1);
    try table.addRow(&row2);
    try table.addRow(&row3);

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const out = buf.writer();

    _ = try table.print(out);

    // Verify output contains mixed characters
    try testing.expect(std.mem.indexOf(u8, buf.items, "苹果") != null);
    try testing.expect(std.mem.indexOf(u8, buf.items, "👍") != null);
    try testing.expect(std.mem.indexOf(u8, buf.items, "😊") != null);
}
