# UPDATING.md — how to run this site (the simple version)

Everything is files in this repo. Edit → run a script if it's book/posts → commit → push →
live in ~2 minutes. No servers, no databases, no admin panel.

## ✍️ Add a post (the thing you'll do most)

1. Create `posts-src\YYYY-MM-DD-your-title.md` (today's date, dashes in the name).
   First line: `# Your Title`. Then write in Markdown — `##` subheads, `-` lists, `**bold**`,
   `— — —` or `---` for a section break, `[text](url)` for links.
2. ```powershell
   powershell _build\build-posts.ps1
   ```
   This creates `posts\your-title.html` AND refreshes the cards on the front page. Newest first,
   automatically.
3. ```powershell
   git add -A ; git commit -m "post: your title" ; git push
   ```

Preview before pushing: double-click `index.html` locally.

## 📖 Update the book

Edit `book\source.txt` (it's the whole book, plain text) → `powershell _build\build-book.ps1`
→ commit + push. Chapters split on `#` headings.

## 🎨 Edit pages / look & feel

- Front page text: `index.html` (but NEVER between the `POSTS:START/END` markers — the script owns that).
- About / Contact: those files directly — both still have placeholder text marked for you.
- Colors/spacing/starfield: `css\site.css` (top `:root` block holds all the colors).
- Book reading theme: `book\book.css`.

## 🚀 Publish & verify

Push to `main` = deployed. Check: https://github.com/SScleves/thetruth/actions ("pages build and
deployment" green) → https://sscleves.github.io/thetruth/

## 🔧 When it looks wrong

| Symptom | Fix |
|---|---|
| Site shows the OLD version | Hard refresh: **Ctrl+F5** (Pages caches aggressively) |
| Post missing from front page | You skipped step 2 — run `_build\build-posts.ps1`, commit again |
| Post skipped by the script | Filename must be `YYYY-MM-DD-slug.md` exactly |
| 404 on everything | Settings → Pages → still "Deploy from a branch", `main` + `/ (root)`? |
| Weird characters (â€™) | The .md file isn't UTF-8 — save as UTF-8 in your editor |

## 📊 Later (from the lab)

RUM snippets (New Relic Browser / Dynatrace) get pasted where the
`<!-- RUM snippet slot -->` comments sit — plan lives in personal-lab
`vault/tech/Frontend RUM.md`. Repo settings (Pages, protection) eventually move into Terraform:
`personal-lab/terraform/modules/github-estate`.
