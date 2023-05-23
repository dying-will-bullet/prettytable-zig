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
    f_color: ?Color = null,
    b_color: ?Color = null,

    const Self = @This();

    fn fg2Ansi(comptime color: Color) u8 {
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

    fn bg2Ansi(comptime color: Color) u8 {
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

    pub fn toAnsi(comptime self: Self) ![]const u8 {
        var buffer = [_]u8{undefined} ** 32;
        const template = "\x1b[{d};{d};{d};{d};{d}m";

        comptime var f_color = 0;
        comptime var b_color = 0;
        comptime var bold = 0;
        comptime var italic = 0;
        comptime var underline = 0;

        if (self.f_color != null) {
            f_color = comptime Self.fg2Ansi(self.f_color.?);
        }
        if (self.b_color != null) {
            b_color = comptime Self.bg2Ansi(self.b_color.?);
        }

        if (self.bold) {
            bold = 1;
        }
        if (self.italic) {
            italic = 3;
        }

        if (self.underline) {
            underline = 4;
        }

        // const prefix = comptime std.fmt.comptimePrint(template, .{ f_color, b_color, bold, italic, underline });
        const prefix = try std.fmt.bufPrint(&buffer, template, .{ f_color, b_color, bold, italic, underline });
        return prefix;
    }
};

test "test to ansi" {
    const style = .{ .bold = true, .f_color = .green, .b_color = .red };
    try testing.expect(std.mem.eql(u8, try Style.toAnsi(style), "\x1b[32;41;1;0;0m"));
}
