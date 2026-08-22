param(
  [string]$BaseUrl = "",
  [int]$ServerPort = 8776,
  [switch]$StartServer
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:$ServerPort/docs/beginner-guide.html" }
$npxName = if ($IsWindows) { "npx.cmd" } else { "npx" }
$pythonName = if ($IsWindows) { "python" } else { "python3" }
$npx = (Get-Command $npxName -ErrorAction Stop).Source
$session = "rlearnxr-beginner-guide"
$server = $null

function Invoke-PwCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & $npx --yes --package @playwright/cli playwright-cli "-s=$session" @Arguments
  if ($LASTEXITCODE -ne 0) { throw "playwright-cli failed: $($Arguments -join ' ')" }
}

try {
  if ($StartServer) {
    $serverOptions = @{FilePath = $pythonName; ArgumentList = @("-m", "http.server", "$ServerPort", "--bind", "127.0.0.1"); WorkingDirectory = $root; PassThru = $true}
    if ($IsWindows) { $serverOptions.WindowStyle = "Hidden" }
    $server = Start-Process @serverOptions
    $ready = $false
    1..30 | ForEach-Object {
      if (-not $ready) {
        try { $ready = (Invoke-WebRequest -Uri $BaseUrl -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 }
        catch { Start-Sleep -Milliseconds 250 }
      }
    }
    if (-not $ready) { throw "Beginner guide server did not become ready at $BaseUrl" }
  }

  Invoke-PwCli open $BaseUrl | Out-Null
  Invoke-PwCli snapshot | Out-Null
  Invoke-PwCli eval "async () => { const required = ['choose-route','learner-route','eight-stages','rstudio-route','build-lesson','commands','success','faq']; const missing = required.filter(id => !document.getElementById(id)); if (missing.length) throw new Error('guide sections missing: ' + missing.join(', ')); const images = [...document.images]; await Promise.all(images.map(image => image.complete ? Promise.resolve() : new Promise((resolve,reject) => { image.addEventListener('load', resolve, {once:true}); image.addEventListener('error', reject, {once:true}); }))); const broken = images.filter(image => !image.naturalWidth).map(image => image.getAttribute('src')); if (broken.length) throw new Error('guide images failed: ' + broken.join(', ')); return JSON.stringify({sections:required.length, images:images.length}); }" | Out-Null
  Invoke-PwCli eval "async () => { const local = [...document.querySelectorAll('a[href]')].map(link => link.getAttribute('href')).filter(href => href && !href.startsWith('#') && !href.startsWith('http://127.0.0.1')); for (const href of local) { const response = await fetch(new URL(href, location.href)); if (!response.ok) throw new Error('guide link failed: ' + href); } return 'guide-links-ready'; }" | Out-Null
  Invoke-PwCli eval "() => { const labels = [...document.querySelectorAll('img')].filter(image => !image.alt.trim()).length; if (labels) throw new Error('guide image without alt text'); const toc = document.querySelector('.toc nav'); if (!toc || toc.querySelectorAll('a').length < 8) throw new Error('guide TOC incomplete'); return 'guide-accessibility-proxy-ready'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rlearnxr-beginner-guide-top.png" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rlearnxr-beginner-guide-desktop.png" --full-page | Out-Null

  Invoke-PwCli resize 390 844 | Out-Null
  Invoke-PwCli eval "() => { if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('beginner guide horizontal overflow'); return 'guide-mobile-width-ready'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rlearnxr-beginner-guide-mobile.png" --full-page | Out-Null
  Write-Output "R-LearnXR beginner-guide browser smoke test passed."
} finally {
  try { Invoke-PwCli close | Out-Null } catch { }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
}
