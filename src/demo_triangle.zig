const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");

const log = common.log;

pixels: []u32 = undefined,
canvas: Canvas = undefined,
allocator: std.mem.Allocator = undefined,
x_ofs: u32 = 0,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
    log("INIT from ZIG... {d} {d}\n", .{ width, height });

    const uw: usize = @intCast(width);
    const uh: usize = @intCast(height);

    // std.heap.GeneralPurposeAllocator.allocWithOptions(u32, uw * uh * @sizeOf(u32), 4, null) catch {
    //     return null;
    // };
    const pixels = allocator.allocWithOptions(u32, uw * uh * @sizeOf(u32), 4, null) catch {
        return error.OutOfMemory;
    };

    log("ALLOCATED  ZIG... {any}\n", .{pixels.ptr});
    const canvas = Canvas.init(pixels, uw, uh, uw);
    //log("CANVAS  ZIG... {any}\n", .{canvas});

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
        std.heap.wasm_allocator.free(self.pixels);
    }
}

pub fn render(self: *Self, dt: f32) bool {
    self.x_ofs += 1;

    const angle: i32 = @intFromFloat(std.math.cos(dt) * 50);

    //    const x_off: u32 = @intFromFloat(dt / 100.0);

    const bcolor = Canvas.from_rgba(@intCast(self.x_ofs % 255), 10, 10, 255);
    const fcolor = Canvas.from_rgba(255, 0, 255, 255);
    self.canvas.fill_rect(0, 0, @intCast(self.canvas.width), @intCast(self.canvas.height), bcolor);
    self.canvas.fill_rect(100, 100, 200 + angle, 100, fcolor);
    const cx = @divExact(@as(i32, @intCast(self.canvas.width)), 2);
    const cy = @divExact(@as(i32, @intCast(self.canvas.height)), 2);
    self.canvas.draw_line(cx, cy, cx + 100, cy + 50, fcolor);

    //canvas.fill_circle(300, 200, 50, fcolor);

    self.canvas.draw_triangle(200, 200, 220, 220, 140, 300, fcolor);

    //log("RENDRED TO ... {any}\n", .{pixels.ptr});
    return true;
}
