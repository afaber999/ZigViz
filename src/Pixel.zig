const std = @import("std");
pub const Self = @This();

// struct Canvas {

//     pub inline fn color_red(p: u32) u8 {
//         return @truncate(p >> 8 * 3);
//     }

//     pub inline fn color_green(p: u32) u8 {
//         return @truncate(p >> 8 * 2);
//     }

//     pub inline fn color_blue(p: u32) u8 {
//         return @truncate(p >> 8 * 1);
//     }

//     pub inline fn color_alpha(p: u32) u8 {
//         return @truncate(p >> 8 * 0);
//     }

//     pub inline fn color_as_bytes(p: u32) [4]u8 {
//         return std.mem.asBytes(p);
//     }
//     pub inline fn color_from_rgba(r: u8, g: u8, b: u8, a: u8) u32 {
//         return (@as(u32, r) << 8 * 3) | (@as(u32, g) << 8 * 2) | (@as(u32, b) << 8 * 1) | (@as(u32, a) << 8 * 0);
//     }
