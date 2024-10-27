const std = @import("std");
const Canvas = @import("Canvas.zig");
const Triangle = @import("demo_triangle.zig");
const common = @import("common.zig");

const png = @import("png.zig");

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
    try buf_writer.flush();
}

const c = @cImport({
    @cInclude("fenster.h");
});


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const width = 800;
    const height = 600;

    var triangle = try Triangle.init(allocator, width, height);
    defer triangle.deinit();

    _ = triangle.render(0.0);

    // const pixels = try allocator.alloc(u32, width * height);
    // defer allocator.free(pixels);

    // const canvas = Canvas.init(pixels, width, height, width);
    // std.log.info("Canvas initialized {d} {d}\n", .{ canvas.width, canvas.height });

    // // for (pixels) |*pixel| {
    // //     pixel.* = color_from_rgba(255, 128, 0, 255);
    // // }
    // canvas.fill_rect(0, 10, 50, 50, color_from_rgba(0x80, 0x00, 0x80, 0xFF));
    // //canvas.fill_circle(300, 200, 50, 0xFF00FFFF);

    // canvas.draw_triangle(200, 200, 220, 220, 140, 300, 0xFF00FFFF);

    // canvas.fill_rect(50, 300, 100, 50, color_from_rgba(0x80, 0x80, 0x80, 0xFF));
    try save_as_ppm(triangle.canvas, "output.ppm");
    std.debug.print("Writing PPM\n", .{});

    // const img = png.Image{
    //     .width = @intCast(triangle.canvas.width),
    //     .height = @intCast(triangle.canvas.height),
    //     .pixels = triangle.canvas.pixels,
    // };

    // var img = try png.Image.init(allocator, @intCast(triangle.canvas.width), @intCast(triangle.canvas.height));
    // defer img.deinit(allocator);

    // var idx: usize = 0;
    // for (0..triangle.canvas.height) |y| {
    //     for (0..triangle.canvas.width) |x| {
    //         const pixel = triangle.canvas.pixel_value(x, y);
    //         //img.pixels[idx] = .{ Canvas.red(pixel), Canvas.green(pixel), Canvas.blue(pixel), Canvas.alpha(pixel) }; // rgba_to_pixel
    //         img.pixels[idx] = .{ @as(u16, @intCast(Canvas.red(pixel))) << 8, @as(u16, @intCast(Canvas.green(pixel))) << 8, @as(u16, @intCast(Canvas.blue(pixel))) << 8, @as(u16, @intCast(Canvas.alpha(pixel))) << 8 };
    //         idx += 1;
    //     }
    // }

    // const file = try std.fs.cwd().createFile("output.png", .{});
    // defer file.close();
    // const writer = file.writer();
    // const opts = png.EncodeOptions{ .bit_depth = 8 };
    // //    try img.write(allocator, writer, opts);

    const epin = @embedFile("./assets/tsodinPog.png");

    const pin = "tsodinPog.png";
    const fin = try std.fs.cwd().openFile(pin, .{});
    defer fin.close();
    const reader = fin.reader();

    const pix_canvas = try common.read_png(allocator, reader);
    defer allocator.free(pix_canvas.pixels);

    try save_as_ppm(pix_canvas.canvas, "output1.ppm");

    // var img2 = try png.Image.read(allocator, reader);
    // defer img2.deinit(allocator);
    // try img2.write(allocator, writer, opts);

    const file = try std.fs.cwd().createFile("output.png", .{});
    defer file.close();
    const writer = file.writer();
    try common.write_png(allocator, triangle.canvas, writer);

    var str = std.io.fixedBufferStream(epin);
    const epix_canvas = try common.read_png(allocator, str.reader());
    defer allocator.free(epix_canvas.pixels);
    try save_as_ppm(epix_canvas.canvas, "output2.ppm");
    try fenster_main(allocator);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
