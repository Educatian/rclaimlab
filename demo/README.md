# Demo video production

The English demo uses six verified browser screenshots, an ElevenLabs narration track, and English captions.

## Build

From the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_demo_video.ps1
```

Required local dependency: FFmpeg with the `subtitles` filter.

Outputs:

- `output/demo/rlearnxr-demo-en.mp4`
- `output/demo/rlearnxr-demo-en.srt`
- `output/demo/rlearnxr-narration-en.mp3`

The narration is AI-generated with ElevenLabs using the voice `Alice — Clear, Engaging Educator` and the `eleven_multilingual_v2` model.

