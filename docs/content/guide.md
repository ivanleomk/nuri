---
title: Writing Content
description: How to write Markdown content for Nuri
---

# Writing Content

## File-based Routing

Each Markdown file in `content/` becomes a route:

| File | Route |
|---|---|
| `content/index.md` | `/` |
| `content/about.md` | `/about` |
| `content/blog/first.md` | `/blog/first` |

Every site **must** have a `content/index.md` — this is your homepage.

## Frontmatter

Add metadata at the top of your Markdown files:

```markdown
---
title: About Us
description: Learn more about our team
---

# About Us

Your content here...
```

## Supported Markdown

- Headings (`# H1` through `###### H6`)
- Paragraphs
- **Bold** and *italic* text
- `Inline code`
- Code blocks with language hints
- Unordered and ordered lists
- [Links](https://example.com) — local `.md` links are auto-transformed to routes

---

[← Installation](install.md) · [Commands →](commands.md)
