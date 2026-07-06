# build-book.ps1 — regenerate the book site (book/) from book/source.txt
# Workflow: edit book/source.txt → powershell _build\build-book.ps1 → commit book/ + source.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $repo 'book\source.txt'
$outDir = Join-Path $repo 'book'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

$raw = [System.IO.File]::ReadAllText($srcPath, [System.Text.Encoding]::UTF8)
$lines = ($raw -replace "`r`n", "`n") -split "`n"
if ($lines[0] -match "Something Doesn.t Fit\.txt") { $lines = $lines[1..($lines.Count - 1)] }

function Convert-Inline([string]$s) {
  $s = $s -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
  $s = $s -replace '\*\*([^*]+)\*\*', '<strong>$1</strong>'
  $s = $s -replace '\*([^*]+)\*', '<em>$1</em>'
  return $s
}

# --- split into sections: front matter + one per "# " heading -------------------
$sections = @(); $current = New-Object psobject -Property @{ Title = ''; Lines = @() }
foreach ($line in $lines) {
  if ($line -match '^#\s+(.+)$') {
    $sections += $current
    $t = $Matches[1].Trim() -replace '\*', ''
    $current = New-Object psobject -Property @{ Title = $t; Lines = @() }
  } else { $current.Lines += $line }
}
$sections += $current
$front = $sections[0]; $chapters = $sections[1..($sections.Count - 1)]

function Convert-Body([string[]]$body) {
  $html = New-Object System.Collections.Generic.List[string]; $inList = $false
  foreach ($line in $body) {
    $t = $line.Trim()
    if ($t -match ('^' + [char]0x2014 + '(\s*' + [char]0x2014 + ')+\s*$')) {   # em-dash separator lines in the source
      if ($inList) { $html.Add('</ul>'); $inList = $false }
      $html.Add('<hr>'); continue
    }
    if ($t -eq '') { continue }   # blank lines don't close lists — source has gaps between items
    if ($t -match '^###\s+(.+)$') {
      if ($inList) { $html.Add('</ul>'); $inList = $false }
      $html.Add('<h3>' + (Convert-Inline ($Matches[1] -replace '\*', '')) + '</h3>'); continue
    }
    if ($t -match '^##\s+(.+)$') {
      if ($inList) { $html.Add('</ul>'); $inList = $false }
      $html.Add('<h2>' + (Convert-Inline ($Matches[1] -replace '\*', '')) + '</h2>'); continue
    }
    if ($t -match '^-\s+(.+)$') {
      if (-not $inList) { $html.Add('<ul>'); $inList = $true }
      $html.Add('<li>' + (Convert-Inline $Matches[1]) + '</li>'); continue
    }
    if ($inList) { $html.Add('</ul>'); $inList = $false }
    $html.Add('<p>' + (Convert-Inline $t) + '</p>')
  }
  if ($inList) { $html.Add('</ul>') }
  return ($html -join "`n")
}

$pageTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{TITLE}} &#8212; Something Doesn&#8217;t Fit</title>
<link rel="stylesheet" href="book.css">
<!-- RUM snippet slot: New Relic Browser / Dynatrace - see personal-lab vault/tech/Frontend RUM.md -->
</head>
<body>
<nav class="top"><a href="index.html">&#8801; Contents</a><span>{{CRUMB}}</span><a href="../index.html">The Truth</a></nav>
<main>
<h1>{{TITLE}}</h1>
{{BODY}}
</main>
<nav class="pager">{{PREV}}{{NEXT}}</nav>
</body>
</html>
'@

$n = $chapters.Count
for ($i = 0; $i -lt $n; $i++) {
  $ch = $chapters[$i]
  $prev = ''; $next = ''
  if ($i -gt 0) { $prev = '<a class="prev" href="chapter-' + $i + '.html">&#8592; ' + $chapters[$i-1].Title + '</a>' }
  else { $prev = '<a class="prev" href="index.html">&#8592; Cover</a>' }
  if ($i -lt ($n - 1)) { $next = '<a class="next" href="chapter-' + ($i + 2) + '.html">' + $chapters[$i+1].Title + ' &#8594;</a>' }
  $page = $pageTemplate.Replace('{{TITLE}}', (Convert-Inline $ch.Title)).
    Replace('{{BODY}}', (Convert-Body $ch.Lines)).
    Replace('{{CRUMB}}', ('Chapter {0} of {1}' -f ($i + 1), $n)).
    Replace('{{PREV}}', $prev).Replace('{{NEXT}}', $next)
  [System.IO.File]::WriteAllText((Join-Path $outDir ('chapter-' + ($i + 1) + '.html')), $page, (New-Object System.Text.UTF8Encoding($false)))
}

# --- cover / TOC ----------------------------------------------------------------
$toc = ''
for ($i = 0; $i -lt $n; $i++) {
  $toc += '<li><a href="chapter-' + ($i + 1) + '.html">' + (Convert-Inline $chapters[$i].Title) + '</a></li>' + "`n"
}
$frontHtml = Convert-Body ($front.Lines | Where-Object { $_.Trim() -notmatch '^Something Doesn.t [Ff]it$' })
$cover = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Something Doesn&#8217;t Fit</title>
<link rel="stylesheet" href="book.css">
<!-- RUM snippet slot: New Relic Browser / Dynatrace - see personal-lab vault/tech/Frontend RUM.md -->
</head>
<body>
<nav class="top"><span></span><span></span><a href="../index.html">The Truth</a></nav>
<main class="cover">
<h1 class="booktitle">Something Doesn&#8217;t Fit</h1>
<div class="epigraph">
{{FRONT}}
</div>
<h2 class="tochead">Contents</h2>
<ol class="toc">
{{TOC}}
</ol>
</main>
</body>
</html>
'@
$cover = $cover.Replace('{{FRONT}}', $frontHtml).Replace('{{TOC}}', $toc)
[System.IO.File]::WriteAllText((Join-Path $outDir 'index.html'), $cover, (New-Object System.Text.UTF8Encoding($false)))

Write-Output ("Built cover + {0} chapters -> {1}" -f $n, $outDir)
