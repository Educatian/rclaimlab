param(
  [string]$BaseUrl = "",
  [int]$ServerPort = 8775,
  [switch]$StartServer
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$lessonPath = "/examples/lesson/scene/index.html"
if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:$ServerPort$lessonPath" }
$npxCommand = Get-Command npx.cmd -ErrorAction SilentlyContinue
if (-not $npxCommand) { $npxCommand = Get-Command npx -ErrorAction Stop }
$npx = $npxCommand.Source
$session = "rlearnxr-persona-validation"
$artifactDir = Join-Path $root "output\audit\persona-validation"
$server = $null
$results = [ordered]@{
  learner = "NOT_RUN"
  screen_reader_proxy = "NOT_RUN"
  notes = "Synthetic proxy evidence; not a human pilot or screen-reader conformance claim."
}

New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

function Invoke-PwCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & $npx --yes --package @playwright/cli playwright-cli "-s=$session" @Arguments
  if ($LASTEXITCODE -ne 0) { throw "playwright-cli failed: $($Arguments -join ' ')" }
}

try {
  if ($StartServer) {
    $server = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", "$ServerPort", "--bind", "127.0.0.1" -WorkingDirectory $root -PassThru -WindowStyle Hidden
    $ready = $false
    1..30 | ForEach-Object {
      if (-not $ready) {
        try {
          $response = Invoke-WebRequest -Uri $BaseUrl -UseBasicParsing -TimeoutSec 2
          $ready = $response.StatusCode -eq 200
        } catch { Start-Sleep -Milliseconds 250 }
      }
    }
    if (-not $ready) { throw "Local lesson server did not become ready at $BaseUrl" }
  }

  Invoke-PwCli open $BaseUrl | Out-Null
  Invoke-PwCli click "#restart-lesson" | Out-Null
  Invoke-PwCli screenshot --filename="$artifactDir/01-learner-orient.png" | Out-Null

  Invoke-PwCli fill "#orient-input" "One row represents one observation, the label identifies it, and x, y, and z coordinates locate it in the data space."
  Invoke-PwCli click "#save-orient" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => document.querySelector('#orient-card').dataset.state === 'saved'); }" | Out-Null
  Invoke-PwCli fill "#prediction-input" "Positive x values will remain after the R filter."
  Invoke-PwCli click "#save-prediction" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => !document.querySelector('#r-panel').hidden); }" | Out-Null
  Invoke-PwCli screenshot --filename="$artifactDir/02-learner-run-r.png" | Out-Null

  Invoke-PwCli click "#run-r-code" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => { const ribbon = document.querySelector('#provenance-ribbon'); return ribbon && !ribbon.hidden && document.querySelector('#check-sync').textContent.includes('PASS'); }, null, { timeout: 20000 }); }" | Out-Null
  Invoke-PwCli screenshot --filename="$artifactDir/03-learner-r-verified.png" | Out-Null

  Invoke-PwCli click "#scene-tab" | Out-Null
  Invoke-PwCli eval "() => { const details = document.querySelector('#data-alternative'); details.open = true; const buttons = details.querySelectorAll('button.inspect-button').length; if (!buttons) throw new Error('accessible table has no point selectors'); return JSON.stringify({open: details.open, pointSelectors: buttons}); }" | Out-Null
  Invoke-PwCli eval "() => { const button = document.querySelector('#points-table button.inspect-button'); if (!button) throw new Error('first point selector missing'); button.click(); return button.textContent; }" | Out-Null
  Invoke-PwCli fill "#explanation-input" "Point inspect has a negative x value, but one point does not prove a general pattern."
  Invoke-PwCli click "#check-explanation" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => !document.querySelector('#transfer-card').hidden && document.querySelector('#explanation-feedback').dataset.state === 'success'); }" | Out-Null
  Invoke-PwCli screenshot --filename="$artifactDir/04-learner-explain.png" | Out-Null
  Invoke-PwCli eval "() => { const button = document.querySelector('#points-table tr:nth-child(2) button.inspect-button'); if (!button) throw new Error('second point selector missing'); button.click(); return button.textContent; }" | Out-Null
  Invoke-PwCli fill "#transfer-input" "Compared with inspect, point clean has a higher x value while remaining negative."
  Invoke-PwCli click "#check-transfer" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => !document.querySelector('#reproduce-card').hidden && document.querySelector('#transfer-feedback').dataset.state === 'success'); }" | Out-Null
  Invoke-PwCli click "#complete-lesson" | Out-Null
  Invoke-PwCli eval "() => { const status = document.querySelector('#lesson-status-text').textContent; if (status !== 'Lesson complete') throw new Error('learner completion did not unlock'); return status; }" | Out-Null
  Invoke-PwCli screenshot --filename="$artifactDir/05-learner-complete.png" | Out-Null
  $results.learner = "PASS"

  Invoke-PwCli click "#restart-lesson" | Out-Null
  $a11y = Invoke-PwCli eval "() => { const labels = [...document.querySelectorAll('label[for]')]; const missing = labels.filter(label => !document.getElementById(label.htmlFor)).map(label => label.htmlFor); const canvas = document.querySelector('#scene'); const checks = { main: !!document.querySelector('main[aria-label]'), learningNav: [...document.querySelectorAll('nav')].some(el => el.getAttribute('aria-label') === 'Learning path'), companion: [...document.querySelectorAll('[aria-label]')].some(el => el.getAttribute('aria-label') === 'Learning companion'), tablist: !!document.querySelector('[role=tablist]'), canvas: !!canvas && canvas.getAttribute('role') === 'img' && canvas.hasAttribute('aria-describedby'), tableCaption: !!document.querySelector('table caption'), tableHeaders: [...document.querySelectorAll('table th')].some(el => el.scope === 'col') && [...document.querySelectorAll('table th')].some(el => el.scope === 'row'), labels: missing.length === 0, liveRegions: document.querySelectorAll('[aria-live]').length >= 5, focusableCanvas: !!canvas && canvas.tabIndex >= 0 }; const failed = Object.entries(checks).filter(([, value]) => !value).map(([key]) => key); if (failed.length) throw new Error('screen-reader proxy failed: ' + failed.join(', ')); return JSON.stringify({checks, labelTargets: labels.length}); }"
  Invoke-PwCli eval "() => { const details = document.querySelector('#data-alternative'); details.open = true; return 'accessible-table-open'; }" | Out-Null
  Invoke-PwCli screenshot --filename="$artifactDir/06-screen-reader-proxy.png" | Out-Null
  $results.screen_reader_proxy = "PASS"

  $results | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $artifactDir "persona-validation.json")
  Write-Output "R-LearnXR persona validation passed: learner flow and screen-reader accessibility-tree proxy."
} finally {
  try { Invoke-PwCli close | Out-Null } catch { }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
}
