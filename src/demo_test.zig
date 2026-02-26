const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");

var pixels: []u32 = undefined;
var canvas: Canvas = undefined;

pub extern fn logWasm(s: [*]const u8, len: usize) void;
pub fn print(comptime fmt: []const u8, args: anytype) void {
    var buf: [4096]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
    logWasm(slice.ptr, slice.len);
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;
    print("PANIC: {s}\n", .{msg});
    @trap();
}

var x_ofs: u32 = 0;

pub export fn init(width: i32, height: i32) ?[*]u32 {
    print("INIT from ZIG... {d} {d}\n", .{ width, height });

    const uw: usize = @intCast(width);
    const uh: usize = @intCast(height);
    pixels = std.heap.wasm_allocator.alloc(u32, uw * uh) catch {
        return null;
    };
    print("ALLOCATED  ZIG... {any}\n", .{pixels.ptr});
    canvas = Canvas.init(pixels, uw, uh, uw);
    //print("CANVAS  ZIG... {any}\n", .{canvas});
    return pixels.ptr;
}

pub export fn deinit() void {
    //if (pixels != undefined) {
    if (pixels.len > 0) {
        std.heap.wasm_allocator.free(pixels);
    }
    //}
    // pixels = undefined;
    // canvas = undefined;
}

pub export fn render(dt: f32) bool {
    x_ofs += 1;

    const angle: i32 = @intFromFloat(std.math.cos(dt) * 50);

    //    const x_off: u32 = @intFromFloat(dt / 100.0);

    const bcolor = Canvas.from_rgba(@intCast(x_ofs % 255), 10, 10, 255);
    const fcolor = Canvas.from_rgba(255, 0, 255, 255);
    canvas.fill_rect(0, 0, @intCast(canvas.width), @intCast(canvas.height), bcolor);
    canvas.fill_rect(100, 100, 200 + angle, 100, fcolor);
    const cx = @divExact(@as(i32, @intCast(canvas.width)), 2);
    const cy = @divExact(@as(i32, @intCast(canvas.height)), 2);
    canvas.draw_line(cx, cy, cx + 100, cy + 50, fcolor);

    //canvas.fill_circle(300, 200, 50, fcolor);

    canvas.draw_triangle(200, 200, 220, 220, 140, 300, fcolor);

    //print("RENDRED TO ... {any}\n", .{pixels.ptr});
    return true;
}
