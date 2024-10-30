const std = @import("std");
const builtin = @import("builtin");
const Canvas = @import("Canvas.zig");
const png = @import("png.zig");

//if ( comptime builtin.cpu.arch == .wasm32) {
pub extern fn logWasm(s: [*]const u8, len: usize) void;
//}

pub fn log(comptime fmt: []const u8, args: anytype) void {
    if (comptime builtin.cpu.arch == .wasm32) {
        var buf: [4096]u8 = undefined;
        const slice = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
        logWasm(slice.ptr, slice.len);
    } else {
        std.debug.print(fmt, args);
    }
}

pub fn write_png(allocator: std.mem.Allocator, canvas: Canvas, writer: anytype) !void {
    var img = try png.Image.init(allocator, @intCast(canvas.width), @intCast(canvas.height));
    defer img.deinit(allocator);

    var idx: usize = 0;
    for (0..canvas.height) |y| {
        for (0..canvas.width) |x| {
            const pixel = canvas.pixel_value(x, y);
            img.pixels[idx] = .{ @as(u16, @intCast(Canvas.red(pixel))) << 8, @as(u16, @intCast(Canvas.green(pixel))) << 8, @as(u16, @intCast(Canvas.blue(pixel))) << 8, @as(u16, @intCast(Canvas.alpha(pixel))) << 8 };
            idx += 1;
        }
    }
    const opts = png.EncodeOptions{ .bit_depth = 8 };
    try img.write(allocator, writer, opts);
}

const PixelCanvas = struct {
    pixels: []Canvas.PixelType,
    canvas: Canvas,
};

pub fn read_png(allocator: std.mem.Allocator, reader: anytype) !PixelCanvas {
    var img = try png.Image.read(allocator, reader);
    defer img.deinit(allocator);

    const pixels = try allocator.alloc(Canvas.PixelType, img.width * img.height);
    errdefer allocator.free(pixels);
    var canvas = Canvas.init(pixels, img.width, img.height, img.width);

    var idx: usize = 0;
    for (0..canvas.height) |y| {
        for (0..canvas.width) |x| {
            const pixel = img.pixels[idx];
            const r = @as(u8, @intCast(pixel[0] >> 8));
            const g = @as(u8, @intCast(pixel[1] >> 8));
            const b = @as(u8, @intCast(pixel[2] >> 8));
            const a = @as(u8, @intCast(pixel[3] >> 8));

            const pt = Canvas.from_rgba(r, g, b, a);
            canvas.set_pixel(x, y, pt);
            idx += 1;
        }
    }
    return PixelCanvas{ .pixels = pixels, .canvas = canvas };
}
