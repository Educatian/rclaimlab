param(
  [string]$BaseUrl = "",
  [int]$ServerPort = 8773,
  [switch]$StartServer
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$lessonPath = "/examples/lesson/scene/index.html"
if (-not $BaseUrl) {
  $BaseUrl = "http://127.0.0.1:$ServerPort$lessonPath"
}
$npxName = if ($IsWindows) { "npx.cmd" } else { "npx" }
$pythonName = if ($IsWindows) { "python" } else { "python3" }
$npx = (Get-Command $npxName -ErrorAction Stop).Source
$session = "rclaimlab-browser-smoke"
$server = $null

function Invoke-PwCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
  & $npx --yes --package @playwright/cli playwright-cli "-s=$session" @Arguments
  if ($LASTEXITCODE -ne 0) { throw "playwright-cli failed: $($Arguments -join ' ')" }
}

try {
  if ($StartServer) {
    $serverArgs = @("-m", "http.server", "$ServerPort", "--bind", "127.0.0.1")
    $serverOptions = @{FilePath = $pythonName; ArgumentList = $serverArgs; WorkingDirectory = $root; PassThru = $true}
    if ($IsWindows) { $serverOptions.WindowStyle = "Hidden" }
    $server = Start-Process @serverOptions
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
  Invoke-PwCli snapshot | Out-Null
  Invoke-PwCli resize 390 844 | Out-Null
  Invoke-PwCli eval "() => { document.querySelector('#ai-tab').click(); return 'ai-tab-open'; }" | Out-Null
  Invoke-PwCli eval "(() => { const root = document.documentElement; if (root.scrollWidth > root.clientWidth + 1) throw new Error('mobile horizontal overflow: ' + root.scrollWidth + ' > ' + root.clientWidth); return 'mobile-width-ok'; })()" | Out-Null
  Invoke-PwCli fill "#ai-prompt" "Show the three-dimensional relationship between x, y, and z." | Out-Null
  Invoke-PwCli click "#generate-ai-brief" | Out-Null
  Invoke-PwCli run-code "async page => { await page.waitForFunction(() => { const card = document.querySelector('#ai-result-card'); return card && !card.hidden; }, null, { timeout: 15000 }); }" | Out-Null
  Invoke-PwCli eval "() => { const code = document.querySelector('#ai-generated-code').textContent; if (!code.includes('set.seed(2026)')) throw new Error('AI brief did not produce deterministic starter code'); return 'ai-brief-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-smoke-mobile.png" | Out-Null

  Invoke-PwCli eval "() => { document.querySelector('#scene-tab').click(); document.querySelector('#scene').focus(); return 'scene-focused'; }" | Out-Null
  Invoke-PwCli eval "() => { const table = document.querySelector('[data-representation=table]'); table.click(); if (table.getAttribute('aria-pressed') !== 'true') throw new Error('table representation did not activate'); if (!document.querySelector('#plot-shell').hidden) throw new Error('canvas remains visible in table mode'); if (!document.querySelector('#compiled-evidence-alternative').open) throw new Error('full Evidence IR table did not open'); return 'table-representation-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-smoke-table.png" | Out-Null
  Invoke-PwCli eval "() => { const plot = document.querySelector('[data-representation=plot2d]'); plot.click(); const canvas = document.querySelector('#scene'); if (plot.getAttribute('aria-pressed') !== 'true') throw new Error('2D representation did not activate'); if (document.querySelector('#plot-shell').hidden) throw new Error('2D canvas is hidden'); if (!canvas.getAttribute('aria-label').includes('two-dimensional')) throw new Error('2D accessible label missing'); canvas.focus(); return 'plot2d-representation-ok'; }" | Out-Null
  Invoke-PwCli press ArrowRight | Out-Null
  Invoke-PwCli eval "() => { const canvas = document.querySelector('#scene'); const selected = document.querySelector('#point-name')?.textContent || ''; if (document.activeElement !== canvas) throw new Error('2D canvas lost keyboard focus'); if (!selected || selected === 'point') throw new Error('2D keyboard selection did not link an observation'); return 'plot2d-selection-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-smoke-2d.png" | Out-Null
  Invoke-PwCli eval "() => { const scene3d = document.querySelector('[data-representation=scene3d]'); scene3d.click(); const canvas = document.querySelector('#scene'); if (scene3d.getAttribute('aria-pressed') !== 'true') throw new Error('3D representation did not reactivate'); canvas.focus(); return 'scene3d-focused'; }" | Out-Null
  Invoke-PwCli press ArrowUp | Out-Null
  Invoke-PwCli press Home | Out-Null
  Invoke-PwCli eval "() => { const canvas = document.querySelector('#scene'); if (document.activeElement !== canvas) throw new Error('3D canvas lost keyboard focus'); if (!document.querySelector('#points-table')) throw new Error('semantic points table missing'); return 'keyboard-and-table-ok'; }" | Out-Null
  Invoke-PwCli resize 1440 920 | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-smoke-desktop.png" | Out-Null
  $methodUrl = $BaseUrl -replace "/examples/lesson/scene/index.html$", "/examples/penguin-pca/scene/index.html"
  Invoke-PwCli run-code "async page => { await page.goto('$methodUrl', {waitUntil: 'domcontentloaded'}); }" | Out-Null
  $methodDiagnostics = Invoke-PwCli eval "() => JSON.stringify({question: document.querySelector('#lesson-question')?.textContent, criteria: [...document.querySelectorAll('#criteria-grid .criterion')].map(item => item.textContent), commands: document.querySelectorAll('#analysis-command-explanations li').length, diagnostics: document.querySelector('#method-diagnostics')?.innerText, source: document.querySelector('#source-analysis-code')?.innerText.slice(0, 160), width: [document.documentElement.scrollWidth, document.documentElement.clientWidth]})"
  Write-Output $methodDiagnostics
  Invoke-PwCli eval "() => { const question = document.querySelector('#lesson-question')?.textContent || ''; const diagnostics = document.querySelector('#method-diagnostics')?.textContent || ''; const criteriaText = document.querySelector('#criteria-grid')?.textContent || ''; const source = document.querySelector('#source-analysis-code')?.textContent || ''; const evidenceHead = document.querySelector('#compiled-evidence-head')?.textContent || ''; const criteria = document.querySelectorAll('#criteria-grid .criterion').length; const commands = document.querySelectorAll('#analysis-command-explanations li').length; if (!question.includes('Which morphology measurements vary together')) throw new Error('compiled PCA question missing'); if (!diagnostics.includes('Largest absolute PC1 loading')) throw new Error('PCA diagnostic missing'); if (!criteriaText.includes('Names a principal component')) throw new Error('PCA criterion missing'); if (!source.includes('complete.cases')) throw new Error('complete-case command missing'); if (!evidenceHead.includes('PC1') || document.querySelectorAll('#compiled-evidence-body tr').length < 3) throw new Error('full Evidence IR table missing'); if (criteria !== 4 || commands < 8) throw new Error('compiled method contract missing'); if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('method desktop overflow'); return 'method-contract-desktop-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-smoke-method-contract-desktop.png" | Out-Null
  Invoke-PwCli resize 390 844 | Out-Null
  Invoke-PwCli eval "() => { if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('method mobile overflow'); const grid = document.querySelector('#criteria-grid'); if (!grid || grid.getBoundingClientRect().right > document.documentElement.clientWidth + 1) throw new Error('method criteria overflow'); return 'method-contract-mobile-ok'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-smoke-method-contract-mobile.png" | Out-Null
  $kmeansUrl = $BaseUrl -replace "/examples/lesson/scene/index.html$", "/examples/edm-patterns/scene/index.html"
  Invoke-PwCli resize 1440 920 | Out-Null
  Invoke-PwCli run-code "async page => { await page.goto('$kmeansUrl', {waitUntil: 'domcontentloaded'}); }" | Out-Null
  Invoke-PwCli eval "() => { const header = document.querySelector('#compiled-evidence-head')?.textContent || ''; const diagnostics = document.querySelector('#method-diagnostics')?.textContent || ''; const criteria = document.querySelector('#criteria-grid')?.textContent || ''; if (!header.includes('cluster') || !header.includes('distance_to_centroid')) throw new Error('k-means evidence columns missing'); if (!diagnostics.includes('Sensitivity across k and seeds')) throw new Error('k-means stability diagnostic missing'); if (!criteria.includes('centroid distance')) throw new Error('k-means criterion missing'); return 'kmeans-contract-ok'; }" | Out-Null
  Invoke-PwCli eval "() => { const details = document.querySelector('#compiled-evidence-alternative'); details.open = true; details.scrollIntoView({block: 'start'}); return 'full-evidence-table-open'; }" | Out-Null
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-smoke-kmeans-contract-desktop.png" | Out-Null

  $rootUrl = $BaseUrl -replace "/examples/lesson/scene/index.html$", ""
  $foundationalCases = @(
    @{Path = "statistics-distribution"; Engine = "numeric_summary"},
    @{Path = "statistics-association"; Engine = "cor.test"},
    @{Path = "statistics-bootstrap"; Engine = "bootstrap_mean"},
    @{Path = "statistics-groups"; Engine = "aov"},
    @{Path = "statistics-categories"; Engine = "chisq.test"}
  )
  foreach ($case in $foundationalCases) {
    $url = "$rootUrl/examples/$($case.Path)/scene/index.html"
    Invoke-PwCli run-code "async page => { await page.goto('$url', {waitUntil: 'domcontentloaded'}); }" | Out-Null
    Invoke-PwCli eval "() => { const engine = document.querySelector('#method-name')?.textContent || ''; const source = document.querySelector('#source-analysis-code')?.textContent || ''; const plot = document.querySelector('[data-representation=plot2d]'); if (engine !== '$($case.Engine)') throw new Error('unexpected adapter: ' + engine); if (!source.includes('set.seed(2026)')) throw new Error('deterministic source missing'); plot.click(); if (plot.getAttribute('aria-pressed') !== 'true' || document.querySelector('#plot-shell').hidden) throw new Error('2D representation unavailable'); if (document.documentElement.scrollWidth > document.documentElement.clientWidth + 1) throw new Error('foundational lesson overflow'); return '$($case.Path)-ok'; }" | Out-Null
  }
  Invoke-PwCli screenshot --filename="output/playwright/rclaimlab-browser-smoke-foundational-categories.png" | Out-Null
  Write-Output "R-ClaimLab browser smoke test passed: responsive layout, AI brief, linked table/2D/3D representations, keyboard controls, and semantic evidence."
} finally {
  try { Invoke-PwCli close | Out-Null } catch { }
  if ($server) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue }
}
