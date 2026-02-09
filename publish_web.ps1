param(
  [string]$BaseHref = '/qrbase/'
)

$ErrorActionPreference = 'Stop'

Write-Host "Building web with base href $BaseHref..."
flutter build web --base-href $BaseHref

Write-Host "Syncing build/web to docs/..."
if (!(Test-Path docs)) { New-Item -ItemType Directory -Path docs | Out-Null }
robocopy build\web docs /MIR /NFL /NDL /NJH /NJS /NP | Out-Null

if (!(Test-Path docs\.nojekyll)) { New-Item -ItemType File -Path docs\.nojekyll | Out-Null }

Write-Host "Done. Now run: git add docs && git commit -m 'Publish web build' && git push"
