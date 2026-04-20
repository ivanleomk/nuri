---
title: Deploying to Cloudflare
description: Deploy your Nuri site to Cloudflare Pages
---

# Cloudflare

Cloudflare Pages provides fast, global hosting with automatic deployments from your Git repository. It's an ideal choice for Nuri sites because it handles static files efficiently and offers generous free tiers.

## Cloudflare Pages

Setting up Cloudflare Pages takes just a few minutes. First, push your Nuri project to a GitHub repository. Then log into the Cloudflare dashboard, navigate to Pages, and create a new project by connecting your repository.

Configure the build settings:
- Build command: `nuri build && zig build prod`
- Build output directory: `dist`

Once configured, every push to your repository will trigger an automatic deployment. Cloudflare builds your site and deploys it to their global edge network, making it fast for visitors worldwide.

## Install Script

Cloudflare Pages doesn't include Zig by default in their build environment, so you'll need to install it during the build process. The `install-zig.sh` script handles this automatically by downloading and caching Zig 0.16.0.

Create this file in your project root:

```bash
#!/bin/bash
set -e
ZIG_VERSION="0.16.0"
ZIG_DIR="$HOME/.zig"

if [ ! -f "$ZIG_DIR/zig" ]; then
    mkdir -p "$ZIG_DIR"
    cd "$ZIG_DIR"
    curl -L "https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" -o zig.tar.xz
    tar -xf zig.tar.xz --strip-components=1
    rm zig.tar.xz
fi

export PATH="$ZIG_DIR:$PATH"
zig version
zig build prod
```

Set this as your build command in Cloudflare Pages: `./install-zig.sh`. The script checks if Zig is already cached (to speed up subsequent builds) and then builds your site to the `dist/` directory.

## Custom Domain

After your site deploys, you can add a custom domain from the Cloudflare Pages dashboard. Click "Custom domains" in your project settings, enter your domain name, and Cloudflare automatically configures the necessary DNS records.

Since Cloudflare manages both your DNS and hosting, the process is seamless. Your site will be available on your custom domain with HTTPS automatically enabled.

## Notes

Currently, Nuri has only been tested on Cloudflare Workers. While it should work on other platforms that support Zig/WASM, your mileage may vary. If you deploy successfully to other platforms, please let us know!
