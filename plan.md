# Nuri CLI - Implementation Plan

## What I've Learned About Zig (0.16)

### Build System (build.zig.zon)
- Package name must be an enum literal: `.name = .nuri` not `"nuri"`
- Required fields: `name`, `version`, `fingerprint` (0x... hex value)
- Git dependencies need commit hash in URL: `git+https://.../repo.git#commit_hash`
- Dependencies also need `.hash` field with package hash
- Format: `package_name-version-hash_value`

### Build System (build.zig)
- `addExecutable` uses `root_module`:
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

### Standard Library Changes (0.16)
Major API reorganization:
- `std.heap.GeneralPurposeAllocator` → `std.heap.DebugAllocator`
- `std.fs.cwd()` → `std.Io.Dir.cwd()`
- File operations now require `io: Io` parameter
- `std.process.argsAlloc()` → use `init.minimal.args` iterator
- `std.time.sleep` → `std.Io.sleep(io, duration, clock)`
- `std.Thread.sleep` removed
- `main()` signature changed to `pub fn main(init: std.process.Init) !void`

### File System API (0.16)
All file operations moved to `std.Io.Dir`:
- `cwd.makeDir(io, path, permissions)` - permissions required
- `cwd.createDirPath(io, path)` - creates nested dirs
- `cwd.writeFile(io, options)` - write entire file
- `cwd.readFileAlloc(io, sub_path, allocator, limit)` - note param order
- `cwd.openDir(io, path, options)` - returns Dir handle
- `walker.next(io)` - requires io parameter

### String Handling
- Multiline strings with `\` prefix need careful formatting
- `std.fmt.allocPrint` for dynamic string formatting
- `entry.name` → `entry.basename` in walker entries
- `entry.path` is now `[:0]const u8` (null-terminated slice)

### Dependencies
- **koino**: Markdown parser - transitive deps (pcre, uucode) not yet Zig 0.16 compatible
- **zig-clap**: CLI parser - incompatible with 0.16 (uses deprecated builtins)
- **Decision**: Manual parsing for both CLI and Markdown

## Architecture

### Core Concept
Nuri is a content layer on top of merjs:
- Takes markdown files in `content/`
- Converts to merjs zig files in `src/app/`
- merjs handles the rest (routing, rendering, hot reload)

### File Structure
```
nuri/                      # CLI project root
├── build.zig             # Build configuration
├── build.zig.zon         # Dependencies (currently none)
├── src/
│   ├── main.zig          # CLI entry point
│   ├── parser.zig        # Markdown parser
│   └── generator.zig     # merjs code generator
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

## Markdown Parser Design

### Supported Elements
| Markdown | AST Node | merjs Output |
|----------|----------|---------------|
| `# Header` | Heading(level: 1) | `mer.h1(.{}, "Header")` |
| `## Header` | Heading(level: 2) | `mer.h2(.{}, "Header")` |
| `### Header` | Heading(level: 3) | `mer.h3(.{}, "Header")` |
| `paragraph` | Paragraph | `mer.p(.{}, .{children})` |
| `[text](url)` | Link(text, url) | `mer.a(.{.href = "url"}, "text")` |
| `**bold**` | Bold(text) | `mer.strong(.{}, "text")` |
| `*italic*` | Italic(text) | `mer.em(.{}, "text")` |
| `` `code` `` | InlineCode(text) | `mer.code(.{}, "text")` |
| `- item` | ListItem | `mer.li(.{}, "text")` |
| Code blocks | CodeBlock | `mer.pre(.{}, mer.code(...))` |

### Parsing Strategy
Simple line-based recursive descent parser:
1. **Tokenization**: Split into lines, identify block types
2. **Block parsing**: Headers, paragraphs, lists, code blocks
3. **Inline parsing**: Links, bold, italic, code within text
4. **AST generation**: Build tree structure
5. **Code generation**: Walk AST and output merjs

### Link Processing
- `./page.md` → `/page`
- `./folder/page.md` → `/folder/page`
- `http://...` → pass through unchanged
- Strip `.md` extension
- Convert relative paths to absolute routes

### Frontmatter
Format: YAML between `---` markers at top of file
```yaml
---
title: Page Title
description: Optional description
---
```

Extracted into:
```zig
pub const meta = .{
    .title = "Page Title",
    .description = "Optional description",
};
```

### Testing Strategy
1. Unit tests for each markdown element
2. Integration tests with sample files
3. Round-trip tests (parse → generate → compare)
4. Edge cases: nested elements, empty content, special chars

## Implementation Phases

### Phase 1: Foundation ✅
- [x] Git repository
- [x] CLI commands (init, build, dev, help)
- [x] File operations
- [x] Dev mode with polling

### Phase 2: Markdown Parser
- [ ] Frontmatter extraction
- [ ] Block elements (headers, paragraphs, lists, code)
- [ ] Inline elements (links, bold, italic, code)
- [ ] Link transformation
- [ ] AST structure

### Phase 3: Code Generator
- [ ] AST to merjs conversion
- [ ] Meta block generation
- [ ] Render function generation
- [ ] Proper indentation and formatting

### Phase 4: Polish
- [ ] Error handling
- [ ] Better error messages
- [ ] Configuration options
- [ ] Documentation

## Notes
- Keeping parser simple - no full CommonMark compliance needed
- Focus on elements used in typical documentation/sites
- Deterministic output for testing
- Self-contained implementation (no external deps)
