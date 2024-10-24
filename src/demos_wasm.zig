const std = @import("std");
const common = @import("common.zig");

const Triangle = @import("demo_triangle.zig");

var triangle: Triangle = undefined;

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    common.log("PANIC: {s}\n", .{msg});
    std.builtin.default_panic(msg, error_return_trace, ret_addr);
}

pub export fn triangle_init(width: i32, height: i32) ?[*]u32 {
    triangle = Triangle.init(std.heap.wasm_allocator, width, height) catch {
        return null;
    };
    return triangle.pixel_ptr();
}

pub export fn triangle_render(dt: f32) bool {
    return triangle.render(dt);
}
