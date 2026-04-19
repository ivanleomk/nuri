// Cloudflare Worker entry point
// Loads the merjs WASM bundle and handles HTTP requests

import wasmModule from "./nuri-site.wasm";

let wasmInstance = null;

export default {
  async fetch(request, env, ctx) {
    if (!wasmInstance) {
      // Instantiate the WASM module
      wasmInstance = await WebAssembly.instantiate(wasmModule, {
        env: {
          memory: new WebAssembly.Memory({ initial: 256, maximum: 512 }),
        },
      });
    }
    
    const url = new URL(request.url);
    
    // Pass request info to WASM via shared memory
    const reqData = JSON.stringify({
      method: request.method,
      path: url.pathname,
      headers: Object.fromEntries(request.headers),
    });
    
    // Call the WASM handler
    const memory = wasmInstance.exports.memory;
    const inputBuffer = new TextEncoder().encode(reqData);
    
    // Allocate memory in WASM
    const inputPtr = wasmInstance.exports.alloc(inputBuffer.length);
    new Uint8Array(memory.buffer, inputPtr, inputBuffer.length).set(inputBuffer);
    
    // Call handleRequest
    const outputLenPtr = wasmInstance.exports.alloc(4);
    const outputPtr = wasmInstance.exports.handleRequest(inputPtr, inputBuffer.length, outputLenPtr);
    
    // Read response length
    const outputLen = new Uint32Array(memory.buffer, outputLenPtr, 1)[0];
    
    // Read response body
    const outputBuffer = new Uint8Array(memory.buffer, outputPtr, outputLen);
    const html = new TextDecoder().decode(outputBuffer);
    
    // Free WASM memory
    wasmInstance.exports.free(inputPtr);
    wasmInstance.exports.free(outputPtr);
    wasmInstance.exports.free(outputLenPtr);
    
    return new Response(html, {
      headers: {
        "Content-Type": "text/html",
        "Cache-Control": "public, max-age=60",
      },
    });
  },
};
