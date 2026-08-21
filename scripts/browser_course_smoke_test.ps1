param(
  [string]$BaseUrl = "",
  [int]$ServerPort = 8775,
  [switch]$StartServer
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:$ServerPort/examples/index.html" }
$npxName = if ($IsWindows) { "npx.cmd" } else { "npx" }
$pythonName = if ($IsWindows) { "python" } else { "python3" }
$npx = (Get-Command $npxName -ErrorAction Stop).Source
$session = "rlearnxr-course-smoke"
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
    if (-not $ready) { throw "Course home server did not become ready at $BaseUrl" }
  }
  Invoke-PwCli open $BaseUrl | Out-Null
  Invoke-PwCli eval "() => { const catalog = window.RLEARNXR_CATALOG; const modules = document.querySelectorAll('.module'); if (!catalog || modules.length !== catalog.modules.length || modules.length !== 10) throw new Error('module library and catalog disagree'); const routes = [...document.querySelectorAll('[data-module]')].map(link => link.getAttribute('href')); const required = ['statistics-distribution/scene/index.html','statistics-bootstrap/scene/index.html','statistics-categories/scene/index.html','learning-analytics/scene/index.html','edm-patterns/scene/index.html']; if (required.some(route => !routes.includes(route))) throw new Error('reference lesson routes missing'); return 'course-library-ready'; }" | Out-Null
  Invoke-PwCli eval "() => { if (!document.querySelector('#educator-tools') || !document.querySelector('#receipt-files') || !document.querySelector('#resume-link')) throw new Error('course support controls missing'); return 'course-support-controls-ready'; }" | Out-Null
  Invoke-PwCli eval "async () => { const input = document.querySelector('#receipt-files'); const transfer = new DataTransfer(); transfer.items.add(new File([JSON.stringify({schema_version:'rlearnxr-receipt-2', lesson_id:'smoke', outcome:'complete', reproducibility:{artifact_hash:'smoke'}})], 'smoke.json', {type:'application/json'})); input.files = transfer.files; input.dispatchEvent(new Event('change', {bubbles:true})); await new Promise(resolve => setTimeout(resolve, 50)); if (document.querySelector('#receipt-count').textContent !== '1' || document.querySelector('#receipt-completed').textContent !== '1') throw new Error('receipt aggregation failed'); return 'receipt-summary-ready'; }" | Out-Null
  Invoke-PwCli eval "async () => { const routes = ['learning-analytics/scene/index.html', 'edm-patterns/scene/index.html']; for (const route of routes) { const response = await fetch(route); if (!response.ok) throw new Error('lesson route did not resolve: ' + route); } return 'application-routes-ready'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rlearnxr-course-home-desktop.png" | Out-Null
  Invoke-PwCli click "button[data-filter='Statistics']" | Out-Null
  Invoke-PwCli eval "() => { const expected = window.RLEARNXR_CATALOG.modules.filter(module => module.track === 'Statistics').length; const visible = [...document.querySelectorAll('.module')].filter(x => x.dataset.hidden !== 'true'); if (visible.length !== expected || expected !== 7) throw new Error('statistics filter failed'); return 'filter-ok'; }" | Out-Null
  Invoke-PwCli eval "() => { const catalog = window.RLEARNXR_CATALOG; const key = 'rlearnxr:' + catalog.course_id + ':progress:v1'; localStorage.setItem(key, JSON.stringify({last:'statistics-pca','statistics-pca':true})); window.dispatchEvent(new Event('pageshow')); const module = document.querySelector('[data-module=statistics-pca]').closest('.module'); if (!module.querySelector('.module-status').textContent.includes('Completed')) throw new Error('receipt-backed progress did not persist'); return 'progress-ok'; }" | Out-Null
  Invoke-PwCli eval "() => { const resume = document.querySelector('#resume-link'); if (!resume || resume.hidden || !resume.href.includes('penguin-pca/scene/index.html')) throw new Error('resume link did not appear'); return 'resume-link-ok'; }" | Out-Null
  Invoke-PwCli resize 390 844 | Out-Null
  Invoke-PwCli eval "() => { if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('course home horizontal overflow'); return 'mobile-width-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rlearnxr-course-home-mobile.png" | Out-Null
  Invoke-PwCli close | Out-Null
  Write-Output "R-LearnXR course-home browser smoke test passed."
} finally {
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
}
