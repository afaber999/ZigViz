const std = @import("std");
const c = @cImport({
    @cInclude("fenster.h");
});
const Canvas = @import("Canvas.zig");
const Dot3d = @import("demo_dot3d.zig");
const Squish = @import("demo_squish.zig");
const Triangle = @import("demo_triangle.zig");
const Triangle3c = @import("demo_triangle3c.zig");
const TriangleTex = @import("demo_triangle_tex.zig");

const Demo = union(enum) {
    dot3d: Dot3d,
    squish: Squish,
    triangle: Triangle,
    triangle3c: Triangle3c,
    triangle_tex: TriangleTex,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const width = 800;
    const height = 600;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <demo>\n", .{args[0]});
        return;
    }

    // nedded for ARGB to RGBA conversion
    var fenster_buffer = try allocator.alloc(u32, width * height);
    var canvas: Canvas = undefined;

    var demo: Demo = undefined;

    const demoName = args[1];
    if (std.mem.eql(u8, demoName, "dot3d")) {
        demo = Demo{ .dot3d = try Dot3d.init(allocator, width, height) };
        canvas = demo.dot3d.canvas;
    } else if (std.mem.eql(u8, demoName, "squish")) {
        demo = Demo{ .squish = try Squish.init(allocator, width, height) };
        canvas = demo.squish.canvas;
    } else if (std.mem.eql(u8, demoName, "triangle")) {
        demo = Demo{ .triangle = try Triangle.init(allocator, width, height) };
        canvas = demo.triangle.canvas;
    } else if (std.mem.eql(u8, demoName, "triangle3c")) {
        demo = Demo{ .triangle3c = try Triangle3c.init(allocator, width, height) };
        canvas = demo.triangle3c.canvas;
    } else if (std.mem.eql(u8, demoName, "triangle_tex")) {
        demo = Demo{ .triangle_tex = try TriangleTex.init(allocator, width, height) };
        canvas = demo.triangle_tex.canvas;
    } else {
        return error.Unreachable;
    }

    defer switch (demo) {
        .dot3d => demo.dot3d.deinit(),
        .squish => demo.squish.deinit(),
        .triangle => demo.triangle.deinit(),
        .triangle3c => demo.triangle3c.deinit(),
        .triangle_tex => demo.triangle_tex.deinit(),
    };

    var f : c.fenster = .{
        .width = width,
        .height = height,
        .title = "DEMO window",
        .buf = fenster_buffer.ptr,
    };

    _ = c.fenster_open(&f);
    defer c.fenster_close(&f);

    var now: i64 = c.fenster_time();
    var prev: i64 = now;

    while (c.fenster_loop(&f) == 0) {
        const dt: f32 = @floatFromInt(now - prev);
        prev = now;

        _ = switch (demo) {
            .dot3d => demo.dot3d.render(dt),
            .squish => demo.squish.render(dt),
            .triangle => demo.triangle.render(dt),
            .triangle3c => demo.triangle3c.render(dt),
            .triangle_tex => demo.triangle_tex.render(dt),
        };

        var idx: usize = 0;
        for (0..canvas.height) |y| {
            for (0..canvas.width) |x| {
                const pixel = canvas.pixel_value(x,y);
                fenster_buffer[idx] = Canvas.from_rgba(Canvas.blue(pixel), Canvas.green(pixel), Canvas.red(pixel), 255);
                idx += 1;
            }
        }

        // Exit when Escape is pressed
        if (f.keys[27] != 0) {
            break;
        }
        // Keep ~60 FPS
        const diff: i64 = 1000 / 60 - (c.fenster_time() - now);
        if (diff > 0) {
            c.fenster_sleep(diff);
        }
        now = c.fenster_time();
    }
}

const Self = @This();
