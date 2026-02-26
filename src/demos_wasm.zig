const std = @import("std");
const common = @import("common.zig");
const Triangle = @import("demo_triangle.zig");
const Dot3d = @import("demo_dot3d.zig");
const Squish = @import("demo_squish.zig");
const Canvas = @import("Canvas.zig");

var triangle: Triangle = undefined;
var dot3d: Dot3d = undefined;
var squish: Squish = undefined;

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = error_return_trace;
    _ = ret_addr;
    common.log("PANIC: {s}\n", .{msg});
    @trap();
}

pub export fn triangle_init(width: i32, height: i32) ?[*]u32 {
    triangle = Triangle.init(std.heap.wasm_allocator, width, height) catch {
        return null;
    };
    return @ptrCast(triangle.pixel_ptr());
}

pub export fn triangle_render(dt: f32) bool {
    return triangle.render(dt);
}

pub export fn dot3d_init(width: i32, height: i32) ?[*]u32 {
    dot3d = Dot3d.init(std.heap.wasm_allocator, width, height) catch {
        return null;
    };
    return @ptrCast(dot3d.pixel_ptr());
}

pub export fn dot3d_render(dt: f32) bool {
    return dot3d.render(dt);
}

pub export fn squish_init(width: i32, height: i32) ?[*]u32 {
    squish = Squish.init(std.heap.wasm_allocator, width, height) catch {
        return null;
    };
    return @ptrCast(squish.pixel_ptr());
}

pub export fn squish_render(dt: f32) bool {
    return squish.render(dt);
}
