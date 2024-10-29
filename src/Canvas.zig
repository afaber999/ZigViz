const std = @import("std");

pub const Self = @This();
pub const PixelType = u32;

width: usize,
height: usize,
stride: usize,
pixels: []PixelType,

pub fn init(pixels: []PixelType, width: usize, height: usize, stride: usize) Self {
    return .{
        .width = width,
        .height = height,
        .stride = stride,
        .pixels = pixels,
    };
}

pub fn sub_canvas(self: Self, x: i32, y: i32, w: i32, h: i32) !Self {
    const bounds = self.normalized_bounds(x, y, w, h);

    if (bounds.is_empty()) return error.InvalidBounds;

    const sub_index = self.pixel_index(bounds.xs, bounds.ys);
    return Self.init(self.pixels[sub_index..], bounds.xe - bounds.xs, bounds.ye - bounds.ys, self.stride);
}

pub fn copy_nb(dst: *Self, src: Self) void {
    for (0..dst.height) |y| {
        for (0..dst.width) |x| {
            const nx = @divFloor(x * src.width, dst.width);
            const ny = @divFloor(y * src.height, dst.height);
            const p = src.pixel_value(nx, ny);
            dst.set_pixel(x, y, p);
        }
    }
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
    return @truncate(color >> 8 * 0);
}

pub inline fn green(color: PixelType) u8 {
    return @truncate(color >> 8 * 1);
}

pub inline fn blue(color: PixelType) u8 {
    return @truncate(color >> 8 * 2);
}

pub inline fn alpha(color: PixelType) u8 {
    return @truncate(color >> 8 * 3);
}

pub inline fn from_rgba(r: u8, g: u8, b: u8, a: u8) PixelType {
    return (@as(PixelType, r) << 8 * 0) | (@as(PixelType, g) << 8 * 1) | (@as(PixelType, b) << 8 * 2) | (@as(PixelType, a) << 8 * 3);
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
    const r1 = @as(u32, @intCast(red(c1)));
    const g1 = @as(u32, @intCast(green(c1)));
    const b1 = @as(u32, @intCast(blue(c1)));
    const a1 = alpha(c1);

    const r2 = @as(u32, @intCast(red(c2)));
    const g2 = @as(u32, @intCast(green(c2)));
    const b2 = @as(u32, @intCast(blue(c2)));
    const a2 = @as(u32, @intCast(alpha(c2)));

    const r: u32 = @min((r1 * (255 - a2) + r2 * a2) / 255, 255);
    const g: u32 = @min((g1 * (255 - a2) + g2 * a2) / 255, 255);
    const b: u32 = @min((b1 * (255 - a2) + b2 * a2) / 255, 255);

    return from_rgba(@truncate(r), @truncate(g), @truncate(b), a1);
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
    pub fn add(p1: Point, p2: Point) Point {
        return Point.init(p1.x + p2.x, p1.y + p2.y);
    }
    pub fn mag(pt: Point) f32 {
        const fx: f32 = @floatFromInt(pt.x);
        const fy: f32 = @floatFromInt(pt.y);
        return std.math.sqrt(@as(f32, fx * fx + fy * fy));
    }
    pub fn angle(pt: Point) f32 {
        const fx: f32 = @floatFromInt(pt.x);
        const fy: f32 = @floatFromInt(pt.y);
        return std.math.atan2(fy, fx);
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

    pub fn is_empty(self: Ubounds) bool {
        return self.xs >= self.xe or self.ys >= self.ye;
    }
};

pub fn normalized_bounds(self: Self, x: i32, y: i32, w: i32, h: i32) Ubounds {
    var xs = x;
    var ys = y;
    var xe = xs + w;
    var ye = ys + h;

    if (xs > xe) std.mem.swap(i32, &xs, &xe);
    if (ys > ye) std.mem.swap(i32, &ys, &ye);

    xs = @min(@max(0, xs), @as(i32, @intCast(self.width)));
    xe = @min(@max(0, xe), @as(i32, @intCast(self.width)));

    ys = @min(@max(0, ys), @as(i32, @intCast(self.height)));
    ye = @min(@max(0, ye), @as(i32, @intCast(self.height)));

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
                const bc = blend_color(self.pixel_value(x, y), color);
                self.set_pixel(x, y, bc);
            }
        }
    }
}

pub fn fill_rect(self: Self, x1: i32, y1: i32, w: i32, h: i32, color: PixelType) void {
    const bounds = self.normalized_bounds(x1, y1, w, h);

    for (bounds.ys..bounds.ye) |y| {
        for (bounds.xs..bounds.xe) |x| {
            const bc = blend_color(self.pixel_value(x, y), color);
            self.set_pixel(x, y, bc);
        }
    }
}

pub fn clear(self: *Self, color: PixelType) void {
    const w: i32 = @intCast(self.width);
    const h: i32 = @intCast(self.height);
    self.fill_rect(0, 0, w, h, color);
}

pub fn draw_line(self: Self, x1: i32, y1: i32, x2: i32, y2: i32, color: PixelType) void {
    const dx = x2 - x1;
    const dy = y2 - y1;

    var xs = x1;
    var ys = y1;
    var xe = x2;
    var ye = y2;

    // think this shouldn't draw anything if the line is a point
    if (dx == 0 and dy == 0) {
        if (self.in_bounds(i32, xs, ys)) {
            const x: i32 = @intCast(xs);
            const y: i32 = @intCast(ys);
            const bc = blend_color(self.pixel_value(x, y), color);
            self.set_pixel(x, y, bc);
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
            if (!self.in_x_bounds(i32, x)) continue;
            const y = @divFloor(dy * (x - xs), dx) + ys;
            if (!self.in_y_bounds(i32, y)) continue;

            const bc = blend_color(self.pixel_value(x, y), color);
            self.set_pixel(x, y, bc);
        }
    } else {
        if (ys > ye) {
            std.mem.swap(i32, &xs, &xe);
            std.mem.swap(i32, &ys, &ye);
        }

        var y = ys;
        while (y < ye) : (y += 1) {
            if (!self.in_y_bounds(i32, y)) continue;
            const x = @divFloor(dx * (y - ys), dy) + xs;
            if (!self.in_x_bounds(i32, x)) continue;

            const bc = blend_color(self.pixel_value(x, y), color);
            self.set_pixel(x, y, bc);
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

    // //const looper = struct { fn bar(a:i32) i32 {return  a+1;}.bar;
    // const Inner = struct {
    //     fn loop(pt: Point, p2: Point) void {
    //         var y = pt.y;
    //         while (y <= p2.y) : (y += 1) {
    //             if (!self.in_y_bounds(i32, y)) continue;

    //             var s1 = if (d12.y != 0) @divFloor((y - pt.y) * d12.x, d12.y) + pt.x else pt.x;
    //             var s2 = if (d13.y != 0) @divFloor((y - pt.y) * d13.x, d13.y) + pt.x else pt.x;

    //             if (s1 > s2) std.mem.swap(i32, &s1, &s2);

    //             var x = s1;
    //             while (x <= s2) : (x += 1) {
    //                 if (!self.in_x_bounds(i32, x)) continue;
    //                 const bc = blend_color(self.pixel_value(@intCast(x), @intCast(y)), color);
    //                 self.set_pixel(@intCast(x), @intCast(y), bc);
    //             }
    //         }
    //     }
    // };

    // Inner.loop(1);

    var y = p1.y;
    while (y <= p2.y) : (y += 1) {
        if (!self.in_y_bounds(i32, y)) continue;

        var s1 = if (d12.y != 0) @divFloor((y - p1.y) * d12.x, d12.y) + p1.x else p1.x;
        var s2 = if (d13.y != 0) @divFloor((y - p1.y) * d13.x, d13.y) + p1.x else p1.x;

        if (s1 > s2) std.mem.swap(i32, &s1, &s2);

        var x = s1;
        while (x <= s2) : (x += 1) {
            if (!self.in_x_bounds(i32, x)) continue;
            const bc = blend_color(self.pixel_value(@intCast(x), @intCast(y)), color);
            self.set_pixel(@intCast(x), @intCast(y), bc);
        }
    }

    const d32 = Point.sub(p2, p3);
    const d31 = Point.sub(p1, p3);

    y = p2.y;
    while (y <= p3.y) : (y += 1) {
        if (!self.in_y_bounds(i32, y)) continue;

        var s1 = if (d32.y != 0) @divFloor((y - p3.y) * d32.x, d32.y) + p3.x else p3.x;
        var s2 = if (d31.y != 0) @divFloor((y - p3.y) * d31.x, d31.y) + p3.x else p3.x;

        if (s1 > s2) std.mem.swap(i32, &s1, &s2);

        var x = s1;
        while (x <= s2) : (x += 1) {
            if (!self.in_x_bounds(i32, x)) continue;
            const bc = blend_color(self.pixel_value(@intCast(x), @intCast(y)), color);
            self.set_pixel(@intCast(x), @intCast(y), bc);
        }
    }
}

const BaryCoord = struct {
    u1: i32,
    u2: i32,
    u3: i32,
    det: i32,
};

fn barycentric(p1: Point, p2: Point, p3: Point, pt: Point) ?BaryCoord {
    const det: i32 = ((p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y));
    const ub1: i32 = ((p2.y - p3.y) * (pt.x - p3.x) + (p3.x - p2.x) * (pt.y - p3.y));
    const ub2: i32 = ((p3.y - p1.y) * (pt.x - p3.x) + (p1.x - p3.x) * (pt.y - p3.y));
    const ub3: i32 = det - ub1 - ub2;

    const ret = BaryCoord{
        .u1 = ub1,
        .u2 = ub2,
        .u3 = ub3,
        .det = det,
    };

    const sdet = std.math.sign(det);
    if ((std.math.sign(ub1) == sdet or ub1 == 0) and
        (std.math.sign(ub2) == sdet or ub2 == 0) and
        (std.math.sign(ub3) == sdet or ub3 == 0))
    {
        return ret;
    }
    return null;
}

// const NormalizeTriangle = struct {
//     lx: i32,
//     hx: i32,
//     ly: i32,
//     hy: i32,
// };

// fn normalize_triangle(self: Self, x1: i32, y1: i32, x2: i32, y2: i32, x3: i32, y3: i32) NormalizeTriangle {
//     const lx: i32 = @max(0, @min(@min(x1, x2), x3));
//     const hx: i32 = @min(@as(i32, @intCast(self.width)), @max(@max(x1, x2), x3));

//     if (lx > @as(i32, @intCast(self.width))) return error.InvalidBounds;
//     if (hx < 0) return error.InvalidBounds;

//     const ly: i32 = @max(0, @min(@min(y1, y2), y3));
//     const hy: i32 = @min(@as(i32, @intCast(self.height)), @max(@max(y1, y2), y3));

//     if (ly > @as(i32, @intCast(self.height))) return error.InvalidBounds;
//     if (hy < 0) return error.InvalidBounds;

//     return NormalizeTriangle{
//         .lx = lx,
//         .hx = hx,
//         .ly = ly,
//         .hy = hy,
//     };
// }

// fn PixelClampFromi32(r: i32, g: i32, b: i32, a: i32) PixelType {
//     const r = @as(u8, @intCast(@max(0, @min(r, 255))));
//     const g = @as(u8, @intCast(@max(0, @min(g, 255))));
//     const b = @as(u8, @intCast(@max(0, @min(b, 255))));
//     const a = @as(u8, @intCast(@max(0, @min(a, 255)));
//     return from_rgba(r, g, b, a);
// }

fn mix_colors3(c1: PixelType, c2: PixelType, c3: PixelType, bc: BaryCoord) PixelType {
    if (bc.det == 0) return from_rgba(0, 0, 0, 0);

    const r1 = @as(i32, @intCast(red(c1)));
    const g1 = @as(i32, @intCast(green(c1)));
    const b1 = @as(i32, @intCast(blue(c1)));
    const a1 = @as(i32, @intCast(alpha(c1)));

    const r2 = @as(i32, @intCast(red(c2)));
    const g2 = @as(i32, @intCast(green(c2)));
    const b2 = @as(i32, @intCast(blue(c2)));
    const a2 = @as(i32, @intCast(alpha(c2)));

    const r3 = @as(i32, @intCast(red(c3)));
    const g3 = @as(i32, @intCast(green(c3)));
    const b3 = @as(i32, @intCast(blue(c3)));
    const a3 = @as(i32, @intCast(alpha(c3)));

    const r4 = @divFloor((r1 * bc.u1 + r2 * bc.u2 + r3 * bc.u3), bc.det);
    const g4 = @divFloor((g1 * bc.u1 + g2 * bc.u2 + g3 * bc.u3), bc.det);
    const b4 = @divFloor((b1 * bc.u1 + b2 * bc.u2 + b3 * bc.u3), bc.det);
    const a4 = @divFloor((a1 * bc.u1 + a2 * bc.u2 + a3 * bc.u3), bc.det);

    const r = @as(u8, @truncate(@max(0, @min(r4, 255))));
    const g = @as(u8, @truncate(@max(0, @min(g4, 255))));
    const b = @as(u8, @truncate(@max(0, @min(b4, 255))));
    const a = @as(u8, @truncate(@max(0, @min(a4, 255))));

    return from_rgba(r, g, b, a);
}

// pub fn triangle3c(self: *Self, x1: i32, y1: i32, x2: i32, y2: i32, x3: i32, y3: i32, c1: PixelType, c2: PixelType, c3: PixelType) void {
//     if (self.normalize_triangle(x1, y1, x2, y2, x3, y3)) |nr| {
//         var y = nr.ly;
//         while (y < nr.hy) : (y += 1) {
//             var x = nr.lx;
//             while (x < nr.hx) : (x += 1) {
//                 if (self.olivec_barycentric(x1, y1, x2, y2, x3, y3, x, y)) |bc| {
//                     self.blend_color(self.pixel_ptr(x, y), mix_colors3(c1, c2, c3, bc));
//                 }
//             }
//         }
//     }
// }

pub fn draw_triangle3c(self: *Self, x1: i32, y1: i32, x2: i32, y2: i32, x3: i32, y3: i32, c1: PixelType, c2: PixelType, c3: PixelType) void {
    const Triangle3cData = struct {
        point: Point,
        color: PixelType,
    };

    var p1 = Triangle3cData{ .point = Point.init(x1, y1), .color = c1 };
    var p2 = Triangle3cData{ .point = Point.init(x2, y2), .color = c2 };
    var p3 = Triangle3cData{ .point = Point.init(x3, y3), .color = c3 };

    if (p1.point.y > p2.point.y) std.mem.swap(Triangle3cData, &p1, &p2);
    if (p2.point.y > p3.point.y) std.mem.swap(Triangle3cData, &p2, &p3);
    if (p1.point.y > p2.point.y) std.mem.swap(Triangle3cData, &p1, &p2);

    const d12 = Point.sub(p2.point, p1.point);
    const d13 = Point.sub(p3.point, p1.point);

    var y = p1.point.y;
    while (y <= p2.point.y) : (y += 1) {
        if (!self.in_y_bounds(i32, y)) continue;

        var s1 = if (d12.y != 0) @divFloor((y - p1.point.y) * d12.x, d12.y) + p1.point.x else p1.point.x;
        var s2 = if (d13.y != 0) @divFloor((y - p1.point.y) * d13.x, d13.y) + p1.point.x else p1.point.x;

        if (s1 > s2) std.mem.swap(i32, &s1, &s2);

        var x = s1;
        while (x <= s2) : (x += 1) {
            if (!self.in_x_bounds(i32, x)) continue;
            if (barycentric(p1.point, p2.point, p3.point, Point.init(x, y))) |bc| {
                const mc = mix_colors3(p1.color, p2.color, p3.color, bc);
                const oc = self.pixel_ptr(@intCast(x), @intCast(y));
                const nc = blend_color(oc.*, mc);
                oc.* = nc;
            }
        }
    }

    const d32 = Point.sub(p2.point, p3.point);
    const d31 = Point.sub(p1.point, p3.point);

    y = p2.point.y;
    while (y <= p3.point.y) : (y += 1) {
        if (!self.in_y_bounds(i32, y)) continue;

        var s1 = if (d32.y != 0) @divFloor((y - p3.point.y) * d32.x, d32.y) + p3.point.x else p3.point.x;
        var s2 = if (d31.y != 0) @divFloor((y - p3.point.y) * d31.x, d31.y) + p3.point.x else p3.point.x;

        if (s1 > s2) std.mem.swap(i32, &s1, &s2);

        var x = s1;
        while (x <= s2) : (x += 1) {
            if (!self.in_x_bounds(i32, x)) continue;

            if (barycentric(p1.point, p2.point, p3.point, Point.init(x, y))) |bc| {
                const mc = mix_colors3(p1.color, p2.color, p3.color, bc);
                const oc = self.pixel_ptr(@intCast(x), @intCast(y));
                const nc = blend_color(oc.*, mc);
                oc.* = nc;
            }

            // const bc = blend_color(self.pixel_value(@intCast(x), @intCast(y)), p2.color);
            // self.set_pixel(@intCast(x), @intCast(y), bc);
        }
    }
}
