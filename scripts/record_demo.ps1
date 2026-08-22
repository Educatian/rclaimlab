param([int]$ServerPort = 8782)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$url = "http://127.0.0.1:$ServerPort"
$server = $null

try {
  $server = Start-Process -FilePath "python" -ArgumentList "-m", "http.server", "$ServerPort", "--bind", "127.0.0.1" -WorkingDirectory $root -PassThru -WindowStyle Hidden
  $ready = $false
  1..30 | ForEach-Object {
    if (-not $ready) {
      try { $ready = (Invoke-WebRequest -Uri "$url/examples/lesson/scene/index.html" -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 }
      catch { Start-Sleep -Milliseconds 250 }
    }
  }
  if (-not $ready) { throw "Demo server did not become ready at $url" }

  $runtime = Join-Path $root "tmp\playwright-runtime"
  $playwrightCli = Join-Path $runtime "node_modules\@playwright\test\cli.js"
  if (-not (Test-Path -LiteralPath $playwrightCli)) {
    & npm.cmd install --prefix $runtime --no-save --no-package-lock "@playwright/test"
    if ($LASTEXITCODE -ne 0) { throw "Could not prepare the isolated Playwright runtime." }
  }
  $env:RCLAIMLAB_DEMO_URL = $url
  $env:NODE_PATH = Join-Path $runtime "node_modules"
  & node $playwrightCli test "scripts/demo_recording.spec.js" --workers=1 --reporter=line
  if ($LASTEXITCODE -ne 0) { throw "Playwright demo recording failed." }
  Write-Output "R-ClaimLab direct-interaction recording created."
}
finally {
  Remove-Item Env:RCLAIMLAB_DEMO_URL -ErrorAction SilentlyContinue
  Remove-Item Env:NODE_PATH -ErrorAction SilentlyContinue
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
}
