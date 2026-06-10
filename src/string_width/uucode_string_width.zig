const std = @import("std");
const uucode = @import("uucode");

fn eawToWidth(codepoint: u21, eaw: uucode.types.EastAsianWidth) i16 {
    if (codepoint == 0) return 0;
    if (codepoint < 32 or (codepoint >= 0x7f and codepoint < 0xa0)) return -1;

    const category = uucode.get(.general_category, codepoint);
    switch (category) {
        .mark_nonspacing, .mark_enclosing => return 0,
        else => {},
    }

    if (codepoint == 0x00ad) return 0;
    if (codepoint == 0x200b) return 0;
    if (codepoint == 0x200c) return 0;
    if (codepoint == 0x200d) return 0;
    if (codepoint == 0x2060) return 0;
    if (codepoint == 0x034f) return 0;
    if (codepoint == 0xfeff) return 0;
    if (codepoint >= 0x180b and codepoint <= 0x180d) return 0;
    if (codepoint >= 0xfe00 and codepoint <= 0xfe0f) return 0;
    if (codepoint >= 0xe0100 and codepoint <= 0xe01ef) return 0;

    return switch (eaw) {
        .fullwidth, .wide => 2,
        else => 1,
    };
}

fn graphemeWidth(grapheme: []const u8) usize {
    var iter = uucode.utf8.Iterator.init(grapheme);
    var width: i16 = 0;
    var has_emoji_vs = false;
    var has_text_vs = false;
    var has_emoji_presentation = false;
    var regional_indicator_count: u8 = 0;

    while (iter.next()) |codepoint| {
        if (codepoint == 0xfe0f) {
            has_emoji_vs = true;
            continue;
        }
        if (codepoint == 0xfe0e) {
            has_text_vs = true;
            continue;
        }

        if (uucode.get(.is_emoji_presentation, codepoint)) {
            has_emoji_presentation = true;
        }

        if (codepoint >= 0x1F1E6 and codepoint <= 0x1F1FF) {
            regional_indicator_count += 1;
        }

        const eaw = uucode.get(.east_asian_width, codepoint);
        const cp_width = eawToWidth(codepoint, eaw);
        if (cp_width > 0 and cp_width > width) {
            width = cp_width;
        }
    }

    if (has_text_vs) {
        width = @max(1, width);
    } else if (has_emoji_vs or has_emoji_presentation or regional_indicator_count == 2) {
        width = @max(2, width);
    }

    return @intCast(@max(0, width));
}

pub fn getStringWidth(text: []const u8) usize {
    var total: usize = 0;
    var grapheme_iter = uucode.grapheme.Iterator(uucode.utf8.Iterator).init(.init(text));
    var grapheme_start: usize = 0;
    var prev_break = true;

    while (grapheme_iter.nextCodePoint()) |result| {
        if (prev_break and !result.is_break) {
            const cp_len = std.unicode.utf8CodepointSequenceLength(result.code_point) catch 1;
            grapheme_start = grapheme_iter.i - cp_len;
        }

        if (result.is_break) {
            const grapheme_end = grapheme_iter.i;
            total += graphemeWidth(text[grapheme_start..grapheme_end]);
            grapheme_start = grapheme_end;
        }

        prev_break = result.is_break;
    }

    if (!prev_break and grapheme_start < text.len) {
        total += graphemeWidth(text[grapheme_start..]);
    }

    return total;
}

test "uucode width handles common text" {
    try std.testing.expectEqual(@as(usize, 5), getStringWidth("Hello"));
    try std.testing.expectEqual(@as(usize, 4), getStringWidth("你好"));
    try std.testing.expectEqual(@as(usize, 2), getStringWidth("😊"));
    try std.testing.expectEqual(@as(usize, 8), getStringWidth("Hello 😊"));
}

test "uucode width handles zwj emoji" {
    try std.testing.expectEqual(@as(usize, 2), getStringWidth("👩‍🚀"));
}
