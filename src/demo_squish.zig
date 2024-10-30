const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");

const log = common.log;

pixels: []Canvas.PixelType = undefined,
canvas: Canvas = undefined,
img_canvas: Canvas = undefined,
allocator: std.mem.Allocator = undefined,
global_time: f32 = 0.0,

const Self = @This();

const emedded_png = @embedFile("./assets/tsodinPog.png");

pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
    log("SQUISH INIT from ZIG... {d} {d}\n", .{ width, height });

    const uw: usize = @intCast(width);
    const uh: usize = @intCast(height);

    const pixels = allocator.allocWithOptions(Canvas.PixelType, uw * uh * @sizeOf(Canvas.PixelType), 4, null) catch {
        return error.OutOfMemory;
    };

    var buffer_stream = std.io.fixedBufferStream(emedded_png);
    const epix_canvas = try common.read_png(allocator, buffer_stream.reader());
    //defer allocator.free(epix_canvas.pixes);
    const img_canvas = epix_canvas.canvas;

    //log("ALLOCATED  ZIG... {any}\n", .{pixels.ptr});
    var canvas = Canvas.init(pixels, uw, uh, uw);

    canvas.copy_nb(img_canvas);

    return Self{
        .pixels = pixels,
        .canvas = canvas,
        .img_canvas = img_canvas,
        .allocator = allocator,
    };
}

pub fn pixel_ptr(self: Self) ?[*]Canvas.PixelType {
    return self.pixels.ptr;
}

pub fn deinit(self: Self) void {
    if (self.pixels.len > 0) {
        self.allocator.free(self.pixels);
    }
}

pub fn render(self: *Self, dt: f32) bool {
    self.global_time += dt;
    const scale = @as(i32, @intFromFloat(std.math.sin(self.global_time / 1000.0) * 100.0));

    const sprite_w: i32 = @as(i32, @intCast(self.img_canvas.width)) - scale;
    const sprite_h: i32 = @as(i32, @intCast(self.img_canvas.height)) + scale;

    const sprite_x: i32 = @as(i32, @intCast(self.canvas.width / 2)) - @divFloor(sprite_w, 2);
    const sprite_y: i32 = @as(i32, @intCast(self.canvas.height / 2)) - sprite_h;

    const bcolor = Canvas.from_rgba(0x10, 0x10, 0x10, 0xFF);
    self.canvas.clear(bcolor);

    var sub_canvas = self.canvas.sub_canvas(sprite_x, sprite_y, sprite_w, sprite_h) catch unreachable;
    sub_canvas.copy_nb(self.img_canvas);
    return true;
}
