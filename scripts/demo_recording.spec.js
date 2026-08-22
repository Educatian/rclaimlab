const { test, expect, chromium } = require("@playwright/test");
const fs = require("fs");
const path = require("path");

test("record the R-ClaimLab evidence workflow", async () => {
  test.setTimeout(240000);
  const root = path.resolve(__dirname, "..");
  const output = path.join(root, "output", "demo", "rclaimlab-interaction-raw.webm");
  const videoDir = path.join(root, "tmp", "playwright-demo-video");
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.mkdirSync(videoDir, { recursive: true });

  const baseUrl = process.env.RCLAIMLAB_DEMO_URL || "http://127.0.0.1:8782";
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    recordVideo: { dir: videoDir, size: { width: 1440, height: 900 } },
    reducedMotion: "no-preference"
  });
  const page = await context.newPage();
  const video = page.video();

  await page.goto(`${baseUrl}/examples/lesson/scene/index.html`, { waitUntil: "domcontentloaded" });
  await page.click("#restart-lesson");
  await page.waitForTimeout(4000);

  await page.fill("#orient-input", "One row represents one observation, the label identifies it, and x, y, and z coordinates locate it in the data space.");
  await page.click("#save-orient");
  await page.waitForFunction(() => document.querySelector("#orient-card").dataset.state === "saved");
  await page.waitForTimeout(2500);
  await page.fill("#prediction-input", "Positive x values will remain after the R filter.");
  await page.click("#save-prediction");
  await page.waitForFunction(() => !document.querySelector("#r-panel").hidden);
  await page.waitForTimeout(3500);

  await page.click("#run-r-code");
  await page.waitForFunction(() => {
    const ribbon = document.querySelector("#provenance-ribbon");
    return ribbon && !ribbon.hidden && document.querySelector("#check-sync").textContent.includes("PASS");
  }, null, { timeout: 30000 });
  await page.waitForTimeout(5000);

  await page.click("#scene-tab");
  await page.locator("[data-representation='scene3d']").click();
  const canvas = page.locator("#scene");
  await canvas.scrollIntoViewIfNeeded();
  const box = await canvas.boundingBox();
  if (box) {
    await page.mouse.move(box.x + box.width * 0.35, box.y + box.height * 0.45);
    await page.mouse.down();
    await page.mouse.move(box.x + box.width * 0.68, box.y + box.height * 0.34, { steps: 24 });
    await page.mouse.up();
  }
  await canvas.focus();
  await page.keyboard.press("ArrowRight");
  await page.keyboard.press("ArrowUp");
  await page.waitForTimeout(3500);
  await page.locator("[data-representation='table']").click();
  await page.waitForTimeout(2500);
  const firstPoint = page.locator("#points-table button.inspect-button").first();
  await firstPoint.click();
  await page.waitForTimeout(2500);
  await page.locator("[data-representation='plot2d']").click();
  await page.waitForTimeout(2500);

  await page.fill("#explanation-input", "Point inspect has a negative x value, and one point does not prove a general pattern.");
  await page.click("#check-explanation");
  await page.waitForFunction(() => !document.querySelector("#transfer-card").hidden && document.querySelector("#explanation-feedback").dataset.state === "success");
  await page.waitForTimeout(3500);
  await page.evaluate(() => {
    const buttons = [...document.querySelectorAll("#points-table button.inspect-button")];
    const secondPoint = buttons[1];
    if (!secondPoint) throw new Error("A transfer observation was not available.");
    secondPoint.click();
  });
  await page.fill("#transfer-input", "Compared with inspect, point clean has a higher x value. This descriptive comparison may not generalize.");
  await page.click("#check-transfer");
  await page.waitForFunction(() => !document.querySelector("#reproduce-card").hidden && document.querySelector("#transfer-feedback").dataset.state === "success");
  await page.waitForTimeout(2500);
  await page.click("#complete-lesson");
  await expect(page.locator("#lesson-status-text")).toHaveText("Lesson complete");
  await page.waitForTimeout(4500);

  await page.goto(`${baseUrl}/examples/penguin-pca/scene/index.html`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(4500);
  await page.locator("[data-representation='table']").click();
  await page.waitForTimeout(3000);
  await page.locator("[data-representation='scene3d']").click();
  await page.waitForTimeout(2500);
  await page.click("#r-tab");
  await page.waitForTimeout(4000);

  await page.goto(`${baseUrl}/examples/index.html`, { waitUntil: "domcontentloaded" });
  await page.waitForTimeout(6500);

  await context.close();
  await video.saveAs(output);
  await browser.close();
  expect(fs.statSync(output).size).toBeGreaterThan(100000);
});
