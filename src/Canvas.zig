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
