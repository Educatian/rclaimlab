param([string]$BaseUrl = 'https://rclaimlab-review.pages.dev', [switch]$LegacyRedirect)
$ErrorActionPreference = 'Stop'
$handler = [System.Net.Http.HttpClientHandler]::new()
$handler.AllowAutoRedirect = $false
$client = [System.Net.Http.HttpClient]::new($handler)
$client.Timeout = [TimeSpan]::FromSeconds(30)
try {
    $root = $client.GetAsync("$BaseUrl/").GetAwaiter().GetResult()
    if ($LegacyRedirect) {
        if ([int]$root.StatusCode -ne 302 -or [string]$root.Headers.Location -ne '/app/') { throw 'Legacy root redirect failed.' }
    } else {
        $rootHtml = $root.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if ([int]$root.StatusCode -ne 200 -or $rootHtml -notmatch 'Choose your mode') { throw 'Root mode hub is missing.' }
        $releaseResponse = $client.GetAsync("$BaseUrl/release-manifest.json").GetAwaiter().GetResult()
        if ([int]$releaseResponse.StatusCode -ne 200) { throw 'Release manifest missing.' }
        $release = $releaseResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json
        if ($release.git_commit -notmatch '^[a-f0-9]{40}$' -or $rootHtml -notmatch $release.git_commit) { throw 'Immutable install reference mismatch.' }
        if ($release.runtime.remote_r -or $release.runtime.uploads -or $release.runtime.telemetry) { throw 'Unexpected hosted runtime claim.' }
        foreach ($mode in @('guided', 'analyst', 'scientist', 'reviewer')) {
            foreach ($resource in @('app/', 'report/', 'analysis/workflow.R', 'workflow-spec.json')) {
                $path = "/modes/$mode/$resource"
                $modeResponse = $client.GetAsync($BaseUrl + $path).GetAwaiter().GetResult()
                if ([int]$modeResponse.StatusCode -ne 200) { throw "Missing mode artifact: $path" }
                $relative = "modes/$mode/$resource"
                if ($relative.EndsWith('/')) { $relative += 'index.html' }
                $bytes = $modeResponse.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
                $md5 = [System.Security.Cryptography.MD5]::Create()
                try { $actual = ([BitConverter]::ToString($md5.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant() } finally { $md5.Dispose() }
                if ($actual -ne $release.files.$relative) { throw "Release checksum mismatch: $relative" }
                if ($resource -eq 'analysis/workflow.R' -and [Text.Encoding]::UTF8.GetString($bytes) -notmatch 'reproduce_workflow <- function') { throw "Incomplete R export: $mode" }
                if ($resource -eq 'app/' -and $modeResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult() -notmatch 'Change mode') { throw "Missing mode navigation: $mode" }
                if ($resource -eq 'app/') {
                    $html = $modeResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                    foreach ($marker in @('role-purpose', 'activity-action-help', 'Shared workspace tools', 'task-note', 'RCLAIMLAB_PRESENTATION')) {
                        if ($html -notmatch $marker) { throw "Missing role-aware UI marker $marker in $mode" }
                    }
                }
            }
            Write-Output "PASS $mode app, report, R source and specification"
        }
    }
    foreach ($path in @('/app/', '/report/', '/analysis/workflow.R', '/evidence/index.json')) {
        $response = $client.GetAsync($BaseUrl + $path).GetAwaiter().GetResult()
        if ([int]$response.StatusCode -ne 200) { throw "Failed public asset: $path" }
        Write-Output "PASS 200 $path"
    }
    $missing = $client.GetAsync("$BaseUrl/root-repair-missing-resource").GetAwaiter().GetResult()
    if ([int]$missing.StatusCode -ne 404) { throw 'Missing assets must return a real 404.' }
    Write-Output 'PASS root entry; unknown resource 404.'
} finally {
    $client.Dispose()
    $handler.Dispose()
}
