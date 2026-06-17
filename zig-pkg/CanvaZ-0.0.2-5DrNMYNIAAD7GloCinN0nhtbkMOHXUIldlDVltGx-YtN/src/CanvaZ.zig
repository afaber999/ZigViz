const std = @import("std");
const builtin = @import("builtin");

const c = @cImport({
    switch (builtin.os.tag) {
        .linux => {
            @cDefine( "_DEFAULT_SOURCE", "1" );
            @cInclude("X11/XKBlib.h");
            @cInclude("X11/Xlib.h");
            //@cInclude("X11/keysim.h");
            @cInclude("sys/time.h");
            @cInclude("time.h");
        },
        .windows => {
            @cInclude("windows.h");
        },
        else => @compileError("Unsupported OS"),
    }
});

const PlatformSpecific = if (builtin.os.tag == .windows) struct {
    hwnd: c.HWND = null,

    fn canvasWndProc(hwnd: c.HWND, msg: c.UINT, wParam: c.WPARAM, lParam: c.LPARAM) callconv(.c) c.LRESULT {

        const contextAddress = @as(usize, @intCast( c.GetWindowLongPtrA(hwnd, c.GWLP_USERDATA )));
        const context_opt = @as(?*Context, @ptrFromInt(contextAddress));
        const context = context_opt orelse return c.DefWindowProcA(hwnd, msg, wParam, lParam);

        return switch (msg) {
            c.WM_PAINT => {
                var ps: c.PAINTSTRUCT = undefined;
                const hdc = c.BeginPaint(hwnd, &ps);
                const memdc = c.CreateCompatibleDC(hdc);
                const hbmp = c.CreateCompatibleBitmap(hdc, @intCast(context.width), @intCast(context.height));
                const oldbmp = c.SelectObject(memdc, hbmp);
                var bi : BINFO = std.mem.zeroes(BINFO);
                bi.bmiHeader.biSize = @sizeOf(BINFO);
                bi.bmiHeader.biWidth = @as(c.LONG, @intCast(context.width));
                bi.bmiHeader.biHeight = -@as(c.LONG, @intCast(context.height));
                bi.bmiHeader.biPlanes = 1;
                bi.bmiHeader.biBitCount = 32;
                bi.bmiHeader.biCompression = c.BI_BITFIELDS;
                bi.bmiColors[0].rgbRed = 0xff;
                bi.bmiColors[1].rgbGreen = 0xff;
                bi.bmiColors[2].rgbBlue = 0xff;

                _ = c.SetDIBitsToDevice(memdc, 0, 0, @intCast(context.width), @intCast(context.height), 0, 0, 0, @intCast(context.height),
                    context.buffer.ptr, @ptrCast(&bi), c.DIB_RGB_COLORS);
                _ = c.BitBlt(hdc, 0, 0, @intCast(context.width), @intCast(context.height), memdc, 0, 0, c.SRCCOPY);
                _ = c.SelectObject(memdc, oldbmp);
                _ = c.DeleteObject(hbmp);
                _ = c.DeleteDC(memdc);
                _ = c.EndPaint(hwnd, &ps);            
                return 0;
            },
            c.WM_MOUSEMOVE => {
                const lp : i32 = @intCast(lParam);
                context.mouse_x = @truncate(lp);
                context.mouse_y = @truncate(lp >> 16);
                return 0;
            },
            c.WM_CLOSE => c.DestroyWindow(hwnd),
            c.WM_DESTROY => {c.PostQuitMessage(0); return 0;},
            else => c.DefWindowProcA(hwnd, msg, wParam, lParam),    
        };
    }

} else if (builtin.os.tag == .linux) struct {
    dpy : ?*c.Display = undefined,
    w   : c.Window = undefined,
    gc  : c.GC = undefined,
    img : *c.XImage = undefined,
} else struct {

};


const Self = @This();

// need to be able to dynamic allocate context
// so it remains valid when object is copied!
const Context = struct {
    buffer:[]u32 = undefined,
    mouse_x : i16 = 0,
    mouse_y : i16 = 0,
    width : usize = 0,
    height : usize = 0,
    prev_time : i64 = 0,
    platform : PlatformSpecific = .{},
};

allocator: std.mem.Allocator,
context : *Context = undefined,

pub inline fn from_rgba(r: u8, g: u8, b: u8, a: u8) u32 {
    return (@as(u32, b) << 8 * 0) | (@as(u32, g) << 8 * 1) | (@as(u32, r) << 8 * 2) | (@as(u32, a) << 8 * 3);
}

fn getCurrentTimeMs() i64 {
    switch (builtin.os.tag) {
        .windows => {
            return @as(i64, @intCast(c.GetTickCount()));
        },
        .linux => {
            var tv: c.timeval = undefined;
            _ = c.gettimeofday(&tv, null);
            return @as(i64, @intCast(tv.tv_sec)) * 1000 + @as(i64, @intCast(tv.tv_usec)) / 1000;
        },
        .macos => {
            var tv: c.timeval = undefined;
            _ = c.gettimeofday(&tv, null);
            return @as(i64, @intCast(tv.tv_sec)) * 1000 + @as(i64, @intCast(tv.tv_usec)) / 1000;
        },
        else => @compileError("Unsupported OS"),
    }
}

pub fn init(allocator : std.mem.Allocator) !Self {
    const context = try allocator.create(Context);
    return Self{ 
        .allocator = allocator,
        .context = context,
    };
}

pub fn deinit(self : *Self) void {
    self.allocator.destroy(self.context);
}

pub fn dataBuffer(self: *Self) []u32 {
    return self.context.buffer[0..];
}

pub inline fn getPixel(self: *Self, x : usize, y : usize ) u32 {
    const index = y * self.context.width + x;
    return self.context.buffer[index];
}

pub inline fn setPixel(self: *Self, x : usize, y : usize, color: u32 ) void {
    const index = y * self.context.width + x;
    self.context.buffer[index] = color;
}


pub const BINFO = extern struct {
    bmiHeader: c.BITMAPINFOHEADER = std.mem.zeroes(c.BITMAPINFOHEADER),
    bmiColors: [3]c.RGBQUAD = std.mem.zeroes([3]c.RGBQUAD),
};

pub fn createWindow(self: *Self, name : [:0]const u8, width :usize, height :usize) !void {

    self.context.buffer = try self.allocator.alloc(u32, width*height);  
    errdefer self.allocator.free(self.context.buffer);
    self.context.width = width;
    self.context.height = height;
    self.context.prev_time = getCurrentTimeMs();

    switch (builtin.os.tag) {
        .linux => {
            self.context.platform.dpy = c.XOpenDisplay(null);

            const screen = c.DefaultScreen(self.context.platform.dpy);
            self.context.platform.w = c.XCreateSimpleWindow(
                self.context.platform.dpy,
                c.RootWindow(   self.context.platform.dpy, screen), 0, 0, @intCast( self.width ) ,@intCast( self.height), 0,
                    c.BlackPixel(self.context.platform.dpy, screen),
                    c.WhitePixel(self.context.platform.dpy, screen));

            self.context.platform.gc = c.XCreateGC(self.context.platform.dpy, self.context.platform.w, 0, 0);
            _ = c.XSelectInput(self.context.platform.dpy, self.context.platform.w,
               c.ExposureMask | c.KeyPressMask | c.KeyReleaseMask | c.ButtonPressMask |
                   c.ButtonReleaseMask | c.PointerMotionMask);
            _ = c.XStoreName(self.context.platform.dpy, self.context.platform.w, name);
            _ = c.XMapWindow(self.context.platform.dpy, self.context.platform.w);
            _ = c.XSync(self.context.platform.dpy, @intCast( self.context.platform.w));
            self.context.platform.img = c.XCreateImage(self.context.platform.dpy, c.DefaultVisual(self.context.platform.dpy, 0), 24, c.ZPixmap, 0,
                        @ptrCast( self.buffer.ptr), @intCast(self.width), @intCast(self.height), 32, 0);
        },
        .windows => {
            const instance = c.GetModuleHandleA(null);

            var wc = std.mem.zeroes(c.WNDCLASSEX);
            wc.cbSize = @sizeOf(c.WNDCLASSEX);
            wc.style = c.CS_VREDRAW | c.CS_HREDRAW;
            wc.lpfnWndProc = PlatformSpecific.canvasWndProc;
            wc.hInstance = instance;

            wc.lpszClassName = name;
            _ = c.RegisterClassExA(&wc);

            const dwStyle = c.WS_OVERLAPPEDWINDOW & ~c.WS_MAXIMIZEBOX & ~c.WS_MINIMIZEBOX | c.WS_VISIBLE;

            var window_rect = c.RECT {
                .left = 0,
                .top = 0,
                .right = @intCast(width),
                .bottom = @intCast(height),
            };
            _ = c.AdjustWindowRectEx(&window_rect, dwStyle, c.FALSE, 0);

            const hwnd = c.CreateWindowExA(
                    c.WS_EX_CLIENTEDGE, name, name,
                                    dwStyle, c.CW_USEDEFAULT, c.CW_USEDEFAULT,
                                    window_rect.right - window_rect.left + 4,
                                    window_rect.bottom - window_rect.top + 4,
                                    null, null, instance, null);

            if (hwnd == null) {
                return error.HandleInvalid;
            }

            self.context.platform.hwnd = hwnd;
            _ = c.SetWindowLongPtrA(hwnd, c.GWLP_USERDATA, @intCast(@intFromPtr( self.context )) );
            _ = c.ShowWindow(hwnd, c.SW_NORMAL);
            _ = c.UpdateWindow(hwnd);
        },
        else => @compileError("Unsupported OS"),
    }
}

pub fn destroyWindow(self: *Self) void {
    self.allocator.free(self.context.buffer);
}

pub fn update(self : Self) i32 {

    switch (builtin.os.tag) {
        .linux => {
            //var ev : c.XEvent = undefined;
            if (self.context.platform.dpy) |dpy| {
                _ = c.XPutImage(dpy, self.context.platform.w, self.context.platform.gc, self.context.platform.img, 0, 0, 0, 0, @intCast(self.width), @intCast(self.height));
                _ = c.XFlush(dpy);
            }
            // while ( c.XPending(self.context.platform.dpy) != 0) {
            //     c.XNextEvent(self.context.platform.dpy, &ev);
            //     switch (ev.type) {
            //         c.ButtonPress => {},
            //         c.ButtonRelease => {},
            //         else => {},
            //         // case ButtonRelease:
            //         // f->mouse = (ev.type == ButtonPress);
            //         // break;
            //         // case MotionNotify:
            //         // f->x = ev.xmotion.x, f->y = ev.xmotion.y;
            //         // break;
            //         // case KeyPress:
            //         // case KeyRelease: {
            //         // int m = ev.xkey.state;
            //         // int k = XkbKeycodeToKeysym(self.context.platform.dpy, ev.xkey.keycode, 0, 0);
            //         // for (unsigned int i = 0; i < 124; i += 2) {
            //         // if (FENSTER_KEYCODES[i] == k) {
            //         // f->keys[FENSTER_KEYCODES[i + 1]] = (ev.type == KeyPress);
            //         // break;
            //         // }
            //         // }
            //         // f->mod = (!!(m & ControlMask)) | (!!(m & ShiftMask) << 1) |
            //         //     (!!(m & Mod1Mask) << 2) | (!!(m & Mod4Mask) << 3);
            //         // } break;
            //     }
            // }

        },
        .windows => {
            var msg: c.MSG = undefined;
            while (c.PeekMessageA(&msg, null, 0, 0, c.PM_REMOVE) != 0 ) {
                if (msg.message == c.WM_QUIT)
                return -1;
                _ = c.TranslateMessage(&msg);
                _ = c.DispatchMessageA(&msg);
            }

            _ = c.InvalidateRect(self.context.platform.hwnd, null, c.TRUE);
        },
        else => @compileError("Unsupported OS"),
    }
    return 0;
    }

pub fn sleep(ms : u64) void { 
    switch (builtin.os.tag) {
        .windows => {
            c.Sleep(@as(c.DWORD, @intCast(ms)));
        },
        .linux, .macos => {
            c.usleep(@as(c_uint, @intCast(ms * 1000)));
        },
        else => @compileError("Unsupported OS"),
    }
}

pub fn delta(self : *Self) f32 {
    const new_time = getCurrentTimeMs();
    const delta_ms = @as(f32, @floatFromInt(new_time - self.context.prev_time));
    self.context.prev_time = new_time;    
    return delta_ms / 1000.0;
}
