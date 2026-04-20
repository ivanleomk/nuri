const std = @import("std");
const mer = @import("mer");
const h = mer.h;

pub const meta: mer.Meta = .{
    .title = "Deploying to Cloudflare",
    .description = "Deploy your Nuri site to Cloudflare Pages",
};

const page_node = page();

const raw_markdown = "---\ntitle: Deploying to Cloudflare\ndescription: Deploy your Nuri site to Cloudflare Pages\n---\n\n# Cloudflare\n\nCloudflare Pages provides fast, global hosting with automatic deployments from your Git repository. It's an ideal choice for Nuri sites because it handles static files efficiently and offers generous free tiers.\n\n## Cloudflare Pages\n\nSetting up Cloudflare Pages takes just a few minutes. First, push your Nuri project to a GitHub repository. Then log into the Cloudflare dashboard, navigate to Pages, and create a new project by connecting your repository.\n\nConfigure the build settings:\n- Build command: `nuri build && zig build prod`\n- Build output directory: `dist`\n\nOnce configured, every push to your repository will trigger an automatic deployment. Cloudflare builds your site and deploys it to their global edge network, making it fast for visitors worldwide.\n\n## Install Script\n\nCloudflare Pages doesn't include Zig by default in their build environment, so you'll need to install it during the build process. The `install-zig.sh` script handles this automatically by downloading and caching Zig 0.16.0.\n\nCreate this file in your project root:\n\n```bash\n#!/bin/bash\nset -e\nZIG_VERSION=\"0.16.0\"\nZIG_DIR=\"$HOME/.zig\"\n\nif [ ! -f \"$ZIG_DIR/zig\" ]; then\n    mkdir -p \"$ZIG_DIR\"\n    cd \"$ZIG_DIR\"\n    curl -L \"https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz\" -o zig.tar.xz\n    tar -xf zig.tar.xz --strip-components=1\n    rm zig.tar.xz\nfi\n\nexport PATH=\"$ZIG_DIR:$PATH\"\nzig version\nzig build prod\n```\n\nSet this as your build command in Cloudflare Pages: `./install-zig.sh`. The script checks if Zig is already cached (to speed up subsequent builds) and then builds your site to the `dist/` directory.\n\n## Custom Domain\n\nAfter your site deploys, you can add a custom domain from the Cloudflare Pages dashboard. Click \"Custom domains\" in your project settings, enter your domain name, and Cloudflare automatically configures the necessary DNS records.\n\nSince Cloudflare manages both your DNS and hosting, the process is seamless. Your site will be available on your custom domain with HTTPS automatically enabled.\n\n## Notes\n\nCurrently, Nuri has only been tested on Cloudflare Workers. While it should work on other platforms that support Zig/WASM, your mileage may vary. If you deploy successfully to other platforms, please let us know!\n";

pub fn render(req: mer.Request) mer.Response {
    // Check if client wants raw markdown
    if (std.mem.eql(u8, req.queryParam("format") orelse "", "md")) {
        return mer.text(.ok, raw_markdown);
    }
    return mer.render(req.allocator, page_node);
}

pub const prerender = true;

fn page() h.Node {
    return h.div(.{ .class = "page-wrapper" }, .{
        h.nav(.{ .class = "toc" }, .{
            h.div(.{ .class = "toc-header" }, "On this page"),
            h.ul(.{}, .{
                h.li(.{ .class = "toc-h1" }, .{h.a(.{ .href = "#cloudflare" }, "Cloudflare")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#cloudflare-pages" }, "Cloudflare Pages")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#install-script" }, "Install Script")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#custom-domain" }, "Custom Domain")}),
                h.li(.{ .class = "toc-h2" }, .{h.a(.{ .href = "#notes" }, "Notes")}),
            }),
        }),
        h.div(.{ .class = "page-content" }, .{
            h.h1(.{ .class = "title", .id = "cloudflare" }, "Cloudflare"),
            h.p(.{}, .{
                h.text("Cloudflare Pages provides fast, global hosting with automatic deployments from your Git repository. It's an ideal choice for Nuri sites because it handles static files efficiently and offers generous free tiers."),
            }),
            h.h2(.{ .class = "subtitle", .id = "cloudflare-pages" }, "Cloudflare Pages"),
            h.p(.{}, .{
                h.text("Setting up Cloudflare Pages takes just a few minutes. First, push your Nuri project to a GitHub repository. Then log into the Cloudflare dashboard, navigate to Pages, and create a new project by connecting your repository."),
            }),
            h.p(.{}, .{
                h.text("Configure the build settings:"),
            }),
            h.ul(.{}, .{
                h.li(.{}, .{
                    h.text("Build command: "),
                    h.code(.{}, "nuri build && zig build prod"),
                }),
                h.li(.{}, .{
                    h.text("Build output directory: "),
                    h.code(.{}, "dist"),
                }),
            }),
            h.p(.{}, .{
                h.text("Once configured, every push to your repository will trigger an automatic deployment. Cloudflare builds your site and deploys it to their global edge network, making it fast for visitors worldwide."),
            }),
            h.h2(.{ .class = "subtitle", .id = "install-script" }, "Install Script"),
            h.p(.{}, .{
                h.text("Cloudflare Pages doesn't include Zig by default in their build environment, so you'll need to install it during the build process. The "),
                h.code(.{}, "install-zig.sh"),
                h.text(" script handles this automatically by downloading and caching Zig 0.16.0."),
            }),
            h.p(.{}, .{
                h.text("Create this file in your project root:"),
            }),
            h.pre(.{}, .{h.code(.{}, "#!/bin/bash\nset -e\nZIG_VERSION=\"0.16.0\"\nZIG_DIR=\"$HOME/.zig\"\n\nif [ ! -f \"$ZIG_DIR/zig\" ]; then\n    mkdir -p \"$ZIG_DIR\"\n    cd \"$ZIG_DIR\"\n    curl -L \"https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz\" -o zig.tar.xz\n    tar -xf zig.tar.xz --strip-components=1\n    rm zig.tar.xz\nfi\n\nexport PATH=\"$ZIG_DIR:$PATH\"\nzig version\nzig build prod")}),
            h.p(.{}, .{
                h.text("Set this as your build command in Cloudflare Pages: "),
                h.code(.{}, "./install-zig.sh"),
                h.text(". The script checks if Zig is already cached (to speed up subsequent builds) and then builds your site to the "),
                h.code(.{}, "dist/"),
                h.text(" directory."),
            }),
            h.h2(.{ .class = "subtitle", .id = "custom-domain" }, "Custom Domain"),
            h.p(.{}, .{
                h.text("After your site deploys, you can add a custom domain from the Cloudflare Pages dashboard. Click \"Custom domains\" in your project settings, enter your domain name, and Cloudflare automatically configures the necessary DNS records."),
            }),
            h.p(.{}, .{
                h.text("Since Cloudflare manages both your DNS and hosting, the process is seamless. Your site will be available on your custom domain with HTTPS automatically enabled."),
            }),
            h.h2(.{ .class = "subtitle", .id = "notes" }, "Notes"),
            h.p(.{}, .{
                h.text("Currently, Nuri has only been tested on Cloudflare Workers. While it should work on other platforms that support Zig/WASM, your mileage may vary. If you deploy successfully to other platforms, please let us know!"),
            }),
        }),
    });
}
