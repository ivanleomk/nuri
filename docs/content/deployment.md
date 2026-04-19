---
title: Deployment Guide
description: Deploy Nuri sites to Cloudflare Workers, VPS, or static hosts
---

# Deployment

Nuri sites can be deployed in multiple ways depending on your needs.

## Cloudflare Workers (Recommended)

Deploy as a WebAssembly edge function on Cloudflare's global network. This is the fastest and most scalable option.

### Quick Deploy

From your project directory:

```bash
cd docs  # or wherever your site is
npx wrangler deploy
```

Wrangler will automatically:
1. Build the WASM bundle (`zig build worker`)
2. Upload static assets from `public/`
3. Deploy to Cloudflare's edge network

### Automated Deploy with GitHub Actions

For automatic deployment on every push to `main`, use the included GitHub Actions workflow:

1. Add your Cloudflare credentials to GitHub Secrets:
   - Go to **Settings → Secrets and variables → Actions**
   - Add `CLOUDFLARE_API_TOKEN` - Create at [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens) with permissions:
     - Account: Cloudflare Workers Scripts (Edit)
     - Account: Cloudflare Pages (Edit)
     - User: User Details (Read)
     - Account: Account Settings (Read)
   - Add `CLOUDFLARE_ACCOUNT_ID` - Find at [dash.cloudflare.com](https://dash.cloudflare.com) (right sidebar)

2. The workflow at `.github/workflows/deploy.yml` will:
   - Trigger on every push to `main` that changes `docs/**`
   - Set up Zig 0.16.0
   - Build nuri binary
   - Build the docs
   - Deploy to Cloudflare Workers

3. Commit and push:
```bash
git add .
git push origin main
```

The site will automatically deploy! 🚀

### Manual Build

If you want to build first, then deploy:

```bash
cd docs
zig build worker
npx wrangler deploy --no-build
```

### Configuration

The `wrangler.toml` in your docs directory should look like this:

```toml
name = "nuri-docs"
main = "worker/index.js"
compatibility_date = "2024-12-01"

# Static assets (CSS, images, etc.)
[assets]
directory = "public"

# Build WASM before deploying
[build]
command = "zig build worker"
```

### What Gets Deployed

- **WASM bundle** (~12KB gzipped): Contains your compiled Zig code
- **Static assets**: CSS, images, fonts from `public/`
- **Edge runtime**: JavaScript wrapper that loads WASM and handles requests

The site runs globally on Cloudflare's edge — fast, scalable, and requires no server management.

## VPS / Server

For traditional server deployment, build a native binary:

```bash
zig build -Doptimize=ReleaseFast
```

The binary is at `zig-out/bin/nuri-site`. Deploy it to any VPS or server.

### Docker

```dockerfile
FROM alpine:latest
COPY zig-out/bin/nuri-site /app/nuri-site
EXPOSE 3000
CMD ["/app/nuri-site"]
```

### Fly.io

```bash
fly launch
fly deploy
```

### Railway

Connect your GitHub repo to Railway. It will automatically build and deploy using the Dockerfile.

### DigitalOcean / AWS / GCP

1. Build locally: `zig build -Doptimize=ReleaseFast`
2. Copy binary to server
3. Run with systemd or process manager (PM2, supervisord)

## Static Site

For static hosting on Cloudflare Pages, Netlify, or GitHub Pages:

```bash
# Option 1: Build and serve locally, then scrape
zig build -Doptimize=ReleaseFast
./zig-out/bin/nuri-site
# Scrape the output (e.g., with wget or curl)

# Option 2: Use prerender (if available)
zig build prod  # Outputs to dist/
```

Upload the `dist/` folder to your static host.

## Deployment Comparison

| Method | Speed | Complexity | Best For |
|--------|-------|------------|----------|
| **Cloudflare Workers** | Edge-fast (global) | Low | Most sites |
| **VPS/Bare Metal** | Fast (single region) | Medium | Custom infra |
| **Docker/Fly.io** | Fast (multi-region) | Medium | Containerized |
| **Static Site** | CDN-fast | Low | Content-only sites |

## Troubleshooting

### WASM Build Fails

If `zig build worker` fails with libc errors, ensure you're using the forked merjs that removes libc for WASM targets:

```toml
# In build.zig.zon
.merjs = .{
    .url = "git+https://github.com/ivanleomk/merjs.git#feat/0.16.0-migration",
    .hash = "...",
}
```

### Static Assets 404

Ensure `wrangler.toml` has the `[assets]` section pointing to your `public/` directory.

### Custom Domain

Add to `wrangler.toml`:

```toml
routes = [
  { pattern = "docs.yourdomain.com", custom_domain = true }
]
```

Then run `npx wrangler deploy` again.

---

[← Back to Documentation](index.md)
