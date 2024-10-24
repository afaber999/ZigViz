const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");

const log = common.log;

pixels: []u32 = undefined,
canvas: Canvas = undefined,
allocator: std.mem.Allocator = undefined,
angle: f32 = 0,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
    log("INIT from ZIG... {d} {d}\n", .{ width, height });

    const uw: usize = @intCast(width);
    const uh: usize = @intCast(height);

    const pixels = allocator.allocWithOptions(u32, uw * uh * @sizeOf(u32), 4, null) catch {
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

pub fn pixel_ptr(self: Self) ?[*]u32 {
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
    //    self.angle = std.math.pi * 0.13;
    const w: i32 = @intCast(self.canvas.width);
    const h: i32 = @intCast(self.canvas.height);

    const cp = Canvas.Point.init(@divFloor(w * 1, 2), @divFloor(h * 1, 2));

    const p1 = Canvas.Point.init(@divFloor(w * 1, 2), @divFloor(h * 1, 16));
    //const p1 = Canvas.Point.init(400 - 50, 320 - 50);
    const p2 = Canvas.Point.init(@divFloor(w * 1, 8), @divFloor(h * 1, 4));
    const p3 = Canvas.Point.init(@divFloor(w * 7, 8), @divFloor(h * 7, 16));

    //self.angle = std.math.pi / 1.0;
    const rp1 = rotate_point(p1, cp, self.angle);
    const rp2 = rotate_point(p2, cp, self.angle);
    const rp3 = rotate_point(p3, cp, self.angle);

    const bcolor = Canvas.from_rgba(0x10, 0x10, 0x10, 0xFF);
    const fcolor = Canvas.from_rgba(0xFF, 0x80, 0x10, 0xFF);
    const ccolor = Canvas.from_rgba(0xFF, 0x20, 0x20, 0xFF);

    self.canvas.fill_rect(0, 0, w, h, bcolor);
    self.canvas.draw_triangle(rp1.x, rp1.y, rp2.x, rp2.y, rp3.x, rp3.y, fcolor);

    self.canvas.fill_circle(cp.x, cp.y, 2, fcolor);
    self.canvas.fill_circle(rp1.x, rp1.y, 10, ccolor);
    self.canvas.fill_circle(rp2.x, rp2.y, 10, ccolor);
    self.canvas.fill_circle(rp3.x, rp3.y, 10, ccolor);
    return true;
}
