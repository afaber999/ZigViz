const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");

const log = common.log;

pixels: []Canvas.PixelType = undefined,
canvas: Canvas = undefined,
allocator: std.mem.Allocator = undefined,

angle: f32 = 0,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
    log("INIT DOT3d from ZIG... {d} {d}\n", .{ width, height });

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

    const hw: f32 = @as(f32, @floatFromInt(self.canvas.width)) / 2.0;
    const hh: f32 = @as(f32, @floatFromInt(self.canvas.height)) / 2.0;

    const grid_count = 10;
    const grid_pad: f32 = 0.5 / @as(f32, @floatFromInt(grid_count));
    const grid_size = (@as(f32, @floatFromInt(grid_count)) - 1.0) * grid_pad;
    const z_start = 0.25;

    const bcolor = Canvas.from_rgba(0x10, 0x10, 0x10, 0xFF);
    self.canvas.clear(bcolor);

    for (0..grid_count) |iy| {
        for (0..grid_count) |ix| {
            for (0..grid_count) |iz| {
                var x: f32 = @as(f32, @floatFromInt(ix)) * grid_pad - grid_size / 2.0;
                var y: f32 = @as(f32, @floatFromInt(iy)) * grid_pad - grid_size / 2.0;
                var z: f32 = z_start + @as(f32, @floatFromInt(iz)) * grid_pad;

                const cx: f32 = 0.0;
                const cz: f32 = z_start + grid_size / 2.0;

                // rotate around y axis
                var dx = x - cx;
                var dz = z - cz;

                const a = std.math.atan2(dz, dx);
                const m = std.math.sqrt(dx * dx + dz * dz);

                dx = std.math.cos(a + self.angle) * m;
                dz = std.math.sin(a + self.angle) * m;

                x = cx + dx;
                z = cz + dz;

                // perspective divide
                x = x / z;
                y = y / z;

                // from normalized coordinates to screen coordinates
                const sx = @as(i32, @intFromFloat((x + 1.0) * hw));
                const sy = @as(i32, @intFromFloat((y + 1.0) * hh));

                const radius = @as(i32, @intFromFloat(1.0 / z));

                const r = @as(u8, @intCast(@divFloor(ix * 255, grid_count)));
                const g = @as(u8, @intCast(@divFloor(iy * 255, grid_count)));
                const b = @as(u8, @intCast(@divFloor(iz * 255, grid_count)));
                const fcolor = Canvas.from_rgba(r, g, b, 0xFF);

                self.canvas.fill_circle(sx, sy, radius, fcolor);
            }
        }
    }
    return true;
}
