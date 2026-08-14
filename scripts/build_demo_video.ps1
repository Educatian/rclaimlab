param(
  [string]$Ffmpeg = "ffmpeg",
  [string]$Ffprobe = "ffprobe"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$demoOutput = Join-Path $projectRoot "output\demo"
$captionSource = Join-Path $projectRoot "demo\subtitles-en.srt"
$captionOutput = Join-Path $demoOutput "rlearnxr-demo-en.srt"
$narration = Join-Path $demoOutput "rlearnxr-narration-en.mp3"
$referenceRecording = Join-Path $demoOutput "rlearnxr-interaction-raw.webm"
$penguinRecording = Join-Path $demoOutput "rlearnxr-penguin-interaction-raw.webm"
$finalVideo = Join-Path $demoOutput "rlearnxr-demo-en.mp4"
$temporaryVideo = Join-Path $demoOutput "rlearnxr-demo-en.tmp.mp4"

$required = @($captionSource, $narration, $referenceRecording, $penguinRecording)
foreach ($path in $required) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Required demo input is missing: $path"
  }
}

Copy-Item -LiteralPath $captionSource -Destination $captionOutput -Force

# These cuts align verified browser interactions with the existing 103-second
# English ElevenLabs narration and caption timing.
$filter = @"
[0:v]trim=start=0:end=18,setpts=0.944444444*(PTS-STARTPTS)[v0];
[0:v]trim=start=70:end=100,setpts=0.600000000*(PTS-STARTPTS)[v1];
[0:v]trim=start=102:end=114,setpts=0.750000000*(PTS-STARTPTS)[v2];
[0:v]trim=start=114:end=133,setpts=1.052631579*(PTS-STARTPTS)[v3];
[0:v]trim=start=20:end=65,setpts=0.177777778*(PTS-STARTPTS)[v4];
[1:v]trim=start=0:end=28.52,setpts=0.631136045*(PTS-STARTPTS)[v5];
[0:v]trim=start=133:end=151.4,setpts=0.714293478*(PTS-STARTPTS)[v6];
[v0][v1][v2][v3][v4][v5][v6]concat=n=7:v=1:a=0,
scale=1440:1080:force_original_aspect_ratio=decrease,
pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x111827,
subtitles='demo/subtitles-en.srt':force_style='FontName=Arial,FontSize=10,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=1.5,Shadow=0,MarginV=22,Alignment=2',
format=yuv420p[vout]
"@
$filter = ($filter -replace "`r?`n", "")

Push-Location $projectRoot
try {
  & $Ffmpeg -hide_banner -loglevel error -y `
    -i $referenceRecording -i $penguinRecording -i $narration `
    -filter_complex $filter -map "[vout]" -map "2:a:0" `
    -af "loudnorm=I=-16:TP=-1.5:LRA=11" -r 30 `
    -c:v libx264 -preset medium -crf 20 `
    -c:a aac -b:a 192k -shortest -movflags +faststart `
    -metadata title="R-LearnXR Direct Interaction Grant Demo" `
    -metadata comment="AI-generated narration by ElevenLabs; English captions included." `
    $temporaryVideo
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

Get-Item -LiteralPath $finalVideo, $captionOutput, $narration | Select-Object FullName, Length
