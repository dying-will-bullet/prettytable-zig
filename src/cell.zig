const std = @import("std");
const Alignment = @import("./format.zig").Alignment;
const testing = std.testing;
const eql = std.mem.eql;

// TODO: @Hanaasagi, Unicode String
const String = []const u8;

/// Represent a table cell containing a string.
///
/// Once created, a cell's content cannot be modified.
/// The cell would have to be replaced by another one
pub const Cell = struct {
    content: std.ArrayList(String),
    // content: []const String,
    width: usize,
    align_: Alignment,
    // style: ArrayList(),
    hspan: usize,

    const Self = @This();

    pub fn default(allocator: std.mem.Allocator) !Self {
        return Self.init(allocator, "");
    }

    /// Create a new `Cell` initialized with content from `string`.
    /// Text alignment in cell is configurable with the `align` argument
    pub fn initWithAlign(allocator: std.mem.Allocator, string: String, align_: Alignment) !Self {
        var it = std.mem.split(u8, string, std.cstr.line_sep);
        var content = std.ArrayList(String).init(allocator);
        var width: usize = 0;
        while (it.next()) |item| {
            const l = item.len;
            if (l > width) {
                width = l;
            }
            try content.append(item);
        }

        return Self{
            .content = content,
            .width = width,
            .align_ = align_,
            .hspan = 1,
        };
    }

    pub fn init(allocator: std.mem.Allocator, string: String) !Self {
        return try Self.initWithAlign(allocator, string, Alignment.left);
    }

    pub fn deinit(self: Self) void {
        self.content.deinit();
    }

    /// Set text alignment in the cell
    pub fn setAlign(self: *Self, align_: Alignment) void {
        self.align_ = align_;
    }

    /// Add horizontal spanning to the cell
    pub fn withHspan(self: *Self, hspan: usize) *Self {
        self.setHspan(hspan);
        return self;
    }

    /// Return the height of the cell
    pub fn getHeight(self: Self) usize {
        return self.content.items.len;
    }

    /// Return the width of the cell
    pub fn getWidth(self: Self) usize {
        return self.width;
    }

    /// Set horizontal span for this cell (must be > 0)
    pub fn setHspan(self: *Self, hspan: usize) void {
        if (hspan == 0) {
            self.hspan = 1;
        } else {
            self.hspan = hspan;
        }
    }

    /// Get horizontal span of this cell (> 0)
    pub fn getHspan(self: Self) usize {
        return self.hspan;
    }

    /// Return a copy of the full string contained in the cell, caller owns the memory
    pub fn getContent(self: Self, allocator: std.mem.Allocator) ![]const u8 {
        return try std.mem.join(allocator, std.cstr.line_sep, self.content.items);
    }

    /// Return a copy of the full string contained in the cell
    // pub fn getContent(self: Self) String {
    //     return self.content.join("\n");
    // }

    pub fn print(self: Self, out: anytype, idx: usize, colWidth: usize, skipRightFill: bool) void {
        var c: []const u8 = "";
        if (self.content.items.len > idx) {
            c = self.content.items[idx];
        }
        return self.printAlign(out, self.align_, c, " ", colWidth, skipRightFill) catch return;
    }

    /// Align/fill a string and print it to `out`
    /// If `skip_right_fill` is set to `true`, then no space will be added after the string
    /// to complete alignment
    pub fn printAlign(
        self: Self,
        out: anytype,
        align_: Alignment,
        text: []const u8,
        fill: []const u8,
        size: usize,
        skipRightFill: bool,
    ) !void {
        _ = self;
        const textLen = text.len;
        var nfill: usize = 0;
        if (textLen < size) {
            nfill = size - textLen;
        }
        var n: usize = 0;
        switch (align_) {
            .left => {
                n = 0;
            },
            .right => {
                n = nfill;
            },
            .center => {
                n = nfill / 2;
            },
        }
        if (n > 0) {
            for (0..n) |_| {
                _ = try out.write(fill);
            }
            nfill -= n;
        }
        _ = try out.writeAll(text);
        if (nfill > 0 and !skipRightFill) {
            for (0..nfill) |_| {
                _ = try out.write(fill);
            }
        }
        return;
    }
};

test "test get_content" {
    const cell = try Cell.init(testing.allocator, "test\nnewline");
    defer cell.deinit();

    const content = try cell.getContent(testing.allocator);
    defer testing.allocator.free(content);

    try testing.expect(eql(u8, content, "test\nnewline"));
}

test "test print ascii" {
    const cell = try Cell.init(testing.allocator, "hello");
    defer cell.deinit();

    try testing.expect(cell.getWidth() == 5);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();

    var out = buf.writer();
    _ = cell.print(out, 0, 10, false);

    try testing.expect(eql(u8, buf.items, "hello     "));
}

test "test align left" {
    const cell = try Cell.initWithAlign(testing.allocator, "test", Alignment.left);
    defer cell.deinit();

    try testing.expect(cell.getWidth() == 4);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    var out = buf.writer();
    _ = cell.print(out, 0, 10, false);

    try testing.expect(eql(u8, buf.items, "test      "));
}

test "test align center" {
    const cell = try Cell.initWithAlign(testing.allocator, "test", Alignment.center);
    defer cell.deinit();

    try testing.expect(cell.getWidth() == 4);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    var out = buf.writer();
    _ = cell.print(out, 0, 10, false);

    try testing.expect(eql(u8, buf.items, "   test   "));
}

test "test align right" {
    const cell = try Cell.initWithAlign(testing.allocator, "test", Alignment.right);
    defer cell.deinit();

    try testing.expect(cell.getWidth() == 4);

    var buf = std.ArrayList(u8).init(testing.allocator);
    defer buf.deinit();
    var out = buf.writer();
    _ = cell.print(out, 0, 10, false);

    try testing.expect(eql(u8, buf.items, "      test"));
}
