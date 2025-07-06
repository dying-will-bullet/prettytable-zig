const std = @import("std");
const testing = std.testing;

pub const Color = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,

    BLACK,
    RED,
    GREEN,
    YELLOW,
    BLUE,
    MAGENTA,
    CYAN,
    WHITE,

    const Self = @This();
};

pub const Style = struct {
    bold: bool = false,
    italic: bool = false,
    underline: bool = false,
    fg: ?Color = null,
    bg: ?Color = null,

    const Self = @This();

    fn fg2Ansi(color: Color) u8 {
        switch (color) {
            .black => {
                return 30;
            },
            .red => {
                return 31;
            },
            .green => {
                return 32;
            },
            .yellow => {
                return 33;
            },
            .blue => {
                return 34;
            },
            .magenta => {
                return 35;
            },
            .cyan => {
                return 36;
            },
            .white => {
                return 37;
            },
            .BLACK => {
                return 90;
            },
            .RED => {
                return 91;
            },
            .GREEN => {
                return 92;
            },
            .YELLOW => {
                return 93;
            },
            .BLUE => {
                return 94;
            },
            .MAGENTA => {
                return 95;
            },
            .CYAN => {
                return 96;
            },
            .WHITE => {
                return 97;
            },
        }
    }

    fn bg2Ansi(color: Color) u8 {
        switch (color) {
            .black => {
                return 40;
            },
            .red => {
                return 41;
            },
            .green => {
                return 42;
            },
            .yellow => {
                return 43;
            },
            .blue => {
                return 44;
            },
            .magenta => {
                return 45;
            },
            .cyan => {
                return 46;
            },
            .white => {
                return 47;
            },
            .BLACK => {
                return 100;
            },
            .RED => {
                return 101;
            },
            .GREEN => {
                return 102;
            },
            .YELLOW => {
                return 103;
            },
            .BLUE => {
                return 104;
            },
            .MAGENTA => {
                return 105;
            },
            .CYAN => {
                return 106;
            },
            .WHITE => {
                return 107;
            },
        }
    }

    pub fn toAnsi(self: Self, buf: []u8) !usize {
        const template = "\x1b[{d};{d}{s}{s}{s}m";

        var fg: u8 = 39;
        var bg: u8 = 49;
        var bold: []const u8 = "";
        var italic: []const u8 = "";
        var underline: []const u8 = "";

        if (self.fg != null) {
            fg = Self.fg2Ansi(self.fg.?);
        }
        if (self.bg != null) {
            bg = Self.bg2Ansi(self.bg.?);
        }

        if (self.bold) {
            bold = ";1";
        }
        if (self.italic) {
            italic = ";3";
        }

        if (self.underline) {
            underline = ";4";
        }

        // const prefix = comptime std.fmt.comptimePrint(template, .{ fg, bg, bold, italic, underline });
        const prefix = try std.fmt.bufPrint(buf, template, .{ fg, bg, bold, italic, underline });
        return prefix.len;
    }
};

test "test to ansi" {
    const style = Style{ .bold = true, .fg = .green, .bg = .red };

    var buf = try testing.allocator.alloc(u8, 32);
    defer testing.allocator.free(buf);
    const len = try Style.toAnsi(style, buf);
    try testing.expect(std.mem.eql(u8, buf[0..len], "\x1b[32;41;1m"));
}

test "test default" {
    const style = Style{};
    var buf = try testing.allocator.alloc(u8, 32);
    defer testing.allocator.free(buf);
    const len = try Style.toAnsi(style, buf);
    try testing.expect(std.mem.eql(u8, buf[0..len], "\x1b[39;49m"));
}
