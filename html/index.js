let triangle_demo=document.getElementById('triangle_demo');
let dot3d_demo=document.getElementById('dot3d_demo');
let squish_demo=document.getElementById('squish_demo');

triangle_demo.width=800;
triangle_demo.height=600;

dot3d_demo.width=800;
dot3d_demo.height=600;

squish_demo.width=800;
squish_demo.height=600;

let triangle_demo_ctx=triangle_demo.getContext('2d');
let dot3d_demo_ctx=dot3d_demo.getContext('2d');
let squish_demo_ctx=squish_demo.getContext('2d');

let memory;

const libm = {
    "atan2f": Math.atan2,
    "cosf": Math.cos,
    "sinf": Math.sin,
    "sqrtf": Math.sqrt,
    "logWasm":(s, len ) => {  
        const buf = new Uint8Array(memory.buffer, s, len);
        console.log(new TextDecoder("utf8").decode(buf));
    }    
};

// Browser runtime for the Demo Virtual Console
function make_environment(...envs) {
    return new Proxy(envs, {
        get(target, prop, receiver) {
            for (let env of envs) {
                if (env.hasOwnProperty(prop)) {
                    return env[prop];
                }
            }
            return (...args) => {console.error("NOT IMPLEMENTED: "+prop, args)}
        }
    });
}


WebAssembly.instantiateStreaming(fetch("demos.wasm"), {
    "env": make_environment(libm)
}).then(w0 => {    
    w = w0
    memory = w.instance.exports.memory;


    let prev = null;
    let triangle_pixels = null;
    let dot3d_pixels = null;
    let squish_pixels = null;

    function renderInit() {

        triangle_pixels = w.instance.exports.triangle_init(triangle_demo.width,triangle_demo.height);
        if (triangle_pixels == null) {
            console.error("Failed to initialize triangle");
            return;
        }

        dot3d_pixels = w.instance.exports.dot3d_init(dot3d_demo.width,dot3d_demo.height);
        if (dot3d_pixels == null) {
            console.error("Failed to initialize dot3d");
            return;
        }

        squish_pixels = w.instance.exports.squish_init(squish_demo.width,squish_demo.height);
        if (squish_pixels == null) {
            console.error("Failed to initialize squish");
            return;
        }

        console.log("triangle pixels at: ", triangle_pixels);
        console.log("dot3d    pixels at: ", dot3d_pixels);
        console.log("squish   pixels at: ", squish_pixels);

        // init OK, can continue with rendering loop
        prev = performance.now();
        window.requestAnimationFrame(renderLoop);
    }
    
    function renderLoop() {  
        const now = performance.now();
        const dt = now - prev;

        w.instance.exports.triangle_render(dt);
        w.instance.exports.dot3d_render(dt);
        w.instance.exports.squish_render(dt);

        // console.log(pixels);
        // console.log(memory.buffer);
        const triangle_demo_img = new ImageData(new Uint8ClampedArray(memory.buffer, triangle_pixels, triangle_demo.width*triangle_demo.height*4), triangle_demo.width);
        triangle_demo_ctx.putImageData(triangle_demo_img, 0, 0);

        const dot3d_demo_img = new ImageData(new Uint8ClampedArray(memory.buffer, dot3d_pixels, dot3d_demo.width*dot3d_demo.height*4), dot3d_demo.width);
        dot3d_demo_ctx.putImageData(dot3d_demo_img, 0, 0);
        
        const squish_demo_img = new ImageData(new Uint8ClampedArray(memory.buffer, squish_pixels, squish_demo.width*squish_demo.height*4), squish_demo.width);
        squish_demo_ctx.putImageData(squish_demo_img, 0, 0);

        prev = now;
        window.requestAnimationFrame(renderLoop);
    }

    window.requestAnimationFrame(renderInit);
});

console.log(triangle_demo_ctx);
