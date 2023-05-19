const std = @import("std");
const testing = std.testing;
const unicode = @import("std").unicode;

// TODO: @Hanaasagi
// unicode char, currenty is a bytes
const Char = []const u8;

/// Alignment for cell's content
pub const Alignment = enum {
    /// Align left
    left,
    /// Align in the center
    center,
    /// Align right
    right,
};

/// Position of a line separator in a table
pub const LinePosition = enum {
    /// Table's border on top
    top,
    /// Line separator between the titles row,
    /// and the first data row
    title,
    /// Line separator between data rows
    intern,
    /// bottom table's border
    bottom,
};

/// Position of a column separator in a row
pub const ColumnPosition = enum {
    /// left table's border
    left,
    /// internal column separators
    intern,
    /// Rigth table's border
    right,
};

/// Contains the character used for printing a line separator
pub const LineSeparator = struct {
    /// Line separator
    line: Char,
    /// internal junction separator
    junc: Char,
    /// left junction separator
    ljunc: Char,
    /// right junction separator
    rjunc: Char,

    const Self = @This();

    /// Create a new line separator instance where `line` is the character used to separate 2 lines
    /// and `junc` is the one used for junctions between columns and lines
    pub fn new(line: Char, junc: Char, ljunc: Char, rjunc: Char) Self {
        return Self{
            .line = line,
            .junc = junc,
            .ljunc = ljunc,
            .rjunc = rjunc,
        };
    }

    pub fn default() Self {
        return Self.new("-", "+", "+", "+");
    }

    fn print(self: Self, out: anytype, colWidth: []const usize, lpadding: usize, rpadding: usize, colsep: bool, lborder: bool, rborder: bool) !usize {
        if (lborder) {
            _ = try out.write(self.ljunc);
        }

        var i: usize = 0;

        while (i < colWidth.len) {
            const width = colWidth[i];
            for (0..(width + lpadding + rpadding)) |_| {
                _ = try out.write(self.line);
            }
            if (colsep and i + 1 < colWidth.len) {
                _ = try out.write(self.junc);
            }

            i += 1;
        }
        if (rborder) {
            _ = try out.write(self.rjunc);
        }
        _ = try out.write(std.cstr.line_sep);
        return 1;
    }
};

pub const TableFormat = struct {
    // Optional column separator character
    csep: ?Char,
    // Optional left border character
    lborder: ?Char,
    // Optional right border character
    rborder: ?Char,
    // Optional internal line separator
    lsep: ?LineSeparator,
    // Optional title line separator
    tsep: ?LineSeparator,
    // Optional top line separator
    top_sep: ?LineSeparator,
    // Optional bottom line separator
    bottom_sep: ?LineSeparator,
    // left padding
    pad_left: usize,
    // right padding
    pad_right: usize,
    // Global indentation when rendering the table
    indent: usize,

    const Self = @This();

    /// Create a new empty TableFormat.
    pub fn new() Self {
        return Self{
            .csep = null,
            .lborder = null,
            .rborder = null,
            .lsep = null,
            .tsep = null,
            .top_sep = null,
            .bottom_sep = null,
            .pad_left = 0,
            .pad_right = 0,
            .indent = 0,
        };
    }

    pub fn default() Self {
        return Self{
            .csep = null,
            .lborder = null,
            .rborder = null,
            .lsep = null,
            .tsep = null,
            .top_sep = null,
            .bottom_sep = null,
            .pad_left = 0,
            .pad_right = 0,
            .indent = 0,
        };
    }

    pub fn getLPadding(self: Self) usize {
        return self.pad_left;
    }

    pub fn getRPadding(self: Self) usize {
        return self.pad_right;
    }
    pub fn setPadding(self: *Self, left: usize, right: usize) void {
        self.pad_left = left;
        self.pad_right = right;
    }

    pub fn setColumnSeparator(self: *Self, separator: Char) void {
        self.csep = separator;
    }

    pub fn setBorders(self: *Self, border: Char) void {
        self.lborder = border;
        self.rborder = border;
    }

    pub fn setleftBorder(self: *Self, border: Char) void {
        self.lborder = border;
    }

    pub fn setrightBorder(self: Self, border: Char) void {
        self.rborder = border;
    }

    /// Set a line separator
    pub fn setSeparator(self: *Self, what: LinePosition, separator: LineSeparator) void {
        switch (what) {
            .top => {
                self.top_sep = separator;
            },
            .bottom => {
                self.bottom_sep = separator;
            },
            .title => {
                self.tsep = separator;
            },
            .intern => {
                self.lsep = separator;
            },
        }
    }

    pub fn getSepForLine(self: Self, pos: LinePosition) ?LineSeparator {
        switch (pos) {
            .top => {
                return self.top_sep;
            },
            .bottom => {
                return self.bottom_sep;
            },
            .intern => {
                return self.lsep;
            },
            .title => {
                if (self.tsep == null) {
                    return self.lsep;
                }
                return self.tsep;
            },
        }
    }

    /// Set global indentation in spaces used when rendering a table
    pub fn setIndent(self: *Self, spaces: usize) void {
        self.indent = spaces;
    }

    /// Get global indentation in spaces used when rendering a table
    pub fn getIndent(self: Self) usize {
        return self.indent;
    }

    pub fn getColumnSeparator(self: Self, pos: ColumnPosition) ?Char {
        switch (pos) {
            .left => {
                return self.lborder;
            },
            .intern => {
                return self.csep;
            },
            .right => {
                return self.rborder;
            },
        }
    }

    pub fn printLineSeparator(self: Self, out: anytype, colWidth: []const usize, pos: LinePosition) !usize {
        const sep = self.getSepForLine(pos);
        if (sep == null) {
            return 0;
        }
        for (0..self.getIndent()) |_| {
            try out.writeAll(" ");
        }
        return sep.?.print(out, colWidth, self.getLPadding(), self.getRPadding(), self.csep != null, self.lborder != null, self.rborder != null);
    }

    pub fn printColumnSeparator(self: Self, out: anytype, pos: ColumnPosition) !void {
        const s = self.getColumnSeparator(pos);
        if (s == null) {
            return;
        }

        _ = try out.writeAll(s.?);
    }
};

pub const FormatBuilder = struct {
    format: TableFormat,

    const Self = @This();
    pub fn new() Self {
        return Self{
            .format = TableFormat.new(),
        };
    }

    /// Set left and right padding
    pub fn withPadding(self: *Self, left: usize, right: usize) *Self {
        self.format.setPadding(left, right);
        return self;
    }

    /// Set the character used for internal column separation
    pub fn withColumnSeparator(self: *Self, separator: Char) *Self {
        self.format.setColumnSeparator(separator);
        return self;
    }

    /// Set the character used for table borders
    pub fn withBorders(self: *Self, border: Char) *Self {
        self.format.setBorders(border);
        return self;
    }

    /// Set the character used for left table border
    pub fn withLeftBorder(self: *Self, border: Char) *Self {
        self.format.setleftBorder(border);
        return self;
    }

    /// Set the character used for right table border
    pub fn withRightBorder(self: *Self, border: Char) *Self {
        self.format.setrightBorder(border);
        return self;
    }

    /// Set a line separator format
    pub fn withSeparator(self: *Self, what: LinePosition, separator: LineSeparator) *Self {
        self.format.setSeparator(what, separator);
        return self;
    }

    /// Set global indentation in spaces used when rendering a table
    pub fn withIndent(self: *Self, spaces: usize) *Self {
        self.format.setIndent(spaces);
        return self;
    }

    /// Return the generated `TableFormat`
    pub fn build(self: Self) TableFormat {
        return self.format;
    }
};

/// A line separator made of `-` and `+`
pub const MINUS_PLUS_SEP = LineSeparator.new("-", "+", "+", "+");
/// A line separator made of `=` and `+`
pub const EQU_PLUS_SEP: LineSeparator = LineSeparator.new("=", "+", "+", "+");

/// Default table format
///
/// # Example
/// ```text
/// +----+----+
/// | T1 | T2 |
/// +====+====+
/// | a  | b  |
/// +----+----+
/// | d  | c  |
/// +----+----+
/// ```
pub const FORMAT_DEFAULT = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withColumnSeparator("|")
        .withBorders("|")
        .withSeparator(LinePosition.title, EQU_PLUS_SEP)
        .withSeparator(LinePosition.intern, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.bottom, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.top, MINUS_PLUS_SEP)
        .withPadding(1, 1)
        .build();
};

/// Similar to `FORMAT_DEFAULT` but without special separator after title line
///
/// # Example
/// ```text
/// +----+----+
/// | T1 | T2 |
/// +----+----+
/// | a  | b  |
/// +----+----+
/// | c  | d  |
/// +----+----+
/// ```
pub const FORMAT_NO_TITLE = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withColumnSeparator("|")
        .withBorders("|")
        .withSeparator(LinePosition.intern, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.title, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.bottom, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.top, MINUS_PLUS_SEP)
        .withPadding(1, 1)
        .build();
};

/// With no line separator, but with title separator
///
/// # Example
/// ```text
/// +----+----+
/// | T1 | T2 |
/// +----+----+
/// | a  | b  |
/// | c  | d  |
/// +----+----+
/// ```
pub const FORMAT_NO_LINESEP_WITH_TITLE = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withColumnSeparator("|")
        .withBorders("|")
        .withSeparator(LinePosition.title, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.bottom, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.top, MINUS_PLUS_SEP)
        .withPadding(1, 1)
        .build();
};

/// With no line or title separator
///
/// # Example
/// ```text
/// +----+----+
/// | T1 | T2 |
/// | a  | b  |
/// | c  | d  |
/// +----+----+
/// ```
pub const FORMAT_NO_LINESEP = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withColumnSeparator("|")
        .withBorders("|")
        .withSeparator(LinePosition.bottom, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.top, MINUS_PLUS_SEP)
        .withPadding(1, 1)
        .build();
};

/// No column separator
///
/// # Example
/// ```text
/// --------
///  T1  T2
/// ========
///  a   b
/// --------
///  d   c
/// --------
/// ```
pub const FORMAT_NO_COLSEP = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withSeparator(LinePosition.intern, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.title, EQU_PLUS_SEP)
        .withSeparator(LinePosition.bottom, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.top, MINUS_PLUS_SEP)
        .withPadding(1, 1)
        .build();
};

/// Format for printing a table without any separators (only alignment)
///
/// # Example
/// ```text
///  T1  T2
///  a   b
///  d   c
/// ```
pub const FORMAT_CLEAN = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withPadding(1, 1)
        .build();
};

/// Format for a table with only external borders and title separator
///
/// # Example
/// ```text
/// +--------+
/// | T1  T2 |
/// +========+
/// | a   b  |
/// | c   d  |
/// +--------+
/// ```
pub const FORMAT_BORDERS_ONLY = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withPadding(1, 1)
        .withSeparator(LinePosition.title, EQU_PLUS_SEP)
        .withSeparator(LinePosition.bottom, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.top, MINUS_PLUS_SEP)
        .withBorders("|")
        .build();
};

/// A table with no external border
///
/// # Example
/// ```text
///  T1 | T2
/// ====+====
///  a  | b
/// ----+----
///  c  | d
/// ```
pub const FORMAT_NO_BORDER = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withSeparator(LinePosition.intern, MINUS_PLUS_SEP)
        .withSeparator(LinePosition.title, EQU_PLUS_SEP)
        .withColumnSeparator("|")
        .withPadding(1, 1)
        .build();
};

/// A table with no external border and no line separation
///
/// # Example
/// ```text
///  T1 | T2
/// ----+----
///  a  | b
///  c  | d
/// ```
pub const FORMAT_NO_BORDER_LINE_SEPARATOR = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withPadding(1, 1)
        .withSeparator(LinePosition.title, MINUS_PLUS_SEP)
        .withColumnSeparator("|")
        .build();
};
/// A table with borders and delimiters made with box characters
///
/// # Example
/// ```text
/// ┌────┬────┬────┐
/// │ t1 │ t2 │ t3 │
/// ├────┼────┼────┤
/// │ 1  │ 1  │ 1  │
/// ├────┼────┼────┤
/// │ 2  │ 2  │ 2  │
/// └────┴────┴────┘
/// ```
pub const FORMAT_BOX_CHARS = blk: {
    var builder = FormatBuilder.new();
    break :blk builder
        .withColumnSeparator("│")
        .withBorders("│")
        .withSeparator(LinePosition.top, LineSeparator.new("─", "┬", "┌", "┐"))
        .withSeparator(LinePosition.intern, LineSeparator.new("─", "┼", "├", "┤"))
        .withSeparator(LinePosition.bottom, LineSeparator.new("─", "┴", "└", "┘"))
        .withPadding(1, 1)
        .build();
};

test "test FORMAT_DEFAULT" {
    try testing.expect(FORMAT_DEFAULT.csep != null);
}

test "test FORMAT_NO_TITLE" {
    try testing.expect(FORMAT_NO_TITLE.csep != null);
}

test "test FORMAT_NO_LINESEP_WITH_TITLE" {
    try testing.expect(FORMAT_NO_LINESEP_WITH_TITLE.csep != null);
}

test "test FORMAT_NO_LINESEP" {
    try testing.expect(FORMAT_NO_LINESEP.csep != null);
}

test "test FORMAT_NO_COLSEP" {
    try testing.expect(FORMAT_NO_COLSEP.csep == null);
}

test "test FORMAT_CLEAN" {
    try testing.expect(FORMAT_CLEAN.csep == null);
}

test "test FORMAT_BORDERS_ONLY" {
    try testing.expect(FORMAT_BORDERS_ONLY.csep == null);
}

test "test FORMAT_NO_BORDER" {
    try testing.expect(FORMAT_NO_BORDER.csep != null);
}

test "test FORMAT_NO_BORDER_LINE_SEPARATOR" {
    try testing.expect(FORMAT_NO_BORDER_LINE_SEPARATOR.csep != null);
}

test "test FORMAT_BOX_CHARS" {
    try testing.expect(FORMAT_BOX_CHARS.csep != null);
}
