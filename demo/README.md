# R-ClaimLab — From R Code to Evidence: demo video production

The grant demo combines a verified direct-interaction browser recording, a Higgsfield narration track, and English captions. The caption-only version remains available as an accessibility and review fallback.

## Build

From the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build_demo_video.ps1
```

Required local dependency: FFmpeg with the `subtitles` filter.

Outputs:

- `output/demo/rclaimlab-demo-higgsfield-en.mp4`
- `output/demo/rclaimlab-demo-captioned-preview.mp4` when built with `-CaptionedPreview`
- `output/demo/rclaimlab-interaction-raw.webm`
- `output/demo/rclaimlab-demo-en.srt`
- `output/demo/rclaimlab-narration-higgsfield-en.mp3`
- `output/demo/rclaimlab-higgsfield-generation.json`

The English narration is AI-generated through Higgsfield using the `Ainsley` preset voice and the Seed Speech variant of `text2speech_v2`. The provenance JSON records the generation job, credit cost, timing, and SHA-256 hashes. `scripts/generate_narration_elevenlabs.ps1` is retained only as an optional alternative provider path.

The direct-interaction recording must visibly include prediction entry, real R execution in WebR, four passing reproducibility checks, a changed scene row count, 3D keyboard interaction, the semantic table path, evidence-based explanation feedback, and lesson completion.
