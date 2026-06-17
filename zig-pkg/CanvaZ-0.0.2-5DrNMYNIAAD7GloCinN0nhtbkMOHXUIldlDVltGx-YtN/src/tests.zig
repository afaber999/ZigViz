const std = @import("std");
const CanvaZ = @import("CanvaZ");


pub fn main() !void {
 
     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var canvas = CanvaZ.init(allocator);
    const width = 800;
    const height = 600;

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    try canvas.createWindow("CanvaZ Demo", width,height);

    var r: u8 = 0;
    var g: u8 = 0;

    while (canvas.update() == 0) {
        const dataSice = canvas.dataBuffer();
        for (0..height) |y| {
            for (0..width) |x| {
                const index = y * width + x;
                dataSice[index] = CanvaZ.from_rgba(r, g, 0xFF, 0xFF);
                r +%= 1;
            }
            g +%= 1;
        }
        CanvaZ.sleep(16);
    }
}
