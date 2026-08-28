param(
  [string]$BaseUrl = "",
  [int]$ServerPort = 8778,
  [switch]$StartServer
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $BaseUrl) {
  $BaseUrl = "http://127.0.0.1:$ServerPort/examples/role-workflows/reviewer/app/index.html"
}
$npxName = if ($IsWindows) { "npx.cmd" } else { "npx" }
$pythonName = if ($IsWindows) { "python" } else { "python3" }
$npx = (Get-Command $npxName -ErrorAction Stop).Source
$session = "rclaimlab-role-workflow-smoke"
$server = $null

function Invoke-PwCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & $npx --yes --package @playwright/cli playwright-cli "-s=$session" @Arguments
  if ($LASTEXITCODE -ne 0) { throw "playwright-cli failed: $($Arguments -join ' ')" }
}

try {
  if ($StartServer) {
    $options = @{
      FilePath = $pythonName
      ArgumentList = @("-m", "http.server", "$ServerPort", "--bind", "127.0.0.1")
      WorkingDirectory = $root
      PassThru = $true
    }
    if ($IsWindows) { $options.WindowStyle = "Hidden" }
    $server = Start-Process @options
    $ready = $false
    1..30 | ForEach-Object {
      if (-not $ready) {
        try { $ready = (Invoke-WebRequest -Uri $BaseUrl -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 }
        catch { Start-Sleep -Milliseconds 250 }
      }
    }
    if (-not $ready) { throw "Role workflow server did not become ready at $BaseUrl" }
  }

  Invoke-PwCli open $BaseUrl | Out-Null
  Invoke-PwCli snapshot | Out-Null
  Invoke-PwCli resize 1440 920 | Out-Null
  Invoke-PwCli eval "() => { const root=document.documentElement; const activities=document.querySelectorAll('#activity-list button'); if(document.body.dataset.workflowReady!=='true') throw new Error('workflow readiness marker missing'); if(document.querySelector('#role-badge')?.textContent!=='Model Reviewer') throw new Error('reviewer role missing'); if(activities.length!==7) throw new Error('reviewer activity registry mismatch'); if(root.scrollWidth>root.clientWidth+1) throw new Error('desktop horizontal overflow'); if(!document.querySelector('#source-revision')?.textContent) throw new Error('source revision missing'); if(!document.querySelector('#bundle-hash')?.textContent) throw new Error('bundle hash missing'); return 'desktop-contract-ok'; }" | Out-Null
  Invoke-PwCli eval "() => { const row=document.querySelector('#evidence-table-body tr'); if(!row) throw new Error('evidence table row missing'); row.click(); return 'row-clicked'; }" | Out-Null
  Invoke-PwCli eval "() => { if(document.querySelector('#selected-label')?.textContent==='None selected') throw new Error('table selection did not link evidence'); return 'linked-table-selection-ok'; }" | Out-Null
  Invoke-PwCli fill "#claim-input" "The evidence supports a bounded model review; it does not authorize individual decisions." | Out-Null
  Invoke-PwCli click "#save-claim" | Out-Null
  Invoke-PwCli click "#complete-activity" | Out-Null
  Invoke-PwCli eval "() => { if(!document.querySelector('#claim-status')?.textContent.includes('saved locally')) throw new Error('local claim state missing'); if(!document.querySelector('#rail-progress')?.textContent.startsWith('1 of 7')) throw new Error('activity completion did not persist'); return 'local-state-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-role-workflow-desktop.png" | Out-Null

  Invoke-PwCli click "button[data-view='plot2d']" | Out-Null
  Invoke-PwCli eval "() => { const canvas=document.querySelector('#evidence-canvas'); if(document.querySelector('#canvas-panel').hidden) throw new Error('2D canvas remains hidden'); if(!document.querySelector('#table-panel').hidden) throw new Error('table remains visible in 2D mode'); if(canvas.width!==900) throw new Error('canvas contract changed'); return 'plot2d-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-role-workflow-2d.png" | Out-Null
  Invoke-PwCli click "button[data-view='scene3d']" | Out-Null
  Invoke-PwCli eval "() => { if(!document.querySelector('#canvas-help')?.textContent.includes('rotate')) throw new Error('3D interaction guidance missing'); return 'scene3d-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-role-workflow-3d.png" | Out-Null

  Invoke-PwCli click "button[data-view='table']" | Out-Null
  Invoke-PwCli eval "() => { const row=document.querySelector('#evidence-table-body tr'); row.focus(); return document.activeElement===row?'row-focused':'row-focus-failed'; }" | Out-Null
  Invoke-PwCli press Enter | Out-Null
  Invoke-PwCli eval "() => { const row=document.querySelector('#evidence-table-body tr'); if(document.activeElement!==row) throw new Error('keyboard table path lost focus'); return 'keyboard-table-ok'; }" | Out-Null

  foreach ($size in @(@{Width=760;Height=900;Name='tablet'}, @{Width=390;Height=844;Name='mobile'})) {
    Invoke-PwCli resize $size.Width $size.Height | Out-Null
    Invoke-PwCli eval "() => { const root=document.documentElement; const shell=document.querySelector('.shell'); const claim=document.querySelector('#claim-input'); if(root.scrollWidth>root.clientWidth+1) throw new Error('responsive horizontal overflow: '+root.scrollWidth+' > '+root.clientWidth); if(shell.getBoundingClientRect().right>root.clientWidth+1) throw new Error('shell clipped'); if(claim.getBoundingClientRect().right>root.clientWidth+1) throw new Error('claim input clipped'); return 'responsive-ok'; }" | Out-Null
    Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-role-workflow-$($size.Name).png" --full-page | Out-Null
  }

  Invoke-PwCli resize 760 900 | Out-Null
  Invoke-PwCli eval "() => { document.documentElement.style.fontSize='200%'; const root=document.documentElement; if(root.scrollWidth>root.clientWidth+1) throw new Error('200-percent text horizontal overflow'); const buttons=[...document.querySelectorAll('button')]; if(buttons.some(button=>button.scrollWidth>button.clientWidth+2 && !button.closest('.activity-list'))) throw new Error('button label clipped at 200-percent text'); return 'text-zoom-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-role-workflow-text-zoom.png" --full-page | Out-Null

  Write-Output "R-ClaimLab role workflow browser smoke passed: desktop, table, 2D, 3D, keyboard, tablet, mobile, and 200-percent text."
} finally {
  try { Invoke-PwCli close | Out-Null } catch { }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
}
