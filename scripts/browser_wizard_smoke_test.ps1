param(
  [int]$Port = 8774,
  [switch]$StartServer
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$output = Join-Path $root "output\playwright"
New-Item -ItemType Directory -Force -Path $output | Out-Null
$fixture = Join-Path $root "examples\learning-analytics\data\learning_events.csv"
$npx = (Get-Command npx.cmd -ErrorAction Stop).Source
$session = "rlearnxr-wizard"
$server = $null
$browserOpened = $false
$desktopShot = Join-Path $output "rlearnxr-lesson-wizard-desktop.png"
$completeShot = Join-Path $output "rlearnxr-lesson-wizard-complete.png"
$mobileShot = Join-Path $output "rlearnxr-lesson-wizard-mobile.png"
$fixtureBrowserPath = $fixture.Replace("\", "/")

function Invoke-PwCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & $npx --yes --package "@playwright/cli" playwright-cli "-s=$session" @Arguments
  if ($LASTEXITCODE -ne 0) { throw "playwright-cli failed: $($Arguments -join ' ')" }
}

try {
  if ($StartServer) {
    $rscript = "C:\Program Files\R\R-4.6.1\bin\x64\Rscript.exe"
    if (-not (Test-Path -LiteralPath $rscript)) {
      $rscript = (Get-Command Rscript -ErrorAction Stop).Source
    }
    $runner = Join-Path $root "scripts\run_wizard_demo.R"
    $serverArgs = "--vanilla `"$runner`" $Port"
    $server = Start-Process -FilePath $rscript -ArgumentList $serverArgs -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $output "wizard-server.log") -RedirectStandardError (Join-Path $output "wizard-server-error.log")
  }

  $url = "http://127.0.0.1:$Port"
  $ready = $false
  for ($attempt = 0; $attempt -lt 40; $attempt++) {
    if ($null -ne $server -and $server.HasExited) {
      $serverError = Get-Content -LiteralPath (Join-Path $output "wizard-server-error.log") -Raw -ErrorAction SilentlyContinue
      throw "Lesson Wizard server exited early. $serverError"
    }
    try {
      $response = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 2
      if ($response.StatusCode -eq 200) { $ready = $true; break }
    } catch { Start-Sleep -Milliseconds 500 }
  }
  if (-not $ready) { throw "Lesson Wizard did not start at $url" }

  Invoke-PwCli open $url | Out-Null
  $browserOpened = $true
  Invoke-PwCli resize 1440 1000 | Out-Null
  Invoke-PwCli snapshot | Out-Null
  Invoke-PwCli run-code "async page => { await page.setInputFiles('#data_file', '$fixtureBrowserPath'); }" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => document.querySelectorAll('#column_profile table tbody tr').length >= 5 && document.querySelector('#analysis')); }" | Out-Null
  Invoke-PwCli eval "() => { const text = document.body.innerText; if (!text.includes('Principal component analysis') || !text.includes('Recommended')) throw new Error('analysis recommendation missing'); if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('desktop horizontal overflow'); return 'profile-and-recommendation-ready'; }" | Out-Null
  Invoke-PwCli run-code "async page => { await page.selectOption('#outcome', 'transfer_score'); await page.waitForFunction(() => document.querySelector('#analysis')?.value === 'lm' && ![...document.querySelector('#dimensions').selectedOptions].some(option => option.value === 'transfer_score')); }" | Out-Null
  Invoke-PwCli eval "() => { const text = document.querySelector('#analysis_recommendations').innerText; if (!text.includes('Linear regression') || !text.includes('Recommended')) throw new Error('outcome-aware regression recommendation missing'); return 'outcome-aware-recommendation-ready'; }" | Out-Null
  Invoke-PwCli run-code "async page => { await page.selectOption('#outcome', ''); await page.waitForFunction(() => document.querySelector('#analysis')?.value === 'prcomp'); }" | Out-Null
  Invoke-PwCli click "#preview_lesson" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => document.querySelector('.wizard-preview') && document.querySelector('.wizard-stage-pills').children.length === 8); }" | Out-Null
  Invoke-PwCli eval "() => { document.querySelector('#design-title').scrollIntoView({block:'start'}); window.scrollTo(0, window.scrollY); if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('preview horizontal overflow'); return 'preview-layout-ready'; }" | Out-Null
  Invoke-PwCli screenshot "--filename=$desktopShot" | Out-Null
  Invoke-PwCli click "#build_lesson" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => { const result = document.querySelector('.wizard-build-result'); return result && result.innerText.includes('Build complete'); }, null, { timeout: 20000 }); }" | Out-Null
  Invoke-PwCli eval "() => { document.querySelector('#build-title').scrollIntoView({block:'start'}); window.scrollTo(0, window.scrollY); if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('build horizontal overflow'); return 'build-layout-ready'; }" | Out-Null
  Invoke-PwCli screenshot "--filename=$completeShot" | Out-Null
  Invoke-PwCli resize 390 844 | Out-Null
  Invoke-PwCli eval "() => { if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('mobile horizontal overflow'); const labels = [...document.querySelectorAll('label[for]')]; const missing = labels.filter(label => !document.getElementById(label.htmlFor)); if (missing.length) throw new Error('missing form label targets'); return 'mobile-and-labels-ready'; }" | Out-Null
  Invoke-PwCli screenshot "--filename=$mobileShot" | Out-Null
  Invoke-PwCli close | Out-Null
  Write-Output "Lesson Wizard browser smoke test passed."
} finally {
  if ($browserOpened) { try { Invoke-PwCli close | Out-Null } catch { } }
  if ($null -ne $server -and -not $server.HasExited) { Stop-Process -Id $server.Id -Force }
  $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
  foreach ($connection in $listener) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($connection.OwningProcess)" -ErrorAction SilentlyContinue
    if ($null -ne $process -and $process.CommandLine -like "*run_wizard_demo.R*") {
      Stop-Process -Id $connection.OwningProcess -Force -ErrorAction SilentlyContinue
    }
  }
}
