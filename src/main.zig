const std = @import("std");
const Canvas = @import("Canvas.zig");

// pub inline fn color_red(p: u32) u8 {
//     return @truncate(p >> 8 * 3);
// }

// pub inline fn color_green(p: u32) u8 {
//     return @truncate(p >> 8 * 2);
// }

// pub inline fn color_blue(p: u32) u8 {
//     return @truncate(p >> 8 * 1);
// }

// pub inline fn color_alpha(p: u32) u8 {
//     return @truncate(p >> 8 * 0);
// }

// pub inline fn color_as_bytes(p: u32) [4]u8 {
//     return std.mem.asBytes(p);
// }
pub inline fn color_from_rgba(r: u8, g: u8, b: u8, a: u8) u32 {
    return (@as(u32, r) << 8 * 3) | (@as(u32, g) << 8 * 2) | (@as(u32, b) << 8 * 1) | (@as(u32, a) << 8 * 0);
}

pub fn save_as_ppm(canvas: Canvas, path: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    //var bwriter = std.io.BufferedWriter(4096, @TypeOf(file.writer())){ .unbuffered_writer = file.writer() };
    var buf_writer = std.io.bufferedWriter(file.writer());

    var writer = buf_writer.writer();

    //try std.fmt.format(writer, "P6\n{d} {d}\n255\n", .{ width, height });
    try writer.print("P6\n{d} {d}\n255\n", .{ canvas.width, canvas.height });

    for (0..canvas.height) |y| {
        for (0..canvas.width) |x| {
            const pixel = canvas.pixel_value(x, y);
            const rgb = [3]u8{ Canvas.red(pixel), Canvas.green(pixel), Canvas.blue(pixel) };
            _ = try writer.write(&rgb);
        }
    }

    // for (pixels) |pixel| {
    //     const rgb = [3]u8{ color_red(pixel), color_green(pixel), color_blue(pixel) };
    //     _ = try writer.write(&rgb);
    //     //writer.write(color_as_bytes(pixel));
    // }
    try buf_writer.flush();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const width = 800;
    const height = 640;

    const pixels = try allocator.alloc(u32, width * height);
    defer allocator.free(pixels);

    const canvas = Canvas.init(pixels, width, height, width);
    std.log.info("Canvas initialized {d} {d}\n", .{ canvas.width, canvas.height });

    // for (pixels) |*pixel| {
    //     pixel.* = color_from_rgba(255, 128, 0, 255);
    // }
    canvas.fill_rect(0, 10, 50, 50, color_from_rgba(0x80, 0x00, 0x80, 0xFF));
    //canvas.fill_circle(300, 200, 50, 0xFF00FFFF);

    canvas.draw_triangle(200, 200, 220, 220, 140, 300, 0xFF00FFFF);

    // canvas.fill_rect(50, 300, 100, 50, color_from_rgba(0x80, 0x80, 0x80, 0xFF));
    try save_as_ppm(canvas, "output.ppm");
    std.debug.print("Writing PPM\n", .{});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
