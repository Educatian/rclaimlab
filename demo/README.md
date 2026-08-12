# Demo video production

The grant demo combines a verified direct-interaction browser recording, an ElevenLabs narration track, and English captions. The older screenshot sequence remains as a fallback and visual storyboard reference.

## Build

From the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_demo_video.ps1
```

Required local dependency: FFmpeg with the `subtitles` filter.

Outputs:

- `output/demo/rlearnxr-demo-en.mp4`
- `output/demo/rlearnxr-interaction-raw.webm`
- `output/demo/rlearnxr-demo-en.srt`
- `output/demo/rlearnxr-narration-en.mp3`

The narration is AI-generated with ElevenLabs using the voice `Alice — Clear, Engaging Educator` and the `eleven_multilingual_v2` model.

The direct-interaction recording must visibly include prediction entry, real R execution in WebR, four passing reproducibility checks, a changed scene row count, 3D keyboard interaction, the semantic table path, evidence-based explanation feedback, and lesson completion.
