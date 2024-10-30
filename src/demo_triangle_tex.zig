const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");

const log = common.log;

const circle_rad = 90;

pixels: []Canvas.PixelType = undefined,
canvas: Canvas = undefined,
allocator: std.mem.Allocator = undefined,
angle: f32 = 0,

circle_loc: Canvas.Point = Canvas.Point.init(100, 400),
circle_delta: Canvas.Point = Canvas.Point.init(1, 1),

const Self = @This();

pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
    log("INIT from ZIG... {d} {d}\n", .{ width, height });

    const uw: usize = @intCast(width);
    const uh: usize = @intCast(height);

    const pixels = allocator.allocWithOptions(Canvas.PixelType, uw * uh * @sizeOf(Canvas.PixelType), 4, null) catch {
        return error.OutOfMemory;
    };

    //log("ALLOCATED  ZIG... {any}\n", .{pixels.ptr});
    const canvas = Canvas.init(pixels, uw, uh, uw);

    return Self{
        .pixels = pixels,
        .canvas = canvas,
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

fn rotate_point(point: Canvas.Point, rotation_point: Canvas.Point, angle: f32) Canvas.Point {
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

    const rp1 = rotate_point(p1, cp, self.angle);
    const rp2 = rotate_point(p2, cp, self.angle);
    const rp3 = rotate_point(p3, cp, self.angle);

    const bcolor = Canvas.from_rgba(0x10, 0x10, 0x10, 0xFF);
    const ccolor = Canvas.from_rgba(0xFF, 0x20, 0x20, 0xFF);
    const ocolor = Canvas.from_rgba(0x20, 0x20, 0xAA, 0x99);

    self.canvas.clear(bcolor);

    const c1 = Canvas.from_rgba(0xFF, 0x00, 0x00, 0xFF);
    const c2 = Canvas.from_rgba(0x00, 0xFF, 0x10, 0xFF);
    const c3 = Canvas.from_rgba(0x00, 0x10, 0xFF, 0xFF);

    self.canvas.draw_triangle3c(rp1.x, rp1.y, rp2.x, rp2.y, rp3.x, rp3.y, c1, c2, c3);
    //self.canvas.draw_triangle(rp1.x, rp1.y, rp2.x, rp2.y, rp3.x, rp3.y, fcolor);

    // self.canvas.fill_circle(cp.x, cp.y, 2, fcolor);
    // self.canvas.fill_circle(rp1.x, rp1.y, 10, ccolor);
    // self.canvas.fill_circle(rp2.x, rp2.y, 10, ccolor);
    // self.canvas.fill_circle(rp3.x, rp3.y, 10, ccolor);

    self.canvas.fill_circle(rp3.x, rp3.y, 10, ccolor);

    self.circle_loc = self.circle_loc.add(self.circle_delta);

    if (self.circle_loc.x < circle_rad or self.circle_loc.x > w - circle_rad) self.circle_delta.x *= -1;
    if ((self.circle_loc.y < circle_rad) or (self.circle_loc.y > h - circle_rad)) self.circle_delta.y *= -1;

    self.canvas.fill_circle(self.circle_loc.x, self.circle_loc.y, circle_rad, ocolor);

    // const px = self.canvas.pixel_value(100, 100);
    // const f = Canvas.float(px);
    // log("RENDER from ZIG... {}\n", .{f});

    return true;
}
