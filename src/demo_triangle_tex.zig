const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");

const log = common.log;

pixels: []Canvas.PixelType = undefined,
canvas: Canvas = undefined,
allocator: std.mem.Allocator = undefined,
angle: f32 = 0,
img_canvas: Canvas = undefined,

const Self = @This();

const emedded_png = @embedFile("./assets/tsodinPog.png");

pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
    log("INIT from ZIG... {d} {d}\n", .{ width, height });

    const uw: usize = @intCast(width);
    const uh: usize = @intCast(height);

    const pixels = allocator.alloc(Canvas.PixelType, uw * uh) catch {
        return error.OutOfMemory;
    };

    //log("ALLOCATED  ZIG... {any}\n", .{pixels.ptr});
    const canvas = Canvas.init(pixels, uw, uh, uw);

    var buffer_stream = std.io.fixedBufferStream(emedded_png);
    const epix_canvas = try common.read_png(allocator, buffer_stream.reader());
    // AF TODO FIX defer allocator.free(epix_canvas.pixes);
    const img_canvas = epix_canvas.canvas;

    return Self{
        .pixels = pixels,
        .canvas = canvas,
        .allocator = allocator,
        .img_canvas = img_canvas,
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

fn rotatePoint(point: Canvas.Point, rotation_point: Canvas.Point, angle: f32) Canvas.Point {
    var dp = point.sub(rotation_point);

    const mag = dp.mag();
    const dir = dp.angle() + angle;

    const rp = Canvas.Point.init(
        @intFromFloat(mag * std.math.cos(dir)),
        @intFromFloat(mag * std.math.sin(dir)),
    );

    return rp.add(rotation_point);
}

pub fn render(self: *Self, dt: f32) bool {
    self.angle += dt * 0.001 * 0.05 * std.math.pi;

    const w: i32 = @intCast(self.canvas.width);
    const h: i32 = @intCast(self.canvas.height);

    const cp = Canvas.Point.init(@divFloor(w * 1, 2), @divFloor(h * 1, 2));

    const p1 = Canvas.Point.init(@divFloor(w * 1, 2), @divFloor(h * 1, 16));
    const p2 = Canvas.Point.init(@divFloor(w * 1, 8), @divFloor(h * 1, 4));
    const p3 = Canvas.Point.init(@divFloor(w * 7, 8), @divFloor(h * 7, 16));

    const rp1 = rotatePoint(p1, cp, self.angle);
    const rp2 = rotatePoint(p2, cp, self.angle);
    const rp3 = rotatePoint(p3, cp, self.angle);

    const bcolor = Canvas.from_rgba(0x10, 0x10, 0x10, 0xFF);
    const ccolor = Canvas.from_rgba(0xFF, 0x20, 0x20, 0xFF);

    self.canvas.clear(bcolor);

    const uv1 = Canvas.UvPoint.init(0, 0);
    const uv2 = Canvas.UvPoint.init(0, 1);
    const uv3 = Canvas.UvPoint.init(1, 0);

    self.canvas.fillTriangleTex(rp1.x, rp1.y, rp2.x, rp2.y, rp3.x, rp3.y, self.img_canvas, uv1, uv2, uv3);
    self.canvas.fill_circle(rp3.x, rp3.y, 10, ccolor);

    return true;
}
