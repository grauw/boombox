import fs from "fs";
import PNG from "png-js";

async function generate() {
	generateReels("../res/reels.png", "../gen/reels.bin");
}

async function generateReels(inputPath, outputPath) {
	const png = new PNG(await fs.promises.readFile(inputPath));
	if (png.colorType != 3)
		throw new Error("Not indexed RGB.");
	const pngPixels = await new Promise(resolve => png.decodePixels(resolve));

	const spriteData = [];
	for (let index = 0; index < 16; index++) {
		for (let sprite = 0; sprite < 4; sprite++) {
			for (let char = 0; char < 4; char++) {
				for (let line = 0; line < 8; line++) {
					let accu = 0;
					for (let bit = 0; bit < 8; bit++) {
						const x = index * 32 + (sprite & 1) * 16 + ((char >> 1) & 1) * 8 + bit;
						const y = ((sprite >> 1) & 1) * 16 + (char & 1) * 8 + line;
						const pixel = pngPixels[y * png.width + x];
						accu = (accu << 1) | (pixel > 1 ? 1 : 0);
					}
					spriteData.push(accu);
				}
			}
		}
	}

	await fs.promises.writeFile(outputPath, new Uint8Array(spriteData));
}

await generate();
