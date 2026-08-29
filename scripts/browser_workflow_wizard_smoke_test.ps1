param(
  [int]$ServerPort = 8786
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$baseUrl = "http://127.0.0.1:$ServerPort"
$onWindows = $env:OS -eq "Windows_NT"
$npxName = if ($onWindows) { "npx.cmd" } else { "npx" }
$npx = (Get-Command $npxName -ErrorAction Stop).Source
$rscript = if ($onWindows) { "C:\Program Files\R\R-4.6.1\bin\Rscript.exe" } else { (Get-Command Rscript -ErrorAction Stop).Source }
$session = "rclaimlab-progressive-workflow-wizard"
$output = Join-Path $root "output\workflow-wizard-smoke"
$fixture = Join-Path $root "examples\role-workflows\synthetic-workflow-data.csv"
$fixtureBrowser = $fixture -replace '\\', '/'
$server = $null

function Invoke-PwCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & $npx --yes --package @playwright/cli playwright-cli "-s=$session" @Arguments
  if ($LASTEXITCODE -ne 0) { throw "playwright-cli failed: $($Arguments -join ' ')" }
}

try {
  New-Item -ItemType Directory -Force -Path $output | Out-Null
  $runner = Join-Path $root "scripts\run_workflow_wizard_demo.R"
  $serverArgs = "--vanilla `"$runner`" $ServerPort"
  $options = @{
    FilePath = $rscript
    ArgumentList = $serverArgs
    WorkingDirectory = $root
    PassThru = $true
    RedirectStandardOutput = (Join-Path $output "workflow-wizard-server.log")
    RedirectStandardError = (Join-Path $output "workflow-wizard-server-error.log")
  }
  if ($onWindows) { $options.WindowStyle = "Hidden" }
  $server = Start-Process @options
  Write-Output "Starting Workflow Wizard at $baseUrl"
  $ready = $false
  1..80 | ForEach-Object {
    if (-not $ready) {
      if ($server.HasExited) {
        $serverError = Get-Content -Raw -ErrorAction SilentlyContinue (Join-Path $output "workflow-wizard-server-error.log")
        throw "Workflow Wizard server exited early. $serverError"
      }
      try { $ready = (Invoke-WebRequest -Uri $baseUrl -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 }
      catch { Start-Sleep -Milliseconds 250 }
    }
  }
  if (-not $ready) { throw "Workflow Wizard did not become ready at $baseUrl" }
  Write-Output "Workflow Wizard is ready"

  Invoke-PwCli open $baseUrl | Out-Null
  Write-Output "Browser opened"
  Invoke-PwCli resize 1440 920 | Out-Null
  Invoke-PwCli snapshot | Out-Null
  Invoke-PwCli eval "() => { const root=document.documentElement; const scene=[...document.querySelectorAll('[data-storyboard-scene]')].find(node=>node.dataset.storyboardScene==='01'); if(!scene) throw new Error('purpose scene missing'); if(root.scrollWidth>root.clientWidth+1) throw new Error('scene 01 overflow'); return 'scene-01-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-storyboard-01-purpose.png" --full-page | Out-Null
  Write-Output "Captured scene 01"

  Invoke-PwCli click "#wizard_next_1" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(300); }" | Out-Null
  Invoke-PwCli eval "() => [...document.querySelectorAll('[data-storyboard-scene]')].find(node=>node.dataset.storyboardScene==='02')?.offsetParent ? 'scene-02-ok' : Promise.reject(new Error('source scene hidden'))" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-storyboard-02-source.png" --full-page | Out-Null
  Write-Output "Captured scene 02"
  Invoke-PwCli run-code "async page => { await page.locator('#local_file').setInputFiles('$fixtureBrowser'); }" | Out-Null
  Invoke-PwCli click "#inspect_source" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(1000); }" | Out-Null
  Invoke-PwCli click "#wizard_next_2" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(400); }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-storyboard-03-profile.png" --full-page | Out-Null
  Write-Output "Captured scene 03"

  Invoke-PwCli click "#import_source" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(1200); }" | Out-Null
  Invoke-PwCli click "#wizard_next_3" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(400); }" | Out-Null
  Invoke-PwCli fill "#question" "How well does the approved GLM classify held-out synthetic records?" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => document.querySelector('#outcome')?.selectize?.options?.outcome); await page.evaluate(() => document.querySelector('#outcome').selectize.setValue('outcome')); }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-storyboard-04-plan.png" --full-page | Out-Null
  Write-Output "Captured scene 04"

  Invoke-PwCli click "#wizard_next_4" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(300); }" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => document.querySelector('#analysis')?.selectize?.options?.glm); await page.evaluate(() => document.querySelector('#analysis').selectize.setValue('glm')); }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-storyboard-05-role.png" --full-page | Out-Null
  Write-Output "Captured scene 05"
  Invoke-PwCli click "#create_workflow" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(800); }" | Out-Null
  Invoke-PwCli click "#wizard_next_5" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(300); }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-storyboard-06-review.png" --full-page | Out-Null
  Write-Output "Captured scene 06"

  foreach ($selector in @("#approve_question", "#approve_roles", "#approve_method", "#approve_missing")) { Invoke-PwCli check $selector | Out-Null }
  Invoke-PwCli click "#build_workflow" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForTimeout(2200); }" | Out-Null
  Invoke-PwCli eval "() => { const ready=[...document.querySelectorAll('[data-storyboard-scene]')].find(node=>node.dataset.storyboardScene==='07'); if(!ready || !ready.offsetParent) throw new Error('completion scene missing'); if(!document.querySelector('.rw-build a')) throw new Error('compiled workspace link missing'); return 'completion-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-storyboard-07-ready.png" --full-page | Out-Null
  Write-Output "Captured scene 07"

  Invoke-PwCli click "#nav_data" | Out-Null
  Invoke-PwCli resize 390 844 | Out-Null
  Invoke-PwCli eval "() => { const root=document.documentElement; if(root.scrollWidth>root.clientWidth+1) throw new Error('wizard mobile overflow'); return 'wizard-mobile-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-storyboard-wizard-mobile.png" --full-page | Out-Null
  Write-Output "R-ClaimLab progressive Workflow Wizard passed: purpose, source, profile, plan, role, approval, build, and mobile."
} finally {
  try { Invoke-PwCli close | Out-Null } catch { }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
  $listeners = Get-NetTCPConnection -LocalPort $ServerPort -State Listen -ErrorAction SilentlyContinue
  foreach ($connection in $listeners) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($connection.OwningProcess)" -ErrorAction SilentlyContinue
    if ($null -ne $process -and $process.CommandLine -like "*run_workflow_wizard_demo.R*") {
      Stop-Process -Id $connection.OwningProcess -Force -ErrorAction SilentlyContinue
    }
  }
}
