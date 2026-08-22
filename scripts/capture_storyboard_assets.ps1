param([int]$ServerPort = 8781)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$npxName = if ($IsWindows) { "npx.cmd" } else { "npx" }
$pythonName = if ($IsWindows) { "python" } else { "python3" }
$npx = (Get-Command $npxName -ErrorAction Stop).Source
$baseUrl = "http://127.0.0.1:$ServerPort"
$session = "rclaimlab-storyboard-assets"
$server = $null

function Invoke-PwCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & $npx --yes --package @playwright/cli playwright-cli "-s=$session" @Arguments
  if ($LASTEXITCODE -ne 0) { throw "playwright-cli failed: $($Arguments -join ' ')" }
}

try {
  $serverOptions = @{
    FilePath = $pythonName
    ArgumentList = @("-m", "http.server", "$ServerPort", "--bind", "127.0.0.1")
    WorkingDirectory = $root
    PassThru = $true
  }
  if ($IsWindows) { $serverOptions.WindowStyle = "Hidden" }
  $server = Start-Process @serverOptions
  $ready = $false
  1..30 | ForEach-Object {
    if (-not $ready) {
      try { $ready = (Invoke-WebRequest -Uri "$baseUrl/docs/storyboards/assets-src/rclaimlab-learner-journey.html" -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 }
      catch { Start-Sleep -Milliseconds 250 }
    }
  }
  if (-not $ready) { throw "Storyboard asset server did not become ready." }

  Invoke-PwCli open "$baseUrl/docs/storyboards/assets-src/rclaimlab-learner-journey.html" | Out-Null
  Invoke-PwCli resize 1920 1080 | Out-Null
  Invoke-PwCli screenshot --filename="docs/storyboards/assets/rclaimlab-learner-journey-v1.png" | Out-Null
  Invoke-PwCli run-code "async page => { await page.goto('$baseUrl/docs/storyboards/assets-src/rclaimlab-evidence-loop.html', {waitUntil: 'networkidle'}); }" | Out-Null
  Invoke-PwCli screenshot --filename="docs/storyboards/assets/rclaimlab-evidence-loop-v1.png" | Out-Null
  Invoke-PwCli close | Out-Null
  Write-Output "R-ClaimLab storyboard assets captured from tested browser states."
}
finally {
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
}
