param(
  [string]$Ffmpeg = "ffmpeg"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$demoOutput = Join-Path $projectRoot "output\demo"
$partsDir = Join-Path $demoOutput ".video-parts"
$captionSource = Join-Path $projectRoot "demo\subtitles-en.srt"
$captionOutput = Join-Path $demoOutput "rlearnxr-demo-en.srt"
$narration = Join-Path $demoOutput "rlearnxr-narration-en.mp3"
$silentVideo = Join-Path $partsDir "silent-demo.mp4"
$finalVideo = Join-Path $demoOutput "rlearnxr-demo-en.mp4"

New-Item -ItemType Directory -Force -Path $partsDir | Out-Null
Copy-Item -LiteralPath $captionSource -Destination $captionOutput -Force

$scenes = @(
  @{ File = "01-predict.png"; Duration = 17.76 },
  @{ File = "02-explore.png"; Duration = 17.98 },
  @{ File = "03-evidence.png"; Duration = 20.30 },
  @{ File = "04-explain.png"; Duration = 16.72 },
  @{ File = "05-complete.png"; Duration = 16.60 },
  @{ File = "06-penguin-pca.png"; Duration = 13.79 }
)

$concatLines = New-Object System.Collections.Generic.List[string]
for ($index = 0; $index -lt $scenes.Count; $index++) {
  $scene = $scenes[$index]
  $input = Join-Path $demoOutput $scene.File
  $clip = Join-Path $partsDir ("scene-{0:D2}.mp4" -f ($index + 1))
  $frames = [Math]::Ceiling($scene.Duration * 30)
  $zoomDirection = if ($index % 2 -eq 0) { "min(zoom+0.00020,1.035)" } else { "min(zoom+0.00015,1.025)" }
  $filter = "scale=1920:-2,crop=1920:1080,zoompan=z='$zoomDirection':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=${frames}:s=1920x1080:fps=30,format=yuv420p"
  & $Ffmpeg -hide_banner -loglevel error -y -loop 1 -i $input -t $scene.Duration -vf $filter -an -c:v libx264 -preset medium -crf 19 -movflags +faststart $clip
  if ($LASTEXITCODE -ne 0) { throw "FFmpeg failed while creating $clip" }
  $concatLines.Add("file '$($clip.Replace("'", "''"))'")
}

$concatFile = Join-Path $partsDir "concat.txt"
[System.IO.File]::WriteAllLines($concatFile, $concatLines)
& $Ffmpeg -hide_banner -loglevel error -y -f concat -safe 0 -i $concatFile -c copy $silentVideo
if ($LASTEXITCODE -ne 0) { throw "FFmpeg failed while concatenating scene clips." }

Push-Location $projectRoot
try {
  $subtitleFilter = "subtitles='demo/subtitles-en.srt':force_style='FontName=Arial,FontSize=12,PrimaryColour=&H00FFFFFF,OutlineColour=&H00142133,BorderStyle=1,Outline=1,Shadow=0,MarginV=24,Alignment=2'"
  & $Ffmpeg -hide_banner -loglevel error -y -i $silentVideo -i $narration -vf $subtitleFilter -af "loudnorm=I=-16:TP=-1.5:LRA=11" -map 0:v:0 -map 1:a:0 -c:v libx264 -preset medium -crf 19 -c:a aac -b:a 192k -shortest -movflags +faststart -metadata title="R-LearnXR Grant Demo" -metadata comment="AI-generated narration by ElevenLabs; English captions included." $finalVideo
  if ($LASTEXITCODE -ne 0) { throw "FFmpeg failed while adding narration and captions." }
}
finally {
  Pop-Location
}

Get-Item -LiteralPath $finalVideo, $captionOutput, $narration | Select-Object FullName, Length
