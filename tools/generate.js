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
				json.graphics.boomboxFrames.map(frame => path.resolve(path.dirname(resourcesPath), frame)),
				path.resolve(path.dirname(resourcesPath), json.graphics.reels),
				path.resolve(path.dirname(resourcesPath), json.graphics.target),
				path.resolve(path.dirname(resourcesPath), json.graphics.playlistTarget)
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
	constructor(boomboxFrames, reels, target, playlistTarget) {
		this.boomboxFrames = boomboxFrames.map(frame => new Image(frame));
		this.reels = new Image(reels);
		this.target = target;
		this.playlistTarget = playlistTarget;
	}

	async generate() {
		const graphics = new Screen2();

		await this.generateReels(graphics);
		const playlistGraphics = await this.generateBoombox(graphics);
		await this.generateControls(graphics);
		await this.generateVUMeters(graphics);

		// patch the dark red to look nicer on MSX2
		graphics.setPaletteColor(6, [5, 2, 2]);

		await fs.promises.writeFile(this.target, compress(graphics.vram));
		await fs.promises.writeFile(this.playlistTarget, compress(playlistGraphics));
	}

	async generateReels(graphics) {
		await this.reels.load();

		for (let index = 0; index < 16; index++) {
			for (let sprite = 0; sprite < 4; sprite++) {
				for (let char = 0; char < 4; char++) {
					const pattern = this.reels.getSpritePattern(8,
						index * 32 + (sprite & 1) * 16 + ((char >> 1) & 1) * 8,
						((sprite >> 1) & 1) * 16 + (char & 1) * 8
					);
					graphics.setSpritePattern(index * 16 + sprite * 4 + char, pattern);
				}
			}
		}

		graphics.setSpriteAttribute(0, 208);  // hide sprites
	}

	async generateBoombox(graphics) {
		await Promise.all(this.boomboxFrames.map(frame => frame.load()));

		const graphicsFrames = [graphics];
		for (let frame = 1; frame < this.boomboxFrames.length; frame++) {
			graphicsFrames.push(new Screen2());
		}

		const patterns = [[], [], []];
		for (let frame = 0; frame < this.boomboxFrames.length; frame++) {
			const boombox = this.boomboxFrames[frame];

			for (let table = 0; table < 3; table++) {
				for (let tile = 0; tile < 256; tile++) {
					const [pattern, color] = boombox.getPattern((tile & 31) * 8, table * 64 + (tile >> 5) * 8);
					const hash = [...pattern, ...color].reduce((accu, value) => accu << 8n | BigInt(value), 0n);
					let patternIndex = patterns[table].indexOf(hash);
					if (patternIndex == -1) {
						patternIndex = patterns[table].length;
						graphicsFrames[0].setPattern(table, patternIndex, pattern);
						graphicsFrames[0].setPatternColor(table, patternIndex, color);
						patterns[table].push(hash);
					}
					graphicsFrames[frame].setName(table, tile, patternIndex);
				}
			}
		}

		for (let color = 0; color < 16; color++) {
			const boombox = this.boomboxFrames[0];
			graphicsFrames[0].setPaletteColor(color, boombox.getColor(color));
		}

		const offset = 0x1800 + 14 * 32;
		const length = 3 * 32;
		const playlistGraphics = new Uint8Array((this.boomboxFrames.length - 1) * length);
		for (let frame = 1; frame < this.boomboxFrames.length; frame++) {
			const data = graphicsFrames[frame].vram.subarray(offset, offset + length);
			playlistGraphics.set(data, (frame - 1) * length);
		}
		return playlistGraphics;
	}

	async generateControls(graphics) {
		const patterns = [
			[0x60, 0x70, 0x78, 0x7C, 0x78, 0x70, 0x60, 0x00],
			[0x0C, 0x1C, 0x3C, 0x7C, 0x3C, 0x1C, 0x0C, 0x00],
			[0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x00],
			[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
		];
		for (let table = 1; table < 3; table++) {
			for (let pattern = 0; pattern < patterns.length; pattern++) {
				graphics.setPattern(table, 0xFC + pattern, patterns[pattern]);
				graphics.setPatternColor(table, 0xFC + pattern, [0x1F, 0x1F, 0x1F, 0x1F, 0x1F, 0x1F, 0x1F, 0x1F]);
			}
		}
	}

	async generateVUMeters(graphics) {
		const L = 0x3E, R = 0xF8;
		graphics.setPattern(1, 0xF3, [0, 0, 0, 0, 0, 0, 0, 0]);
		graphics.setPatternColor(1, 0xF3, [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11]);
		for (let i = 0; i < 4; i++) {
			graphics.setPattern(1, 0xF4 + i, [i >= 3 ? L : 0, 0, i >= 2 ? L : 0, 0, i >= 1 ? L : 0, 0, L, 0]);
			graphics.setPatternColor(1, 0xF4 + i, [0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31]);
			graphics.setPattern(1, 0xF8 + i, [i >= 3 ? R : 0, 0, i >= 2 ? R : 0, 0, i >= 1 ? R : 0, 0, R, 0]);
			graphics.setPatternColor(1, 0xF8 + i, [0xA1, 0xA1, 0xA1, 0xA1, 0xA1, 0xA1, 0xA1, 0xA1]);
		}
	}
}

class Screen2 {
	constructor() {
		this.vram = new Uint8Array(0x4000);
	}

	setName(table = 0, index = 0, pattern = 0) {
		if (table < 0 || table >= 3 || index < 0 || index >= 256 || pattern < 0 || pattern >= 256)
			throw new Error("Invalid parameters.");
		this.vram[0x1800 + table * 0x100 + index] = pattern;
	}

	setPattern(table = 0, index = 0, pattern = [0, 0, 0, 0, 0, 0, 0, 0]) {
		if (table < 0 || table >= 3 || index < 0 || index >= 256 || pattern.length != 8)
			throw new Error("Invalid parameters.");
		this.vram.set(pattern, 0x0000 + table * 0x800 + index * 8);
	}

	setPatternColor(table = 0, index = 0, color = [0, 0, 0, 0, 0, 0, 0, 0]) {
		if (table < 0 || table >= 3 || index < 0 || index >= 256 || color.length != 8)
			throw new Error("Invalid parameters.");
		this.vram.set(color, 0x2000 + table * 0x800 + index * 8);
	}

	setSpriteAttribute(index = 0, y = 0, x = 0, pattern = 0, color = 0) {
		if (index < 0 || index >= 256 || pattern < 0 || pattern >= 256)
			throw new Error("Invalid parameters.");
		this.vram.set([y, x, pattern, color], 0x1B00 + index * 4);
	}

	setSpritePattern(index = 0, pattern = [0, 0, 0, 0, 0, 0, 0, 0]) {
		if (index < 0 || index >= 256 || pattern.length != 8)
			throw new Error("Invalid parameters.");
		this.vram.set(pattern, 0x3800 + index * 8);
	}

	setPaletteColor(index = 0, rgb = [0, 0, 0]) {
		if (index < 0 || index >= 16 || rgb.length != 3)
			throw new Error("Invalid parameters.");
		this.vram[0x1B80 + index * 2 + 0] = rgb[0] << 4 | rgb[2];
		this.vram[0x1B80 + index * 2 + 1] = rgb[1];
	}
}

class Image {
	constructor(path) {
		this.path = path;
		this.pixels = [];
		this.palette = [];
	}

	async load() {
		const png = new PNG(await fs.promises.readFile(this.path));
		if (png.colorType != 3)
			throw new Error("Not indexed RGB.");
		const pixels = await new Promise(resolve => png.decodePixels(resolve));

		this.pixels = [];
		for (let y = 0; y < png.height; y++) {
			this.pixels.push(pixels.subarray(y * png.width, (y + 1) * png.width));
		}

		this.palette = [];
		for (let color = 0; color < 16; color++) {
			this.palette.push(png.palette.slice(color * 3 + 0, color * 3 + 3).map(
				component => Math.pow(component / 255, 2.2 / 1)));
		}
	}

	getSpritePattern(color, x, y) {
		const pattern = [0, 0, 0, 0, 0, 0, 0, 0];
		for (let line = 0; line < 8; line++) {
			for (let bit = 0; bit < 8; bit++) {
				const pixel = this.pixels[y + line][x + bit] & 15;
				pattern[line] = (pattern[line] << 1) | (pixel == color ? 1 : 0);
			}
		}
		return pattern;
	}

	getPattern(x, y) {
		const pattern = [0, 0, 0, 0, 0, 0, 0, 0];
		const color = [0, 0, 0, 0, 0, 0, 0, 0];
		for (let line = 0; line < 8; line++) {
			let color1 = -1;
			let color1Count = 0;
			let color2 = -1;
			let color2Count = 0;
			for (let bit = 0; bit < 8; bit++) {
				const pixel = this.pixels[y + line][x + bit] & 15;
				if (color1Count == 0 || color1 == pixel) {
					color1 = pixel;
					color1Count++;
				} else if (color2Count == 0 || color2 == pixel) {
					color2 = pixel;
					color2Count++;
				} else {
					throw new Error(`Too many colours per tile line at (${x + bit}, ${y + line})`);
				}
				pattern[line] = (pattern[line] << 1) | (pixel == color2 ? 1 : 0);
			}
			if (!color2Count) {
				color2 = color1;
			}
			if (color2 < color1) {
				[color1, color2] = [color2, color1];
				pattern[line] ^= 0xFF;
			}
			color[line] = color2 << 4 | color1;
		}
		return [pattern, color];
	}

	getColor(color) {
		return this.palette[color].map(component => Math.round(Math.pow(component, 1 / 2.4) * 7));
	}
}

class Module {
	constructor(source, target) {
		this.source = source;
		this.target = target;
	}

	async generate() {
		let data = this.parse(await fs.promises.readFile(this.source));

		await fs.promises.writeFile(this.target, compress(data));
	}

	parse(data) {
		if (data[0] == 0x21 && data[1] == 0xB3 && data[2] == 0x84) {
			data = data.subarray(0x4B3);
		}

		if (data[0x0A] != 0x45 || data[0x0B] != 0x54 || data[0x0C] != 0x72 || data[0x0D] != 0x61 ||
			data[0x0E] != 0x63 || data[0x0F] != 0x6B || data[0x10] != 0x65 || data[0x11] != 0x72) {
			throw new Error("Not an ETracker file");
		} else {
			data.fill(0, 0x0A, 0x1E);  // Clear ETracker signature
		}

		this.parseModule(data);

		let dataSize = this.patternTable + this.patternTableSize;
		if (dataSize > data.length) {
			throw new Error("File size too small.");
		} else if (dataSize < data.length) {
			// console.log(`File size too large by ${data.length - dataSize} byte(s) in ${this.source}`);
		}

		return data.subarray(0, dataSize);
	}

	parseModule(data) {
		const readWord = address => data[address] | data[address + 1] << 8;

		const tables = [readWord(0), readWord(2), readWord(4), readWord(6), readWord(8)];
		[this.songTable, this.patternTable, this.instrumentTable, this.ornamentTable, ] = tables;

		if (tables.some(table => table >= data.length)) {
			throw new Error("Table address exceeds file length.");
		}
		if (tables.some(table => table > this.patternTable)) {
			throw new Error(`Patterns is not the last table.`);
		}

		this.parseSongTable(data);
		this.parsePatternTable(data);
	}

	parseSongTable(data) {
		let maxPattern = -1;
		let loopPosition = -1;
		let patternHeight = -1;
		for (let songPosition = 0; ; songPosition++) {
			const songCommand = data[this.songTable + songPosition];
			if (songCommand == 0xFF) {
				this.songTableSize = songPosition + 1;
				break;
			} else if (songCommand == 0xFE) {
				if (loopPosition != -1)
					throw new Error("More than one loop position.");
				loopPosition = songPosition;
			} else if (songCommand >= 0x60) {
				if (patternHeight != -1)
					throw new Error("More than one pattern height.");
				patternHeight = songCommand - 0x60;
			} else {
				if (songCommand % 3 != 0)
					throw new Error("Pattern number is not a multiple of 3.");
				maxPattern = Math.max(maxPattern, songCommand / 3);
			}
		}
		if (loopPosition < 0)
			throw new Error("No loop position.");
		if (patternHeight < 0)
			throw new Error("No pattern height.");
		if (maxPattern < 0)
			throw new Error("No patterns.");

		this.patternCount = maxPattern + 1;
		this.patternHeight = patternHeight;
	}

	parsePatternTable(data) {
		const readWord = address => data[address] | data[address + 1] << 8;

		this.patternTableSize = this.patternCount * 6 * 2;
		let patternsEnd = this.patternTable + this.patternTableSize;

		this.patterns = [];
		for (let pattern = 0; pattern < this.patternCount; pattern++) {
			let tracks = [];
			for (let track = 0; track < 6; track++) {
				const trackAddress = readWord(this.patternTable + (pattern * 6 + track) * 2);
				if (trackAddress >= patternsEnd) {
					throw new Error("Track comes after patterns.");
				}
				tracks.push(trackAddress);
			}
			this.patterns.push(tracks);
		}
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
