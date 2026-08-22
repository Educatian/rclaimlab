param(
  [string]$EnvFile = "",
  [string]$VoiceName = "Matilda - Knowledgable, Professional",
  [string]$VoiceId = "XrExE9yKIg1WjnnlVkGX",
  [string]$ModelId = "eleven_multilingual_v2"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root "demo\narration-en.txt"
$output = Join-Path $root "output\demo\rclaimlab-narration-elevenlabs-en.mp3"
$apiKey = $env:ELEVENLABS_API_KEY

if (-not $apiKey -and $EnvFile) {
  $line = Get-Content -LiteralPath $EnvFile | Where-Object { $_ -match '^ELEVENLABS_API_KEY=' } | Select-Object -First 1
  if ($line) { $apiKey = ($line -split '=', 2)[1].Trim().Trim('"').Trim("'") }
}
if (-not $apiKey) { throw "Set ELEVENLABS_API_KEY or pass -EnvFile containing that variable." }

$headers = @{ "xi-api-key" = $apiKey }
if (-not $VoiceId) {
  $voiceResponse = Invoke-RestMethod -Uri "https://api.elevenlabs.io/v2/voices?page_size=100&voice_type=default" -Headers $headers -Method Get
  $voice = $voiceResponse.voices | Where-Object { $_.name -eq $VoiceName } | Select-Object -First 1
  if (-not $voice) { throw "ElevenLabs voice not found: $VoiceName" }
  if ($voice.labels.accent -notmatch '(?i)american') { throw "Selected voice is not labeled with an American accent." }
  $VoiceId = $voice.voice_id
}

$payload = @{
  text = [string](Get-Content -Raw -LiteralPath $source)
  model_id = $ModelId
  voice_settings = @{
    stability = 0.55
    similarity_boost = 0.78
    style = 0.15
    use_speaker_boost = $true
  }
} | ConvertTo-Json -Depth 5

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $output) | Out-Null
$uri = "https://api.elevenlabs.io/v1/text-to-speech/${VoiceId}?output_format=mp3_44100_128"
Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -ContentType "application/json" -Body $payload -OutFile $output
if ((Get-Item -LiteralPath $output).Length -lt 10000) { throw "Generated narration is unexpectedly small." }
Write-Output "Generated American-English ElevenLabs narration: $output"
