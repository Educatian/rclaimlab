# R-ClaimLab — From R Code to Evidence: demo video production

The grant demo combines a verified direct-interaction browser recording, an ElevenLabs narration track, and English captions. The older screenshot sequence remains as a fallback and visual storyboard reference.

## Build

From the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_demo_video.ps1
```

Required local dependency: FFmpeg with the `subtitles` filter.

Outputs:

- `output/demo/rclaimlab-demo-en.mp4`
- `output/demo/rclaimlab-demo-captioned-preview.mp4` when built with `-CaptionedPreview`
- `output/demo/rclaimlab-interaction-raw.webm`
- `output/demo/rclaimlab-demo-en.srt`
- `output/demo/rclaimlab-narration-en.mp3`

The narration is AI-generated with ElevenLabs using the American voice `Matilda — Knowledgeable, Professional` and the `eleven_multilingual_v2` model. If the connected ElevenLabs account has insufficient credits, build the truthful caption-only review artifact with `-CaptionedPreview`; do not publish an older narration under the current brand.

The direct-interaction recording must visibly include prediction entry, real R execution in WebR, four passing reproducibility checks, a changed scene row count, 3D keyboard interaction, the semantic table path, evidence-based explanation feedback, and lesson completion.
