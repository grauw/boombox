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

		// patch colors to look nicer on MSX2
		graphics.setPaletteColor(5, [3, 3, 6]);
		graphics.setPaletteColor(6, [5, 2, 2]);

		graphics.optimiseForCompression();

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
		const selectionPatterns = [
			[0x60, 0x70, 0x78, 0x7C, 0x78, 0x70, 0x60, 0x00],
			[0x0C, 0x1C, 0x3C, 0x7C, 0x3C, 0x1C, 0x0C, 0x00],
			[0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x6C, 0x00],
			[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
		];
		for (let table = 1; table < 3; table++) {
			for (let pattern = 0; pattern < selectionPatterns.length; pattern++) {
				graphics.setPattern(table, 0xFC + pattern, selectionPatterns[pattern].map(v => v ^ 0xFF));
				graphics.setPatternColor(table, 0xFC + pattern, [0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1, 0xF1]);
			}
		}

		const frequencyPatterns = [
			[0x00, 0x00, 0xEE, 0x8A, 0xEA, 0xAA, 0xEE, 0x00],
			[0x00, 0x00, 0xEE, 0x8A, 0xEA, 0x2A, 0xEE, 0x00],
			[0x00, 0x00, 0x50, 0x57, 0x71, 0x52, 0x57, 0x00],
			[0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
		];
		for (let pattern = 0; pattern < frequencyPatterns.length; pattern++) {
			graphics.setPattern(2, 0xF8 + pattern, frequencyPatterns[pattern]);
			graphics.setPatternColor(2, 0xF8 + pattern, [0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86, 0x86]);
		}
	}

	async generateVUMeters(graphics) {
		const L = 0x3E, R = 0xF8;
		graphics.setPattern(1, 0xF3, [0, 0, 0, 0, 0, 0, 0, 0]);
		graphics.setPatternColor(1, 0xF3, [0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31]);
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

	optimiseForCompression() {
		for (let table = 0; table < 3; table++) {
			for (let i = 0; i < 0x800; i++) {
				const color = this.vram[0x2000 + table * 0x800 + i];
				if ((color & 0x0F) == (color >> 4)) {
					for (let j = i + 1; j < 0x800; j++) {
						const nextColor = this.vram[0x2000 + table * 0x800 + j];
						if ((color & 0x0F) == (nextColor & 0x0F) && (color & 0xF0) != (nextColor & 0xF0)) {
							this.vram[0x2000 + table * 0x800 + i] = nextColor;
							this.vram[0x0000 + table * 0x800 + i] = 0x00;
							break;
						} else if ((color & 0xF0) == (nextColor & 0xF0) && (color & 0x0F) != (nextColor & 0x0F)) {
							this.vram[0x2000 + table * 0x800 + i] = nextColor;
							this.vram[0x0000 + table * 0x800 + i] = 0xFF;
							break;
						} else {
							continue;
						}
					}
				}
			}
		}
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
		this.parse(await fs.promises.readFile(this.source));

		this.optimise();

		await fs.promises.writeFile(this.target, compress(this.generateModule()));
	}

	generateModule() {
		const moduleData = new Uint8Array(0x4000);

		const writeWord = (address, value) => {
			moduleData[address] = value & 0xFF;
			moduleData[address + 1] = value >> 8;
		}

		let position = 5 * 2;

		const tracksMap = new Map();
		for (const track of [...this.trackTables.keys()].sort((a, b) => a - b)) {
			tracksMap.set(track, position);
			const trackData = this.trackTables.get(track);
			moduleData.set(trackData, position);
			position += trackData.length;
		}

		const ornamentsMap = new Map();
		for (const ornament of [...this.ornamentTables.keys()].sort((a, b) => a - b)) {
			ornamentsMap.set(ornament, position);
			const ornamentData = this.ornamentTables.get(ornament);
			moduleData.set(ornamentData, position);
			position += ornamentData.length;
		}

		const instrumentsMap = new Map();
		for (const instrument of [...this.instrumentTables.keys()].sort((a, b) => a - b)) {
			instrumentsMap.set(instrument, position);
			const instrumentData = this.instrumentTables.get(instrument);
			moduleData.set(instrumentData, position);
			position += instrumentData.length;
		}

		writeWord(0x04, position);
		for (const instrument of this.instruments) {
			writeWord(position, instrument ? instrumentsMap.get(instrument) : 0);
			position += 2;
		}

		writeWord(0x06, position);
		for (const ornament of this.ornaments) {
			writeWord(position, ornament ? ornamentsMap.get(ornament) : 0);
			position += 2;
		}

		writeWord(0x08, position);
		moduleData.set(this.volumeTable, position);
		position += this.volumeTable.length;

		writeWord(0x00, position);
		moduleData.set(this.songTable, position);
		position += this.songTable.length;

		writeWord(0x02, position);
		for (const pattern of this.patterns) {
			for (const track of pattern) {
				writeWord(position, tracksMap.get(track));
				position += 2;
			}
		}

		return moduleData.subarray(0, position);
	}

	parse(data) {
		if (data[0] == 0x21 && data[1] == 0xB3 && data[2] == 0x84) {
			data = data.subarray(0x4B3);
		}

		if (data[0x0A] != 0x45 || data[0x0B] != 0x54 || data[0x0C] != 0x72 || data[0x0D] != 0x61 ||
			data[0x0E] != 0x63 || data[0x0F] != 0x6B || data[0x10] != 0x65 || data[0x11] != 0x72) {
			throw new Error("Not an ETracker file");
		}

		this.parseModule(data);
	}

	parseModule(data) {
		const readWord = address => data[address] | data[address + 1] << 8;

		const tables = [readWord(0), readWord(2), readWord(4), readWord(6), readWord(8)];
		const [songTable, patternTable, instrumentTable, ornamentTable, volumeTable] = tables;

		if (tables.some(table => table >= data.length)) {
			throw new Error("Table address exceeds file length.");
		}
		if (instrumentTable >= ornamentTable || ornamentTable >= volumeTable || volumeTable >= songTable || songTable >= patternTable) {
			throw new Error("Unexpected table order.");
		}

		this.instrumentTable = this.parseInstrumentTable(data.subarray(instrumentTable, ornamentTable));
		this.ornamentTable = this.parseOrnamentTable(data.subarray(ornamentTable, volumeTable));
		this.volumeTable = this.parseVolumeTable(data.subarray(volumeTable, songTable));
		this.songTable = this.parseSongTable(data.subarray(songTable, patternTable));
		this.patternTable = this.parsePatternTable(data.subarray(patternTable));

		if (0x1E > Math.min(...this.patterns.flat()) ||
			Math.max(...this.patterns.flat()) >= Math.min(...this.ornaments) ||
			Math.max(...this.ornaments) >= Math.min(...this.instruments) ||
			Math.max(...this.instruments) >= instrumentTable) {
			throw new Error("Unexpected table order.");
		}

		this.instrumentTables = new Map();
		const instruments = [...new Set(this.instruments)].sort((a, b) => a - b);
		for (let i = 0; i < instruments.length; i++) {
			this.instrumentTables.set(instruments[i],
				this.parseInstrument(data.subarray(instruments[i], instruments[i + 1] ?? instrumentTable)));
		}

		this.ornamentTables = new Map();
		const ornaments = [...new Set(this.ornaments)].sort((a, b) => a - b);
		for (let i = 0; i < ornaments.length; i++) {
			this.ornamentTables.set(ornaments[i],
				this.parseOrnament(data.subarray(ornaments[i], ornaments[i + 1] ?? Math.min(...this.instruments))));
		}

		this.usedInstruments = new Set();
		this.usedOrnaments = new Set();
		this.trackTables = new Map();
		const tracks = [...new Set(this.patterns.flat())].sort((a, b) => a - b);
		for (let i = 0; i < tracks.length; i++) {
			this.trackTables.set(tracks[i],
				this.parseTrack(data.subarray(tracks[i], tracks[i + 1] ?? Math.min(...this.ornaments))));
		}

		if (Math.max(...this.usedInstruments) >= this.instruments.length)
			throw new Error("Instrument index out of bounds.");
		if (Math.max(...this.usedOrnaments) >= this.ornaments.length)
			throw new Error("Ornament index out of bounds.");
	}

	parseSongTable(songTable) {
		let maxPattern = -1;
		let loopPosition = -1;
		let patternTranspose = -1;
		for (let songPosition = 0; songPosition < songTable.length; songPosition++) {
			const songCommand = songTable[songPosition];
			if (songCommand == 0xFF) {
				if (songPosition + 1 < songTable.length)
					throw new Error("Song table too large.");
				if (loopPosition < 0)
					throw new Error("No loop position.");
				if (patternTranspose < 0)
					throw new Error("No pattern transpose.");
				if (maxPattern < 0)
					throw new Error("No patterns.");

				this.patternCount = maxPattern + 1;
				return songTable.subarray(0, songPosition + 1);
			} else if (songCommand == 0xFE) {
				if (loopPosition != -1)
					throw new Error("More than one loop position.");
				loopPosition = songPosition;
			} else if (songCommand >= 0x60) {
				patternTranspose = songCommand - 0x60;
			} else {
				if (songCommand % 3 != 0)
					throw new Error("Pattern number is not a multiple of 3.");
				maxPattern = Math.max(maxPattern, songCommand / 3);
			}
		}
		throw new Error("Song table ended prematurely.");
	}

	parseInstrumentTable(instrumentTable) {
		const readWord = address => instrumentTable[address] | instrumentTable[address + 1] << 8;
		let emptyInstrument = false;
		this.instruments = [];
		for (let instrumentPosition = 0; instrumentPosition < instrumentTable.length; instrumentPosition += 2) {
			const instrument = readWord(instrumentPosition);
			if (instrument == 0) {
				emptyInstrument = true;
			} else if (emptyInstrument) {
				throw new Error("Empty instrument between nonempty instruments.");
			} else {
				this.instruments.push(instrument);
			}
		}
		return instrumentTable;
	}

	parseOrnamentTable(ornamentTable) {
		const readWord = address => ornamentTable[address] | ornamentTable[address + 1] << 8;
		let emptyOrnament = false;
		this.ornaments = [];
		for (let ornamentPosition = 0; ornamentPosition < ornamentTable.length; ornamentPosition += 2) {
			const ornament = readWord(ornamentPosition);
			if (ornament == 0) {
				emptyOrnament = true;
			} else if (emptyOrnament) {
				throw new Error("Empty ornament between nonempty ornaments.");
			} else {
				this.ornaments.push(ornament);
			}
		}
		return ornamentTable;
	}

	parseVolumeTable(volumeTable) {
		return volumeTable;
	}

	parsePatternTable(patternTable) {
		const readWord = address => patternTable[address] | patternTable[address + 1] << 8;

		// if (this.patternCount * 6 * 2 < patternTable.length)
		// 	throw new Error("Pattern table too large.");
		patternTable = patternTable.subarray(0, this.patternCount * 6 * 2);

		this.patterns = [];
		for (let pattern = 0; pattern < this.patternCount; pattern++) {
			let tracks = [];
			for (let track = 0; track < 6; track++) {
				const trackAddress = readWord((pattern * 6 + track) * 2);
				if (trackAddress >= patternTable) {
					throw new Error("Track comes after patterns.");
				}
				tracks.push(trackAddress);
			}
			this.patterns.push(tracks);
		}

		return patternTable;
	}

	parseInstrument(instrumentData) {
		return instrumentData;
	}

	parseOrnament(ornamentData) {
		return ornamentData;
	}

	parseTrack(trackTable) {
		for (let trackPosition = 0; trackPosition < trackTable.length; trackPosition++) {
			const trackCommand = trackTable[trackPosition];
			if (trackCommand == 0x51) {
				if (trackTable.length > trackPosition + 1)
					throw new Error("Track table too large.");

				return trackTable.subarray(0, trackPosition + 1);
			} else if (trackCommand >= 0x52 && trackCommand < 0x72) {
				this.usedInstruments.add(trackCommand - 0x52);
			} else if (trackCommand >= 0x30 && trackCommand < 0x50) {
				this.usedOrnaments.add(trackCommand - 0x30);
			}
		}
		throw new Error("Track table ended prematurely.");
	}

	optimise() {
		this.optimiseInstruments();
		this.optimiseOrnaments();
	}

	optimiseInstruments() {
		if (this.usedInstruments.size == this.instruments.length)
			return;

		for (let i = 0; i < this.instruments.length; i++) {
			if (!this.usedInstruments.has(i)) {
				this.instrumentTables.delete(this.instruments[i]);
				this.instruments[i] = 0;
			}
		}
	}

	optimiseOrnaments() {
		if (this.usedOrnaments.size == this.ornaments.length)
			return;

		for (let i = 0; i < this.ornaments.length; i++) {
			const ornament = this.ornaments[i];
			if (!this.usedOrnaments.has(ornament)) {
				this.ornamentTables.delete(ornament);
				this.ornaments[i] = 0;
			}
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
