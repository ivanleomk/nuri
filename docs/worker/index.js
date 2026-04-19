// worker.js — Cloudflare Workers fetch handler for Nuri site
// Loads the WASM bundle and handles HTTP requests

import nuriWasm from "./nuri-site.wasm";

let instance = null;

async function getInstance() {
  if (instance) return instance;
  const mod = await WebAssembly.instantiate(nuriWasm, {
    env: { memory: new WebAssembly.Memory({ initial: 256 }) },
  });
  instance = mod.exports || mod;
  instance.init();
  return instance;
}

export default {
  async fetch(request, env, ctx) {
    const wasm = await getInstance();
    const url = new URL(request.url);
    
    // Encode request: "METHOD /path"
    const reqData = `${request.method} ${url.pathname}`;
    const encoder = new TextEncoder();
    const reqBytes = encoder.encode(reqData);
    
    // Allocate memory in WASM and copy request
    const inputPtr = wasm.alloc(reqBytes.length);
    new Uint8Array(wasm.memory.buffer, inputPtr, reqBytes.length).set(reqBytes);
    
    // Call handle()
    const outputPtr = wasm.handle(inputPtr, reqBytes.length);
    const outputLen = wasm.response_len();
    
    // Read response: status_u16 LE | ct_len_u16 LE | content-type | body
    const output = new Uint8Array(wasm.memory.buffer, outputPtr, outputLen);
    const status = new DataView(output.buffer, output.byteOffset, 2).getUint16(0, true);
    const ctLen = new DataView(output.buffer, output.byteOffset + 2, 2).getUint16(0, true);
    const contentType = new TextDecoder().decode(output.slice(4, 4 + ctLen));
    const body = output.slice(4 + ctLen);
    
    // Free WASM memory
    wasm.dealloc(inputPtr, reqBytes.length);
    // Note: output buffer is freed by WASM on next request
    
    return new Response(body, {
      status,
      headers: {
        "content-type": contentType,
        "cache-control": "public, max-age=60",
      },
    });
  },
};
