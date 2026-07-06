# The Truth

A place to write about things worth discussing. Static site (Bootstrap 4), no build step —
edit HTML, push, done.

## Add a new post (the whole workflow)

1. Copy the newest `post-XX.html` to `post-<next number>.html`.
2. Edit: `<title>`, the post heading, the content section, and the hero image
   (drop a new image in `images/`, keep it under ~300 KB — export PNG/JPG, never the `.xcf` source).
3. Add the post to the Blog dropdown in the navbar of `index.html` (and the other pages that share it).
4. Move the `New` badge to your newest post.

Topic backlog: see `TOPICS.md` — capture ideas there before they become posts.

## Publish

GitHub Pages: repo Settings → Pages → Deploy from branch → `main` / root.
Site appears at `https://sscleves.github.io/thetruth/`.

## Planned

- Replace the template demo posts (Spider-Man/Batman/Panther) with real topics.
- Real user monitoring (New Relic Browser / Dynatrace RUM) — see the personal-lab repo,
  `vault/tech/Frontend RUM.md`.
