param(
  [string]$Ffmpeg = "ffmpeg",
  [string]$Ffprobe = "ffprobe",
  [switch]$CaptionedPreview
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$demoOutput = Join-Path $projectRoot "output\demo"
$captionSource = Join-Path $projectRoot "demo\subtitles-en.srt"
$captionOutput = Join-Path $demoOutput "rclaimlab-demo-en.srt"
$narration = Join-Path $demoOutput "rclaimlab-narration-en.mp3"
$referenceRecording = Join-Path $demoOutput "rclaimlab-interaction-raw.webm"
$finalName = if ($CaptionedPreview) { "rclaimlab-demo-captioned-preview.mp4" } else { "rclaimlab-demo-en.mp4" }
$finalVideo = Join-Path $demoOutput $finalName
$temporaryVideo = Join-Path $demoOutput ($finalName -replace '\.mp4$', '.tmp.mp4')

$required = @($captionSource, $referenceRecording)
if (-not $CaptionedPreview) { $required += $narration }
foreach ($path in $required) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Required demo input is missing: $path"
  }
}

Copy-Item -LiteralPath $captionSource -Destination $captionOutput -Force

$targetDuration = 103.14
$rawDurationText = & $Ffprobe -v error -show_entries "format=duration" -of "default=noprint_wrappers=1:nokey=1" $referenceRecording
if ($LASTEXITCODE -ne 0) { throw "FFprobe could not read the interaction recording." }
$rawDuration = [double]::Parse($rawDurationText.Trim(), [Globalization.CultureInfo]::InvariantCulture)
$ratio = ($targetDuration / $rawDuration).ToString("0.000000", [Globalization.CultureInfo]::InvariantCulture)
$filter = @"
[0:v]setpts=$ratio*(PTS-STARTPTS),
scale=1440:1080:force_original_aspect_ratio=decrease,
pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x111827,
subtitles='demo/subtitles-en.srt':force_style='FontName=Arial,FontSize=10,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=1.5,Shadow=0,MarginV=22,Alignment=2',
format=yuv420p[vout]
"@
$filter = ($filter -replace "`r?`n", "")

Push-Location $projectRoot
try {
  if ($CaptionedPreview) {
    & $Ffmpeg -hide_banner -loglevel error -y -i $referenceRecording `
      -filter_complex $filter -map "[vout]" -r 30 -t $targetDuration `
      -c:v libx264 -preset medium -crf 20 -movflags +faststart `
      -metadata title="R-ClaimLab Captioned Direct Interaction Preview" `
      -metadata comment="English captions included; narration pending a fresh ElevenLabs render." `
      $temporaryVideo
  } else {
    & $Ffmpeg -hide_banner -loglevel error -y -i $referenceRecording -i $narration `
      -filter_complex $filter -map "[vout]" -map "1:a:0" `
      -af "loudnorm=I=-16:TP=-1.5:LRA=11,apad" -r 30 -t $targetDuration `
      -c:v libx264 -preset medium -crf 20 `
      -c:a aac -b:a 192k -movflags +faststart `
      -metadata title="R-ClaimLab Direct Interaction Grant Demo" `
      -metadata comment="AI-generated narration by ElevenLabs; English captions included." `
      $temporaryVideo
  }
  if ($LASTEXITCODE -ne 0) { throw "FFmpeg failed while composing the interaction demo." }

  Move-Item -LiteralPath $temporaryVideo -Destination $finalVideo -Force
  & $Ffprobe -v error `
    -show_entries "format=duration,size:stream=codec_name,width,height,r_frame_rate" `
    -of "default=noprint_wrappers=1" $finalVideo
  if ($LASTEXITCODE -ne 0) { throw "FFprobe could not validate the final demo." }

  # Metadata alone can miss a damaged H.264 access unit. Decode the completed
  # file once before publishing it so a concurrent or partial write fails here.
  & $Ffmpeg -hide_banner -loglevel error -i $finalVideo -f null NUL
  if ($LASTEXITCODE -ne 0) { throw "FFmpeg could not decode the final demo." }
}
finally {
  Pop-Location
}

$outputs = @($finalVideo, $captionOutput)
if (-not $CaptionedPreview) { $outputs += $narration }
Get-Item -LiteralPath $outputs | Select-Object FullName, Length
