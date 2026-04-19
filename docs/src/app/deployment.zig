const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Deployment Guide",
    .description = "Deploy Nuri sites to Cloudflare Workers, VPS, or static hosts",
};

const page_node = page();

pub fn render(req: mer.Request) mer.Response {
    return mer.render(req.allocator, page_node);
}

pub const prerender = true;

fn page() h.Node {
    return h.div(.{ .class = "page-wrapper" }, .{
        h.nav(.{ .class = "toc" }, .{
            h.div(.{ .class = "toc-header" }, "On this page"),
            h.ul(.{}, .{
                h.li(.{ .class = "toc-h1" }, .{h.a(.{ .href = "#deployment" }, "Deployment")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#cloudflare-workers-recommended" }, "Cloudflare Workers (Recommended)")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#quick-deploy" }, "Quick Deploy")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#manual-build" }, "Manual Build")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#configuration" }, "Configuration")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#what-gets-deployed" }, "What Gets Deployed")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#vps-server" }, "VPS / Server")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#docker" }, "Docker")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#flyio" }, "Fly.io")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#railway" }, "Railway")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#digitalocean-aws-gcp" }, "DigitalOcean / AWS / GCP")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#static-site" }, "Static Site")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#deployment-comparison" }, "Deployment Comparison")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#troubleshooting" }, "Troubleshooting")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#wasm-build-fails" }, "WASM Build Fails")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#static-assets-404" }, "Static Assets 404")}),
                h.li(.{ .class = "toc-h3" }, .{h.a(.{ .href = "#custom-domain" }, "Custom Domain")}),
            }),
        }),
        h.div(.{ .class = "page-content" }, .{
            h.h1(.{ .class = "title", .id = "deployment" }, "Deployment"),
            h.p(.{}, .{
                h.text("Nuri sites can be deployed in multiple ways depending on your needs."),
            }),
            h.h2(.{ .class = "subtitle", .id = "cloudflare-workers-recommended" }, "Cloudflare Workers (Recommended)"),
            h.p(.{}, .{
                h.text("Deploy as a WebAssembly edge function on Cloudflare's global network. This is the fastest and most scalable option."),
            }),
            h.h3(.{ .class = "heading", .id = "quick-deploy" }, "Quick Deploy"),
            h.p(.{}, .{
                h.text("From your project directory:"),
            }),
            h.pre(.{}, .{h.code(.{}, "cd docs  # or wherever your site is\nnpx wrangler deploy")}),
            h.p(.{}, .{
                h.text("Wrangler will automatically:"),
            }),
            h.ol(.{}, .{
                h.li(.{}, .{
                    h.text("Build the WASM bundle ("),
                    h.code(.{}, "zig build worker"),
                    h.text(")"),
                }),
                h.li(.{}, .{
                    h.text("Upload static assets from "),
                    h.code(.{}, "public/"),
                }),
                h.li(.{}, "Deploy to Cloudflare's edge network"),
            }),
            h.h3(.{ .class = "heading", .id = "manual-build" }, "Manual Build"),
            h.p(.{}, .{
                h.text("If you want to build first, then deploy:"),
            }),
            h.pre(.{}, .{h.code(.{}, "cd docs\nzig build worker\nnpx wrangler deploy --no-build")}),
            h.h3(.{ .class = "heading", .id = "configuration" }, "Configuration"),
            h.p(.{}, .{
                h.text("The "),
                h.code(.{}, "wrangler.toml"),
                h.text(" in your docs directory should look like this:"),
            }),
            h.pre(.{}, .{h.code(.{}, "name = \"nuri-docs\"\nmain = \"worker/index.js\"\ncompatibility_date = \"2024-12-01\"\n\n# Static assets (CSS, images, etc.)\n[assets]\ndirectory = \"public\"\n\n# Build WASM before deploying\n[build]\ncommand = \"zig build worker\"")}),
            h.h3(.{ .class = "heading", .id = "what-gets-deployed" }, "What Gets Deployed"),
            h.ul(.{}, .{
                h.li(.{}, .{
                    h.strong(.{}, "WASM bundle"),
                    h.text(" (~12KB gzipped): Contains your compiled Zig code"),
                }),
                h.li(.{}, .{
                    h.strong(.{}, "Static assets"),
                    h.text(": CSS, images, fonts from "),
                    h.code(.{}, "public/"),
                }),
                h.li(.{}, .{
                    h.strong(.{}, "Edge runtime"),
                    h.text(": JavaScript wrapper that loads WASM and handles requests"),
                }),
            }),
            h.p(.{}, .{
                h.text("The site runs globally on Cloudflare's edge — fast, scalable, and requires no server management."),
            }),
            h.h2(.{ .class = "subtitle", .id = "vps-server" }, "VPS / Server"),
            h.p(.{}, .{
                h.text("For traditional server deployment, build a native binary:"),
            }),
            h.pre(.{}, .{h.code(.{}, "zig build -Doptimize=ReleaseFast")}),
            h.p(.{}, .{
                h.text("The binary is at "),
                h.code(.{}, "zig-out/bin/nuri-site"),
                h.text(". Deploy it to any VPS or server."),
            }),
            h.h3(.{ .class = "heading", .id = "docker" }, "Docker"),
            h.pre(.{}, .{h.code(.{}, "FROM alpine:latest\nCOPY zig-out/bin/nuri-site /app/nuri-site\nEXPOSE 3000\nCMD [\"/app/nuri-site\"]")}),
            h.h3(.{ .class = "heading", .id = "flyio" }, "Fly.io"),
            h.pre(.{}, .{h.code(.{}, "fly launch\nfly deploy")}),
            h.h3(.{ .class = "heading", .id = "railway" }, "Railway"),
            h.p(.{}, .{
                h.text("Connect your GitHub repo to Railway. It will automatically build and deploy using the Dockerfile."),
            }),
            h.h3(.{ .class = "heading", .id = "digitalocean-aws-gcp" }, "DigitalOcean / AWS / GCP"),
            h.ol(.{}, .{
                h.li(.{}, .{
                    h.text("Build locally: "),
                    h.code(.{}, "zig build -Doptimize=ReleaseFast"),
                }),
                h.li(.{}, "Copy binary to server"),
                h.li(.{}, "Run with systemd or process manager (PM2, supervisord)"),
            }),
            h.h2(.{ .class = "subtitle", .id = "static-site" }, "Static Site"),
            h.p(.{}, .{
                h.text("For static hosting on Cloudflare Pages, Netlify, or GitHub Pages:"),
            }),
            h.pre(.{}, .{h.code(.{}, "# Option 1: Build and serve locally, then scrape\nzig build -Doptimize=ReleaseFast\n./zig-out/bin/nuri-site\n# Scrape the output (e.g., with wget or curl)\n\n# Option 2: Use prerender (if available)\nzig build prod  # Outputs to dist/")}),
            h.p(.{}, .{
                h.text("Upload the "),
                h.code(.{}, "dist/"),
                h.text(" folder to your static host."),
            }),
            h.h2(.{ .class = "subtitle", .id = "deployment-comparison" }, "Deployment Comparison"),
            h.table(.{}, .{
                h.thead(.{}, .{h.tr(.{}, .{
                    h.th(.{}, "Method"),
                    h.th(.{}, "Speed"),
                    h.th(.{}, "Complexity"),
                    h.th(.{}, "Best For"),
                })}),
                h.tbody(.{}, .{
                    h.tr(.{}, .{
                        h.td(.{}, "**Cloudflare Workers**"),
                        h.td(.{}, "Edge-fast (global)"),
                        h.td(.{}, "Low"),
                        h.td(.{}, "Most sites"),
                    }),
                    h.tr(.{}, .{
                        h.td(.{}, "**VPS/Bare Metal**"),
                        h.td(.{}, "Fast (single region)"),
                        h.td(.{}, "Medium"),
                        h.td(.{}, "Custom infra"),
                    }),
                    h.tr(.{}, .{
                        h.td(.{}, "**Docker/Fly.io**"),
                        h.td(.{}, "Fast (multi-region)"),
                        h.td(.{}, "Medium"),
                        h.td(.{}, "Containerized"),
                    }),
                    h.tr(.{}, .{
                        h.td(.{}, "**Static Site**"),
                        h.td(.{}, "CDN-fast"),
                        h.td(.{}, "Low"),
                        h.td(.{}, "Content-only sites"),
                    }),
                }),
            }),
            h.h2(.{ .class = "subtitle", .id = "troubleshooting" }, "Troubleshooting"),
            h.h3(.{ .class = "heading", .id = "wasm-build-fails" }, "WASM Build Fails"),
            h.p(.{}, .{
                h.text("If "),
                h.code(.{}, "zig build worker"),
                h.text(" fails with libc errors, ensure you're using the forked merjs that removes libc for WASM targets:"),
            }),
            h.pre(.{}, .{h.code(.{}, "# In build.zig.zon\n.merjs = .{\n    .url = \"git+https://github.com/ivanleomk/merjs.git#feat/0.16.0-migration\",\n    .hash = \"...\",\n}")}),
            h.h3(.{ .class = "heading", .id = "static-assets-404" }, "Static Assets 404"),
            h.p(.{}, .{
                h.text("Ensure "),
                h.code(.{}, "wrangler.toml"),
                h.text(" has the "),
                h.code(.{}, "[assets]"),
                h.text(" section pointing to your "),
                h.code(.{}, "public/"),
                h.text(" directory."),
            }),
            h.h3(.{ .class = "heading", .id = "custom-domain" }, "Custom Domain"),
            h.p(.{}, .{
                h.text("Add to "),
                h.code(.{}, "wrangler.toml"),
                h.text(":"),
            }),
            h.pre(.{}, .{h.code(.{}, "routes = [\n  { pattern = \"docs.yourdomain.com\", custom_domain = true }\n]")}),
            h.p(.{}, .{
                h.text("Then run "),
                h.code(.{}, "npx wrangler deploy"),
                h.text(" again."),
            }),
            h.p(.{}, .{
                h.a(.{ .href = "/" }, "← Back to Documentation"),
            }),
        }),
    });
}
