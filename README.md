Very simple graphics library written in ZIG, no external dependencies, can be compiled to WASM to run examples in the browser.


Inspired by https://github.com/tsoding/olive.c


zig build run -- dot3d



# run wasm samples
start http server for zig-out\html\index.html


# run native examples

zig-out\bin\zigviz.exe demoName
or use zig build run -- demoName

demoName
    squish
    dot3d
    triangle
  
