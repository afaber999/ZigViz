const std = @import("std");

pub const Self = @This();
pub const PixelType = u32;

width: usize,
height: usize,
stride: usize,
pixels: []PixelType,

pub fn init(pixels: []u32, width: usize, height: usize, stride: usize) Self {
    return .{
        .width = width,
        .height = height,
        .stride = stride,
        .pixels = pixels,
    };
}

pub inline fn pixel_index(self: Self, x: usize, y: usize) usize {
    return y * self.stride + x;
}

pub inline fn pixel_value(self: Self, x: usize, y: usize) PixelType {
    return self.pixels[self.pixel_index(x, y)];
}

pub inline fn set_pixel(self: Self, x: usize, y: usize, color: PixelType) void {
    self.pixels[self.pixel_index(x, y)] = color;
}

pub inline fn pixel_ptr(self: Self, x: usize, y: usize) *PixelType {
    return &self.pixels[self.pixel_index(x, y)];
}

pub inline fn red(color: PixelType) u8 {
    return @truncate(color >> 8 * 3);
}

pub inline fn green(color: PixelType) u8 {
    return @truncate(color >> 8 * 2);
}

pub inline fn blue(color: PixelType) u8 {
    return @truncate(color >> 8 * 1);
}

pub inline fn alpha(color: PixelType) u8 {
    return @truncate(color >> 8 * 0);
}

pub inline fn from_rgba(r: u8, g: u8, b: u8, a: u8) PixelType {
    return (@as(PixelType, r) << 8 * 3) | (@as(PixelType, g) << 8 * 2) | (@as(PixelType, b) << 8 * 1) | (@as(PixelType, a) << 8 * 0);
}

pub inline fn in_x_bounds(self: Self, comptime T: type, x: T) bool {
    switch (T) {
        u32 => {
            const w: T = @intCast(self.width);
            return x < w;
        },
        i32 => {
            const w: T = @intCast(self.width);
            return 0 <= x and x < w;
        },
        else => @compileError(std.fmt.format("unsupported type: {}", .{T})),
    }
}

pub inline fn in_y_bounds(self: Self, comptime T: type, y: T) bool {
    switch (T) {
        u32 => {
            const h: T = @intCast(self.height);
            return y < h;
        },
        i32 => {
            const h: T = @intCast(self.height);
            return 0 <= y and y < h;
        },
        else => @compileError(std.fmt.format("unsupported type: {}", .{T})),
    }
}

pub inline fn in_bounds(self: Self, comptime T: type, x: T, y: T) bool {
    return (self.in_x_bounds(T, x) and self.in_y_bounds(T, y));
}

pub fn blend_color(c1: PixelType, c2: PixelType) PixelType {
    const r1 = red(c1);
    const g1 = green(c1);
    const b1 = blue(c1);
    const a1 = alpha(c1);

    const r2 = red(c2);
    const g2 = green(c2);
    const b2 = blue(c2);
    const a2 = alpha(c2);

    const r3: i32 = @min((@as(i32, r1) * (255 - a2) + @as(i32, r2) * @as(i32, a2)) / 255, 255);
    const g3: i32 = @min((@as(i32, g1) * (255 - a2) + @as(i32, g2) * @as(i32, a2)) / 255, 255);
    const b3: i32 = @min((@as(i32, b1) * (255 - a2) + @as(i32, b2) * @as(i32, a2)) / 255, 255);

    return from_rgba(@truncate(r3), @truncate(g3), @truncate(b3), a1);
}

pub const Point = struct {
    x: i32,
    y: i32,

    pub fn init(x: i32, y: i32) Point {
        return Point{
            .x = x,
            .y = y,
        };
    }

    pub fn sub(p1: Point, p2: Point) Point {
        return Point.init(p1.x - p2.x, p1.y - p2.y);
    }
};

pub const Ubounds = struct {
    xs: usize,
    ys: usize,
    xe: usize,
    ye: usize,

    pub fn init(xs: usize, ys: usize, xe: usize, ye: usize) Ubounds {
        return Ubounds{
            .xs = xs,
            .ys = ys,
            .xe = xe,
            .ye = ye,
        };
    }
};

// The point of this function is to produce two ranges xs..xe and ys..ye that are guaranteed to be safe to iterate over
// the canvas of size pixels_width by pixels_height without any boundary checks.
//
// const bounds = normalized_bounds(x, y, w, h);
//
// for (bounds.ys..bounds.ye) |y| {
//     for (bounds.xs..bounds.xe) |x| {
//         canvas.set_pixel(x, y, color);
//     }
// }

pub fn normalized_bounds(self: Self, x: i32, y: i32, w: i32, h: i32) Ubounds {
    var xs = x;
    var ys = y;
    var xe = xs + w;
    var ye = xs + h;

    if (xs > xe) std.mem.swap(i32, &xs, &xe);
    if (ys > ye) std.mem.swap(i32, &ys, &ye);

    xs = @min(@max(0, xs), @as(i32, @intCast(self.width - 1)));
    xe = @min(@max(0, xe), @as(i32, @intCast(self.width - 1)));

    ys = @min(@max(0, ys), @as(i32, @intCast(self.height - 1)));
    ye = @min(@max(0, ye), @as(i32, @intCast(self.height - 1)));

    return Ubounds.init(@intCast(xs), @intCast(ys), @intCast(xe), @intCast(ye));
}

pub fn fill_circle(self: Self, cx: i32, cy: i32, r: i32, color: PixelType) void {
    const bounds = self.normalized_bounds(cx - r, cy - r, 2 * r, 2 * r);
    const r2 = r * r;

    for (bounds.ys..bounds.ye) |y| {
        for (bounds.xs..bounds.xe) |x| {
            const dx = @as(i32, @intCast(x)) - cx;
            const dy = @as(i32, @intCast(y)) - cy;
            if (dx * dx + dy * dy <= r2) {
                self.set_pixel(x, y, color);
            }
        }
    }
}

pub fn fill_rect(canvas: Self, x1: i32, y1: i32, w: i32, h: i32, color: PixelType) void {
    const bounds = canvas.normalized_bounds(x1, y1, w, h);

    for (bounds.ys..bounds.ye) |y| {
        for (bounds.xs..bounds.xe) |x| {
            canvas.set_pixel(x, y, color);
        }
    }
    // // todo handel negative w and h
    // const x2 = x1 + w;
    // const y2 = y1 + h;

    // var y = y1;
    // while (y < y2) : (y += 1) {
    //     var x = x1;
    //     while (x < x2) : (x += 1) {
    //         //canvas.pixels[canvas.pixel_index(@intCast(x), @intCast(y))] = color;
    //         if (canvas.in_bounds(i32, x, y)) {
    //             canvas.pixels[canvas.pixel_index(@intCast(x), @intCast(y))] = color;
    //         }
    //     }
    // }
}

pub fn draw_line(canvas: Self, x1: i32, y1: i32, x2: i32, y2: i32, color: PixelType) void {
    const dx = x2 - x1;
    const dy = y2 - y1;

    var xs = x1;
    var ys = y1;
    var xe = x2;
    var ye = y2;

    if (dx == 0 and dy == 0) {
        if (canvas.in_bounds(i32, xs, ys)) {
            canvas.set_pixel(@intCast(xs), @intCast(ys), color);
            return;
        }
    }

    if (@abs(dx) > @abs(dy)) {
        if (xs > xe) {
            std.mem.swap(i32, &xs, &xe);
            std.mem.swap(i32, &ys, &ye);
        }

        var x = xs;
        while (x < xs) : (x += 1) {
            if (!canvas.in_x_bounds(i32, x)) continue;
            const y = @divFloor(dy * (x - xs), dx) + ys;
            if (!canvas.in_y_bounds(i32, y)) continue;
            canvas.set_pixel(@intCast(x), @intCast(y), color);
        }
    } else {
        if (ys > ye) {
            std.mem.swap(i32, &xs, &xe);
            std.mem.swap(i32, &ys, &ye);
        }

        var y = ys;
        while (y < ye) : (y += 1) {
            if (!canvas.in_y_bounds(i32, y)) continue;
            const x = @divFloor(dx * (y - ys), dy) + xs;
            if (!canvas.in_x_bounds(i32, x)) continue;
            canvas.set_pixel(@intCast(x), @intCast(y), color);
        }
    }
}

/// TODO: AA for triangle
pub fn draw_triangle(self: Self, x1: i32, y1: i32, x2: i32, y2: i32, x3: i32, y3: i32, color: PixelType) void {
    var p1 = Point.init(x1, y1);
    var p2 = Point.init(x2, y2);
    var p3 = Point.init(x3, y3);

    if (p1.y > p2.y) {
        std.mem.swap(Point, &p1, &p2);
    }
    if (p2.y > p3.y) {
        std.mem.swap(Point, &p2, &p3);
    }
    if (p1.y > p2.y) {
        std.mem.swap(Point, &p1, &p2);
    }

    const d12 = Point.sub(p2, p1);
    const d13 = Point.sub(p3, p1);

    var y = p1.y;
    while (y <= p2.y) : (y += 1) {
        if (!self.in_y_bounds(i32, y)) continue;

        var s1 = if (d12.y != 0) @divFloor((y - y1) * d12.x, d12.y) + x1 else x1;
        var s2 = if (d13.y != 0) @divFloor((y - y1) * d13.x, d13.y) + x1 else x1;

        if (s1 > s2) std.mem.swap(i32, &s1, &s2);

        var x = s1;
        while (x <= s2) : (x += 1) {
            if (!self.in_x_bounds(i32, x)) continue;
            self.set_pixel(@intCast(x), @intCast(y), color);
        }
    }

    const d32 = Point.sub(p2, p3);
    const d31 = Point.sub(p1, p3);

    y = p2.y;
    while (y <= p3.y) : (y += 1) {
        if (!self.in_y_bounds(i32, y)) continue;

        var s1 = if (d32.y != 0) @divFloor((y - y3) * d32.x, d32.y) + x3 else x3;
        var s2 = if (d31.y != 0) @divFloor((y - y3) * d31.x, d31.y) + x3 else x3;

        if (s1 > s2) std.mem.swap(i32, &s1, &s2);

        var x = s1;
        while (x <= s2) : (x += 1) {
            if (!self.in_x_bounds(i32, x)) continue;
            self.set_pixel(@intCast(x), @intCast(y), color);
        }
    }
    // int dx32 = x2 - x3;
    // int dy32 = y2 - y3;
    // int dx31 = x1 - x3;
    // int dy31 = y1 - y3;

    // for (int y = y2; y <= y3; ++y) {
    //     if (0 <= y && (size_t) y < oc.height) {
    //         int s1 = dy32 != 0 ? (y - y3)*dx32/dy32 + x3 : x3;
    //         int s2 = dy31 != 0 ? (y - y3)*dx31/dy31 + x3 : x3;
    //         if (s1 > s2) OLIVEC_SWAP(int, s1, s2);
    //         for (int x = s1; x <= s2; ++x) {
    //             if (0 <= x && (size_t) x < oc.width) {
    //                 olivec_blend_color(&OLIVEC_PIXEL(oc, x, y), color);
    //             }
    //         }
    //     }
    // }
}
