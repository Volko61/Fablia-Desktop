// Generates every icon the packagers need from build/icon.png (1024x1024).
import sharp from "sharp";
import { mkdirSync } from "node:fs";

const src = "build/icon.png";
const bg = { r: 0, g: 32, b: 31, alpha: 1 }; // #00201f, the logo background
mkdirSync("build/appx", { recursive: true });

// Windows Store tiles (electron-builder picks these up from build/appx).
const square = { StoreLogo: 50, Square44x44Logo: 44, Square150x150Logo: 150 };
for (const [name, size] of Object.entries(square)) {
  await sharp(src).resize(size, size).toFile(`build/appx/${name}.png`);
}
// Wide tile: logo centred on the brand background.
const logo = await sharp(src).resize(150, 150).toBuffer();
await sharp({ create: { width: 310, height: 150, channels: 4, background: bg } })
  .composite([{ input: logo, gravity: "center" }])
  .toFile("build/appx/Wide310x150Logo.png");
