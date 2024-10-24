const std = @import("std");
const builtin = @import("builtin");

//if ( comptime builtin.cpu.arch == .wasm32) {
pub extern fn logWasm(s: [*]const u8, len: usize) void;
//}

pub fn log(comptime fmt: []const u8, args: anytype) void {
    if (comptime builtin.cpu.arch == .wasm32) {
        var buf: [4096]u8 = undefined;
        const slice = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
        logWasm(slice.ptr, slice.len);
    } else {
        unreachable;
    }
}
