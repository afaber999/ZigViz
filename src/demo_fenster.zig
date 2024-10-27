const std = @import("std");
const c = @cImport({
    @cInclude("fenster.h");
});
const Canvas = @import("Canvas.zig");
const Triangle = @import("demo_triangle.zig");



pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const width = 800;
    const height = 600;

    // nedded for ARGB to RGBA conversion
    var fenster_buffer = try allocator.alloc(u32, width * height);

    var demo = try Triangle.init(allocator, width, height);
    defer demo.deinit();

    var f = std.mem.zeroInit(c.fenster, .{
        .width = width,
        .height = height,
        .title = "DEMO window",
        .buf = fenster_buffer.ptr,
    });

    _ = c.fenster_open(&f);
    defer c.fenster_close(&f);

    var t: u32 = 0;
    var now: i64 = c.fenster_time();

    while (c.fenster_loop(&f) == 0) {
        _ = demo.render(15.0);

        var idx: usize = 0;
        for (0..demo.canvas.height) |y| {
            for (0..demo.canvas.width) |x| {
                const pixel = demo.canvas.pixel_value(x, y);
                fenster_buffer[idx] = Canvas.from_rgba(Canvas.blue(pixel), Canvas.green(pixel), Canvas.red(pixel), 255);
                idx += 1;
            }
        }

        // Exit when Escape is pressed
        if (f.keys[27] != 0) {
            break;
        }
        // // Render x^y^t pattern
        // for (buf, 0..) |_, i| {
        //     buf[i] = @as(u32, @intCast(i % 320)) ^ @as(u32, @intCast(i / 240)) ^ t;
        // }
        t +%= 1;
        // Keep ~60 FPS
        const diff: i64 = 1000 / 60 - (c.fenster_time() - now);
        if (diff > 0) {
            c.fenster_sleep(diff);
        }
        now = c.fenster_time();
    }
}

const Self = @This();
