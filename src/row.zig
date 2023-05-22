const std = @import("std");
const Cell = @import("./cell.zig").Cell;
const TableFormat = @import("./format.zig").TableFormat;
const ColumnPosition = @import("./format.zig").ColumnPosition;
const Alignment = @import("./format.zig").Alignment;
const testing = std.testing;
const eql = std.mem.eql;

pub fn row(allocator: std.mem.Allocator, cells: []const []const u8) !Row {
    var list = std.ArrayList(Cell).init(allocator);
    for (cells) |cell| {
        try list.append(try Cell.init(allocator, cell));
    }

    return Row.init(allocator, list);
}

pub fn rowWithAlign(allocator: std.mem.Allocator, cells: []const []const u8, align_: Alignment) !Row {
    var list = std.ArrayList(Cell).init(allocator);
    for (cells) |cell| {
        try list.append(try Cell.initWithAlign(allocator, cell, align_));
    }

    return Row.init(allocator, list);
}

pub const Row = struct {
    allocator: std.mem.Allocator,
    cells: std.ArrayList(Cell),

    const Self = @This();

    /// Create a new `Row`
    pub fn init(allocator: std.mem.Allocator, cells: std.ArrayList(Cell)) Self {
        return Self{ .allocator = allocator, .cells = cells };
    }

    pub fn deinit(self: Self) void {
        for (self.cells.items) |cell| {
            cell.deinit();
        }
        self.cells.deinit();
    }

    /// Get the number of cells in this row
    pub fn len(self: Self) usize {
        return self.cells.items.len;
    }

    /// Check if the row is empty (has no cell)
    pub fn isEmpty(self: Self) bool {
        return self.cells.len == 0;
    }

    fn getHeight(self: Self) usize {
        var height: usize = 1;
        for (self.cells.items) |cell| {
            const h = cell.getHeight();
            if (h > height) {
                height = h;
            }
        }
        return height;
    }

    /// Get the cell at index `idx`
    pub fn getCell(self: Self, idx: usize) ?Cell {
        if (idx >= self.len()) {
            return null;
        }
        return self.cells.items[idx];
    }

    /// Set the `cell` in the row at the given `idx` index
    pub fn setCell(self: *Self, idx: usize, cell: Cell) !void {
        if (idx >= self.len()) {
            return error{IndexOutOfBounds}.IndexOutOfBounds;
        }

        self.cells.items[idx].deinit();
        self.cells.items[idx] = cell;
    }

    /// Append a `cell` at the end of the row
    pub fn addCell(self: *Self, cell: Cell) !void {
        try self.cells.append(cell);
    }

    /// Append a `cell` at the end of the row
    pub fn extendCells(self: *Self, cell: Cell) !void {
        try self.cells.append(cell);
    }

    /// Insert `cell` at position `index`. If `index` is higher than the row length,
    /// the cell will be appended at the end
    pub fn insertCell(self: *Self, index: usize, cell: Cell) !void {
        if (index < self.len()) {
            try self.cells.insert(index, cell);
        } else {
            try self.addCell(cell);
        }
    }

    /// Remove the cell at position `index`. Silently skip if this cell does not exist
    pub fn removeCell(self: *Self, index: usize) void {
        if (index < self.len()) {
            const c = self.cells.orderedRemove(index);
            c.deinit();
        }
    }

    /// Count the number of column required in the table grid.
    /// It takes into account horizontal spanning of cells. For
    /// example, a cell with an hspan of 3 will add 3 column to the grid
    pub fn columnCount(self: Self) usize {
        var count: usize = 0;
        for (self.cells.items) |cell| {
            count += cell.getHspan();
        }

        return count;
    }

    pub fn getColumnWidth(self: Self, column: usize, format: TableFormat) usize {
        var i: usize = 0;
        for (self.cells.items) |cell| {
            if (i + cell.getHspan() > column) {
                if (cell.getHspan() == 1) {
                    return cell.getWidth();
                }
                const lp = format.getLPadding();
                const rp = format.getRPadding();
                var sep: usize = 0;

                if (format.getColumnSeparator(ColumnPosition.intern) != null) {
                    sep = 1;
                }

                const rem = lp + rp + sep;
                var w = cell.getWidth();
                if (w > rem) {
                    w -= rem;
                } else {
                    w = 0;
                }

                return @floatToInt(usize, std.math.ceil(@intToFloat(f64, w) / @intToFloat(f64, cell.getHspan())));
            }

            i += cell.getHspan();
        }
        return 0;
    }

    pub fn print(self: Self, out: anytype, format: TableFormat, colWidth: []const usize) usize {
        return self.internalPrint(out, format, colWidth, Cell.print) catch return 0;
    }

    fn internalPrint(self: Self, out: anytype, format: TableFormat, colWidth: []const usize, f: fn (Cell, out: anytype, usize, usize, bool) void) !usize {
        var height = self.getHeight();
        for (0..height) |i| {
            for (0..format.getIndent()) |_| {
                _ = try out.write(" ");
            }

            try format.printColumnSeparator(out, ColumnPosition.left);

            const lp = format.getLPadding();
            const rp = format.getRPadding();

            var j: usize = 0;
            var hspan: usize = 0; // The additional offset caused by cell's horizontal spanning
            //
            while (j + hspan < colWidth.len) {
                var k: usize = 0;
                while (k < lp) {
                    _ = try out.write(" "); // Left padding
                    k += 1;
                }
                // skip_r_fill skip filling the end of the last cell if there's no character
                // delimiting the end of the table
                const skip_r_fill = (j == colWidth.len - 1) and format.getColumnSeparator(ColumnPosition.right) == null;
                const cell = self.getCell(j);
                if (cell == null) {
                    const empty = try Cell.default(self.allocator);
                    defer empty.deinit();
                    _ = f(empty, out, i, colWidth[j + hspan], skip_r_fill);
                } else {

                    // In case of horizontal spanning, width is the sum of all spanned columns' width
                    var w: usize = 0;
                    var start = j + hspan;
                    var end = j + hspan + cell.?.getHspan();
                    while (start < end) {
                        w += colWidth[start];

                        start += 1;
                    }
                    const real_span = cell.?.getHspan() - 1;
                    w += real_span * (lp + rp);
                    if (format
                        .getColumnSeparator(ColumnPosition.intern) != null)
                    {
                        w += real_span * 1;
                    }

                    // Print cell content
                    _ = f(cell.?, out, i, w, skip_r_fill);
                    hspan += real_span; // Add span to offset
                }
                var n: usize = 0;
                while (n < rp) {
                    n += 1;
                }
                _ = try out.write(" "); // Right padding
                if (j + hspan < colWidth.len - 1) {
                    try format.printColumnSeparator(out, ColumnPosition.intern);
                }
                j += 1;
            }
            try format.printColumnSeparator(out, ColumnPosition.right);
            _ = try out.writeAll(std.cstr.line_sep);
        }
        return height;
    }
};

test "test get cell" {
    const data = [_][]const u8{ "foo", "bar", "foobar" };
    var r = try row(testing.allocator, &data);
    defer r.deinit();

    try testing.expect(r.len() == 3);

    try testing.expect(r.getCell(0) != null);
    try testing.expect(r.getCell(1) != null);
    try testing.expect(r.getCell(2) != null);
    try testing.expect(r.getCell(3) == null);

    const content = try r.getCell(0).?.getContent(testing.allocator);
    defer testing.allocator.free(content);

    try testing.expect(eql(u8, content, "foo"));
}

test "test set cell" {
    const data = [_][]const u8{ "foo", "bar", "foobar" };
    var r = try row(testing.allocator, &data);
    defer r.deinit();

    try testing.expect(r.len() == 3);

    const new_cell = try Cell.init(testing.allocator, "hello");

    try r.setCell(0, new_cell);

    const content = try r.getCell(0).?.getContent(testing.allocator);
    defer testing.allocator.free(content);

    try testing.expect(eql(u8, content, "hello"));
}

test "test add cell" {
    const data = [_][]const u8{ "foo", "bar", "foobar" };
    var r = try row(testing.allocator, &data);
    defer r.deinit();

    try testing.expect(r.len() == 3);

    const new_cell = try Cell.init(testing.allocator, "hello");

    try r.addCell(new_cell);
    try testing.expect(r.len() == 4);

    const content = try r.getCell(3).?.getContent(testing.allocator);
    defer testing.allocator.free(content);

    try testing.expect(eql(u8, content, "hello"));
}

test "test insert cell" {
    const data = [_][]const u8{ "foo", "bar", "foobar" };
    var r = try row(testing.allocator, &data);
    defer r.deinit();

    try testing.expect(r.len() == 3);

    const new_cell = try Cell.init(testing.allocator, "hello");

    try r.insertCell(0, new_cell);
    try testing.expect(r.len() == 4);

    const content = try r.getCell(0).?.getContent(testing.allocator);
    defer testing.allocator.free(content);

    try testing.expect(eql(u8, content, "hello"));
}

test "test remove cell" {
    const data = [_][]const u8{ "foo", "bar", "foobar" };
    var r = try row(testing.allocator, &data);
    defer r.deinit();

    try testing.expect(r.len() == 3);

    r.removeCell(0);

    try testing.expect(r.len() == 2);
}

test "test print" {
    const t = @import("./format.zig");
    const data = [_][]const u8{ "foo", "bar", "foobar" };
    var r = try row(testing.allocator, &data);
    defer r.deinit();

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();

    var out = buf.writer();
    _ = r.print(out, t.FORMAT_DEFAULT, &[_]usize{ 10, 10, 10 });

    try testing.expect(eql(u8, buf.items, "| foo        | bar        | foobar     |" ++ std.cstr.line_sep));
}

// test "test extend cell" {
//     const data = [_][]const u8{ "foo", "bar", "foobar" };
//     var r = try row(testing.allocator, &data);
//     defer r.deinit();

//     try testing.expect(r.len() == 3);

//     r.removeCell(0);

//     try testing.expect(r.len() == 2);

// }
