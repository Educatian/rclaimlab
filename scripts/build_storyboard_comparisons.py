from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "storyboard-v2"
CAPTURE = ROOT / "output" / "playwright"
OUTPUT = CAPTURE / "design-qa"

SCENES = [
    ("01", "01-start-with-purpose.png", "rclaimlab-storyboard-01-purpose.png"),
    ("02", "02-choose-data-source.png", "rclaimlab-storyboard-02-source.png"),
    ("03", "03-review-data-profile.png", "rclaimlab-storyboard-03-profile.png"),
    ("04", "04-approve-analysis-plan.png", "rclaimlab-storyboard-04-plan.png"),
    ("05", "05-choose-role-lens.png", "rclaimlab-storyboard-05-role.png"),
    ("06", "06-review-workflow-path.png", "rclaimlab-storyboard-06-review.png"),
    ("07", "07-focused-analysis-workspace.png", "rclaimlab-role-workflow-desktop.png"),
    ("08", "08-trace-evidence.png", "rclaimlab-storyboard-08-trace.png"),
    ("09", "09-build-defensible-claim.png", "rclaimlab-storyboard-09-claim.png"),
    ("10", "10-handoff-and-receipt.png", "rclaimlab-storyboard-10-handoff.png"),
]


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/segoeuib.ttf"),
        Path("C:/Windows/Fonts/arialbd.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(candidate, size=size)
    return ImageFont.load_default()


def panel(image_path: Path, size: tuple[int, int]) -> Image.Image:
    image = Image.open(image_path).convert("RGB")
    return ImageOps.pad(image, size, method=Image.Resampling.LANCZOS, color="#f6f8fc", centering=(0.5, 0.0))


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    title_font = font(28)
    label_font = font(20)
    for scene, source_name, capture_name in SCENES:
        canvas = Image.new("RGB", (3200, 1040), "#ffffff")
        draw = ImageDraw.Draw(canvas)
        draw.text((34, 22), f"SCENE {scene} / REFERENCE STORYBOARD", fill="#1757d7", font=title_font)
        draw.text((1634, 22), "IMPLEMENTED BROWSER STATE", fill="#13804b", font=title_font)
        canvas.paste(panel(SOURCE / source_name, (1532, 920)), (34, 86))
        canvas.paste(panel(CAPTURE / capture_name, (1532, 920)), (1634, 86))
        draw.line((1600, 18, 1600, 1020), fill="#dbe2ed", width=2)
        draw.text((34, 1010), source_name, fill="#5c6880", font=label_font)
        draw.text((1634, 1010), capture_name, fill="#5c6880", font=label_font)
        canvas.save(OUTPUT / f"scene-{scene}-comparison.jpg", quality=88, optimize=True, progressive=True)
    print(f"Created {len(SCENES)} comparison boards in {OUTPUT}")


if __name__ == "__main__":
    main()
