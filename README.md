
Simple graphics library that does not have any dependencies and renders everything into the given memory pixel by pixel. The library is written in ZIG and has no external dependencies, it can be compiled to WASM to run examples in the browser.

Inspired by https://github.com/tsoding/olive.c

To run 'as native', currently only tested for Windows platform, todo for Linux and MAC 
native code based on fenster c library from Serge Zaitsev
https://github.com/zserge/fenster

# build / run wasm samples
to build: zig build
to run:  start http server for zig-out\html\index.html

# run native examples
to build: zig build
to run: zig build run -- dot3d

# Examples
Currently there are 3 exmample:

zig-out\bin\zigviz.exe demoName
or use zig build run -- demoName

demoName
    squish
    dot3d
    triangle
  
