# build-posts.ps1 — turn posts-src\*.md into posts\*.html and refresh the index cards.
# Post workflow: write posts-src\YYYY-MM-DD-slug.md (first line "# Title") →
#   powershell _build\build-posts.ps1 → commit posts-src + posts + index.html → push.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $repo 'posts-src'
$outDir = Join-Path $repo 'posts'
if (-not (Test-Path $srcDir)) { New-Item -ItemType Directory -Path $srcDir | Out-Null }
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$EM = [string][char]0x2014

function Convert-Inline([string]$s) {
  $s = $s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
  $s = $s -replace '\*\*([^*]+)\*\*', '<strong>$1</strong>'
  $s = $s -replace '\*([^*]+)\*', '<em>$1</em>'
  $s = $s -replace '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>'
  return $s
}
function Convert-Body([string[]]$body) {
  $html = New-Object System.Collections.Generic.List[string]; $inList = $false
  foreach ($line in $body) {
    $t = $line.Trim()
    if ($t -match '^<!--.*-->$') { continue }   # editor notes never publish
    if ($t -match ('^' + $EM + '(\s*' + $EM + ')+\s*$') -or $t -match '^---+\s*$') {
      if ($inList) { $html.Add('</ul>'); $inList = $false }
      $html.Add('<hr>'); continue
    }
    if ($t -eq '') { continue }
    if ($t -match '^###\s+(.+)$') { if ($inList) { $html.Add('</ul>'); $inList = $false }
      $html.Add('<h3>' + (Convert-Inline $Matches[1]) + '</h3>'); continue }
    if ($t -match '^##\s+(.+)$') { if ($inList) { $html.Add('</ul>'); $inList = $false }
      $html.Add('<h2>' + (Convert-Inline $Matches[1]) + '</h2>'); continue }
    if ($t -match '^-\s+(.+)$') { if (-not $inList) { $html.Add('<ul>'); $inList = $true }
      $html.Add('<li>' + (Convert-Inline $Matches[1]) + '</li>'); continue }
    if ($inList) { $html.Add('</ul>'); $inList = $false }
    $html.Add('<p>' + (Convert-Inline $t) + '</p>')
  }
  if ($inList) { $html.Add('</ul>') }
  return ($html -join "`n")
}

$template = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{TITLE}} &#8212; The Truth Truth</title>
  <link rel="stylesheet" href="../css/site.css">
</head>
<body>
<div class="sky"></div>
<nav class="site">
  <a class="brand" href="../index.html"><img src="../images/TheTruth2.png" alt="The Truth Truth">THE TRUTH TRUTH</a>
  <span class="links">
    <a href="../book/index.html">The Book</a>
    <a href="../index.html#discussions">Discussions</a>
    <a href="../about.html">About</a>
    <a href="../contact.html">Contact</a>
  </span>
</nav>
<div class="pagehead">
  <div class="kicker2">{{DATE}}</div>
  <h1>{{TITLE}}</h1>
</div>
<main>
<section>
{{BODY}}
</section>
</main>
<footer>
  The Truth Truth &#8212; <a href="../index.html">home</a> &#183; <a href="https://github.com/SScleves/thetruth">source on GitHub</a>
</footer>
</body>
</html>
'@

$posts = @()
Get-ChildItem -Path $srcDir -Filter *.md -File | Sort-Object Name -Descending | ForEach-Object {
  if ($_.BaseName -notmatch '^(\d{4}-\d{2}-\d{2})-(.+)$') {
    Write-Output ("SKIP (name must be YYYY-MM-DD-slug.md): " + $_.Name); return
  }
  $date = $Matches[1]; $slug = $Matches[2]
  $lines = ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8) -replace "`r`n", "`n") -split "`n"
  $title = $slug
  $bodyStart = 0
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^#\s+(.+)$') { $title = $Matches[1].Trim(); $bodyStart = $i + 1; break }
  }
  $body = $lines[$bodyStart..($lines.Count - 1)]
  $snippet = ''
  foreach ($l in $body) { $t = $l.Trim(); if ($t -ne '' -and $t -notmatch '^#' -and $t -notmatch '^<!--') { $snippet = $t; break } }
  if ($snippet.Length -gt 150) { $snippet = $snippet.Substring(0, 147) + '...' }
  $page = $template.Replace('{{TITLE}}', (Convert-Inline $title)).Replace('{{DATE}}', $date).Replace('{{BODY}}', (Convert-Body $body))
  [System.IO.File]::WriteAllText((Join-Path $outDir ($slug + '.html')), $page, (New-Object System.Text.UTF8Encoding($false)))
  $posts += New-Object psobject -Property @{ Slug = $slug; Title = $title; Date = $date; Snippet = $snippet }
}

# --- refresh index cards between the POSTS markers ------------------------------
$idxPath = Join-Path $repo 'index.html'
$idx = [System.IO.File]::ReadAllText($idxPath, [System.Text.Encoding]::UTF8)
$cards = ''
foreach ($p in $posts) {
  $cards += '      <a href="posts/' + $p.Slug + '.html">' + (Convert-Inline $p.Title) +
            '<span class="k">' + $p.Date + ' ' + [char]0x2014 + ' ' + (Convert-Inline $p.Snippet) + '</span></a>' + "`n"
}
if ($posts.Count -eq 0) { $cards = '      <a href="https://github.com/SScleves/thetruth/blob/main/TOPICS.md">First essays are being written<span class="k">The backlog is public</span></a>' + "`n" }
$pattern = '(?s)(<!-- POSTS:START[^>]*-->).*?(<!-- POSTS:END -->)'
$idx = [regex]::Replace($idx, $pattern, ('${1}' + "`n" + $cards + '${2}'))
[System.IO.File]::WriteAllText($idxPath, $idx, (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("Built {0} post(s); index cards refreshed." -f $posts.Count)
