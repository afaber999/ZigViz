# Simple Graphics Library in ZIG

A minimalistic graphics library written in **ZIG** designed for simplicity and educational purposes. This library has no external dependencies and renders graphics directly to memory, pixel by pixel. It can be compiled to **WASM** (WebAssembly) for running examples in a web browser.

### Inspiration
Inspired by [olive.c](https://github.com/tsoding/olive.c), this library aims to provide an approachable way to learn ZIG and basic computer graphics. It is not intended for high performance or complete functionality, but rather to serve as an educational tool for exploring rendering techniques and ZIG fundamentals.

## Key Characteristics
- **No External Dependencies**: Self-contained with no reliance on external libraries.
- **Simple, Educational Design**: Prioritizes straightforward rendering, suitable for learning.
- **Platform Support**: Native execution is currently tested only on **Windows**, with planned support for Linux and Mac.
- **WebAssembly (WASM) Compatibility**: Compile to WASM to run examples in a browser environment.

## Native Mode
In native mode, the library uses the **CanvaZ library** supports Windows, Linux and Mac.

---

## Installation & Usage
Tested with Zig 0.15

### Build and Run WASM Samples
1. **Build**: 
   ```bash
   zig build
   ```
2. **Run**: Start an HTTP server and open:
   ```
   zig-out\html\index.html
   ```

### Build and Run Native Examples
1. **Build**:
   ```bash
   zig build
   ```
2. **Run a specific example** (e.g., `dot3d`):
   ```bash
   zig build run -- dot3d
   ```

---

## Examples

The library currently includes three demonstration examples. You can run them using either method below:

1. **Using the executable directly**:
   ```bash
   zig-out\bin\zigviz.exe demoName
   ```
2. **Using `zig build`**:
   ```bash
   zig build run -- demoName
   ```

### Available Demos (`demoName`)
- **squish**: A simple animation demonstrating pixel manipulation.
- **dot3d**: Renders 3D points, showcasing basic 3D transformations.
- **triangle**: Renders a triangle, illustrating basic shape rendering.
- **triangle_tex**: Renders a triangle, illustrating basic shape rendering with texture.
- **triangle_3c**: Renders a triangle, illustrating basic shape rendering with color gradient per vertex.

---

This library serves as an educational tool to explore graphics rendering in ZIG and can be a foundation for deeper exploration into computer graphics.