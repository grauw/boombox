import fs from "fs";
import path from "path";
import PNG from "png-js";
import lz4 from "lz4";

async function generate() {
	if (process.argv.length < 3) {
		console.log(`Usage: node ${process.argv[1]} resources.json`);
		process.exit(1);
	}

	const resources = await Resources.parse(process.argv[2]);
	await resources.generate();
}

class Resources {
	constructor(graphics, modules) {
		this.graphics = graphics;
		this.modules = modules;
	}

	async generate() {
		await Promise.all([
			this.graphics.generate(),
			...this.modules.map(module => module.generate())
		]);
	}

	static async parse(resourcesPath) {
		const json = JSON.parse(await fs.promises.readFile(resourcesPath));

		return new Resources(
			new Graphics(
				path.resolve(path.dirname(resourcesPath), json.graphics.reels),
				path.resolve(path.dirname(resourcesPath), json.graphics.target)
			),
			json.modules.map(jsonModule => {
				return new Module(
					path.resolve(path.dirname(resourcesPath), jsonModule.source),
					path.resolve(path.dirname(resourcesPath), jsonModule.target)
				)
			})
		);
	}
}

class Graphics {
	constructor(reels, target) {
		this.reels = reels;
		this.target = target;
	}

	async generate() {
		const graphics = new Uint8Array(0x4000);

		await this.generateReels(graphics);

		await fs.promises.writeFile(this.target, compress(graphics));
	}

	async generateReels(graphics) {
		const png = new PNG(await fs.promises.readFile(this.reels));
		if (png.colorType != 3)
			throw new Error("Not indexed RGB.");
		const pngPixels = await new Promise(resolve => png.decodePixels(resolve));

		let spritePatternAddress = 0x3800;
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
						graphics[spritePatternAddress++] = accu;
					}
				}
			}
		}

		graphics[0x1800] = 208;  // hide sprites
	}
}

class Module {
	constructor(source, target) {
		this.source = source;
		this.target = target;
	}

	async generate() {
		let data = await fs.promises.readFile(this.source);

		if (data[0] == 0x21 && data[1] == 0xB3 && data[2] == 0x84) {
			data = data.subarray(0x4B3);
		}

		if (data[0x0A] != 0x45 || data[0x0B] != 0x54 || data[0x0C] != 0x72 || data[0x0D] != 0x61 ||
			data[0x0E] != 0x63 || data[0x0F] != 0x6B || data[0x10] != 0x65 || data[0x11] != 0x72) {
			throw new Error("Not an ETracker file");
		} else {
			data.fill(0, 0x0A, 0x1E);  // Clear ETracker signature
		}

		await fs.promises.writeFile(this.target, compress(data));
	}
}

function compress(input) {
	if (input.length > 65536) {
		throw new Error("Input size exceeds 64K.");
	}
	const output = new Uint8Array(lz4.encodeBound(input.length) + 4);
	const compressedSize = lz4.encodeBlockHC(input, output.subarray(4));
	output[0] = compressedSize & 0xFF;
	output[1] = compressedSize >> 8;
	output[2] = input.length & 0xFF;
	output[3] = input.length >> 8;
	return output.subarray(0, compressedSize + 4);
}

await generate();
