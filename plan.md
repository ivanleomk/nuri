# Nuri CLI - Implementation Plan & Learnings

## What I've Learned About Zig (0.15)

### Build System (build.zig.zon)
- Package name must be an enum literal: `.name = .nuri` not `"nuri"`
- Required fields: `name`, `version`, `fingerprint` (0x... hex value)
- Git dependencies need commit hash in URL: `git+https://.../repo.git#commit_hash`
- Dependencies also need `.hash` field with package hash
- Format: `package_name-version-hash_value`

### Build System (build.zig)
- `addExecutable` uses `root_module` instead of `root_source_file` directly:
  ```zig
  const exe = b.addExecutable(.{
      .name = "nuri",
      .root_module = b.createModule(.{
          .root_source_file = b.path("src/main.zig"),
          .target = target,
          .optimize = optimize,
      }),
  });
  ```
- Dependencies added via: `exe.root_module.addImport("name", dep.module("name"))`

### Standard Library Changes
- `std.time.sleep` moved to `std.Thread.sleep`
- `std.process.args` returns iterator, use `std.process.argsAlloc()` for slice
- File operations: `makeDir` creates single level, `makePath` creates nested

### String Handling
- Multiline strings with `\\` prefix need careful formatting
- `std.fmt.allocPrint` for dynamic string formatting
- Multiline strings can't have trailing content on same line as closing

### Dependencies Found
1. **koino** - Markdown parser (CommonMark + GFM compatible)
   - URL: `git+https://github.com/kivikakk/koino.git`
   - Working well, no compatibility issues

2. **zig-clap** - CLI argument parser
   - Latest version incompatible with Zig 0.15
   - Uses deprecated builtins: `@Tuple`, `@Struct`
   - Decision: Use manual argument parsing instead

## Final Architecture Plan

### Core Concept
Nuri is a content layer on top of merjs:
- Takes markdown files in `content/`
- Converts to merjs zig files in `src/app/`
- merjs handles the rest (routing, rendering, hot reload)

### File Structure
```
nuri/                      # CLI project root
├── build.zig             # Build configuration
├── build.zig.zon         # Dependencies
├── src/
│   └── main.zig          # CLI entry point
└── templates/            # Project scaffolding templates

project/                   # Generated project
├── content/              # Markdown source files
│   └── index.md
├── src/app/              # Generated merjs files
│   └── index.zig
├── public/               # Static assets
└── nuri.config.json      # Site configuration
```

### CLI Commands
1. `nuri init <name>` - Scaffolds new project with directories and sample content
2. `nuri build` - Converts all markdown files to merjs zig files
3. `nuri dev` - Watches content/ for changes and rebuilds
4. `nuri help` - Shows usage information

### Markdown to merjs Conversion

**Input (content/index.md):**
```markdown
---
title: Home
---

# Welcome

This is a [link](./page.md).
```

**Output (src/app/index.zig):**
```zig
pub const meta = .{
    .title = "Home",
};

pub fn render() !mer.Node {
    return mer.html(.{}, .{
        mer.h1(.{}, "Welcome"),
        mer.p(.{}, .{
            "This is a ",
            mer.a(.{.href = "/page"}, "link"),
            ".",
        }),
    });
}
```

### Implementation Details

#### AST to merjs Mapping
Using koino to parse markdown to AST, then transform each node type:

| Markdown | merjs Output |
|----------|---------------|
| `h1` | `mer.h1(.{}, "text")` |
| `p` | `mer.p(.{}, .{children})` |
| `a[href]` | `mer.a(.{.href = "/path"}, "text")` |
| `ul/ol` | `mer.ul()` / `mer.ol()` |
| `li` | `mer.li()` |
| `strong` | `mer.strong()` |
| `em` | `mer.em()` |
| `code` | `mer.code()` |

#### Link Processing
- Convert `./page.md` → `/page`
- Strip `.md` extension
- Convert relative paths to absolute routes
- External links (http/https) pass through unchanged

#### Frontmatter Parsing
- Format: YAML between `---` markers at top of file
- Extract: `title` (required), `date`, `draft`, `layout`
- Store in `pub const meta = .{...}`

#### Hot Reload Strategy
Simple polling approach:
1. Poll `content/` directory every 1 second
2. Compare mtimes to detect changes
3. Rebuild changed files
4. merjs's built-in watcher detects zig file changes

### Dependencies
- **koino**: Markdown parser (already working)
- **No CLI library**: Manual argument parsing (simpler, no compatibility issues)

### Testing Strategy
1. Build CLI binary
2. Run `nuri init test` to create project
3. Run `nuri build` to convert markdown
4. Verify generated zig files compile with merjs
5. Test hot reload by editing markdown

### Next Steps
1. Clear current implementation
2. Create clean project structure
3. Implement CLI with manual arg parsing
4. Integrate koino for markdown parsing
5. Build AST to merjs transformer
6. Add file watching for dev mode
7. Test end-to-end workflow
