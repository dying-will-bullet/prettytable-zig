const std = @import("std");
const prettytable = @import("prettytable");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Example 1: Chinese character table
    {
        var table = prettytable.Table.init(allocator);
        defer table.deinit();

        // Set title
        try table.setTitle(&[_][]const u8{ "姓名", "年龄", "职业", "城市" });

        // Add data rows
        try table.addRow(&[_][]const u8{ "张三", "25", "软件工程师", "北京" });
        try table.addRow(&[_][]const u8{ "李四", "30", "产品经理", "上海" });
        try table.addRow(&[_][]const u8{ "王五", "28", "UI设计师", "深圳" });

        std.debug.print("=== 中文字符表格 ===\n", .{});
        try table.printstd();
        std.debug.print("\n", .{});
    }

    // Example 2: emoji table
    {
        var table = prettytable.Table.init(allocator);
        defer table.deinit();

        try table.setTitle(&[_][]const u8{ "Name", "Mood", "Status", "Rating" });

        try table.addRow(&[_][]const u8{ "Alice", "😊", "Happy", "⭐⭐⭐⭐⭐" });
        try table.addRow(&[_][]const u8{ "Bob", "😢", "Sad", "⭐⭐⭐" });
        try table.addRow(&[_][]const u8{ "Charlie", "😍", "Excited", "⭐⭐⭐⭐" });
        try table.addRow(&[_][]const u8{ "Diana", "🤔", "Thinking", "⭐⭐⭐⭐⭐" });

        std.debug.print("=== Emoji 表格 ===\n", .{});
        try table.printstd();
        std.debug.print("\n", .{});
    }

    // Example 3: mixed character table
    {
        var table = prettytable.Table.init(allocator);
        defer table.deinit();

        try table.setTitle(&[_][]const u8{ "Product", "Price", "Review", "Country" });

        try table.addRow(&[_][]const u8{ "苹果 🍎", "$2.99", "很好 👍", "美国" });
        try table.addRow(&[_][]const u8{ "香蕉 🍌", "$1.99", "不错 😊", "菲律宾" });
        try table.addRow(&[_][]const u8{ "橙子 🍊", "$3.49", "棒极了 🔥", "巴西" });
        try table.addRow(&[_][]const u8{ "草莓 🍓", "$4.99", "超级好 💯", "日本" });

        std.debug.print("=== 混合字符表格 ===\n", .{});
        try table.printstd();
        std.debug.print("\n", .{});
    }

    // Example 4: Korean character table
    {
        var table = prettytable.Table.init(allocator);
        defer table.deinit();

        try table.setTitle(&[_][]const u8{ "이름", "나이", "직업", "도시" });

        try table.addRow(&[_][]const u8{ "김철수", "25", "개발자", "서울" });
        try table.addRow(&[_][]const u8{ "이영희", "30", "디자이너", "부산" });
        try table.addRow(&[_][]const u8{ "박민수", "28", "기획자", "대구" });

        std.debug.print("=== 韩文字符表格 ===\n", .{});
        try table.printstd();
        std.debug.print("\n", .{});
    }

    // Example 5: right-aligned Unicode table
    {
        var table = prettytable.Table.init(allocator);
        defer table.deinit();

        try table.setTitle(&[_][]const u8{ "项目", "进度", "状态" });
        try table.addRow(&[_][]const u8{ "前端开发", "80%", "进行中 🚀" });
        try table.addRow(&[_][]const u8{ "后端开发", "60%", "开发中 💻" });
        try table.addRow(&[_][]const u8{ "测试", "20%", "准备中 📋" });

        // Set right alignment
        table.setAlign(prettytable.Alignment.right);

        std.debug.print("=== 右对齐 Unicode 表格 ===\n", .{});
        try table.printstd();
        std.debug.print("\n", .{});
    }

    // Example 6: different format Unicode table
    {
        var table = prettytable.Table.init(allocator);
        defer table.deinit();

        try table.setTitle(&[_][]const u8{ "语言", "问候", "表情" });
        try table.addRow(&[_][]const u8{ "中文", "你好", "😊" });
        try table.addRow(&[_][]const u8{ "日语", "こんにちは", "🙂" });
        try table.addRow(&[_][]const u8{ "韩语", "안녕하세요", "😄" });
        try table.addRow(&[_][]const u8{ "法语", "Bonjour", "🇫🇷" });

        // Use box character format
        table.setFormat(prettytable.FORMAT_BOX_CHARS);

        std.debug.print("=== Box 字符格式 Unicode 表格 ===\n", .{});
        try table.printstd();
        std.debug.print("\n", .{});
    }
}
