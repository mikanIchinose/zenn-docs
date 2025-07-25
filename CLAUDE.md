# Claude Guidelines for Zenn-docs

## Commands
- `deno task preview` - Start local preview server
- `deno task zenn` - zenn-cli

## Project Structure
- `articles/` - All published and draft articles
- `books/` - Book content
- `images/` - Article images organized by article ID
- `scripts/` - Helper scripts
- `template/` - Template files for new content

## Style Guidelines
- **Format**: Markdown with Zenn-specific extensions
- **Images**: Store in `images/{article-id}/` directory
- **Code blocks**: Use proper language identifiers
- **Headings**: Use ## for sections, ### for subsections
- **Links**: Use [text](url) format for external links
- **File names**: Use auto-generated IDs for article files

## Notes
- This repository uses zenn-cli for content management
- TODOs: textlint setup, reviewdog setup, GitHub Actions pipeline