param(
  [string]$BaseUrl = "",
  [int]$ServerPort = 8774,
  [switch]$StartServer
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$lessonPath = "/examples/lesson/scene/index.html"
if (-not $BaseUrl) {
  $BaseUrl = "http://127.0.0.1:$ServerPort$lessonPath"
}
$npx = (Get-Command npx.cmd -ErrorAction Stop).Source
$session = "rclaimlab-offline-smoke"
$server = $null

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
  Invoke-PwCli eval "() => { const table = document.querySelector('#points-table'); if (!table || table.children.length === 0) throw new Error('static table did not load'); return 'static-fallback-ready'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-offline-fallback.png" | Out-Null
  Invoke-PwCli network-state-set offline | Out-Null
  Invoke-PwCli click "#r-tab" | Out-Null
  Invoke-PwCli click "#run-r-code" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(2500); }" | Out-Null
  Invoke-PwCli eval "() => { const text = document.querySelector('#r-console').textContent; if (!/network|WebR|failed|error|unable/i.test(text)) throw new Error('offline recovery message was not shown: ' + text); return text; }" | Out-Null
  Write-Output "R-ClaimLab offline browser smoke test passed: static fallback loaded and first-run network failure was surfaced."
} finally {
  try { Invoke-PwCli close | Out-Null } catch { }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
}
