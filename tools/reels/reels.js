;(function(){
"use strict"
window.addEventListener("load", setupWebGL, false);
var gl, program;

function setupWebGL(evt) {
	window.removeEventListener(evt.type, setupWebGL, false);
	if (!(gl = getRenderingContext()))
		return;

	var source = document.querySelector("#vertex-shader").innerHTML;
	var vertexShader = gl.createShader(gl.VERTEX_SHADER);
	gl.shaderSource(vertexShader,source);
	gl.compileShader(vertexShader);
	source = document.querySelector("#fragment-shader").innerHTML
	var fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
	gl.shaderSource(fragmentShader,source);
	gl.compileShader(fragmentShader);
	program = gl.createProgram();
	gl.attachShader(program, vertexShader);
	gl.attachShader(program, fragmentShader);
	gl.linkProgram(program);
	gl.detachShader(program, vertexShader);
	gl.detachShader(program, fragmentShader);
	gl.deleteShader(vertexShader);
	gl.deleteShader(fragmentShader);
	if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
		var linkErrLog = gl.getProgramInfoLog(program);
		cleanup();
		document.querySelector("p").innerHTML =
			"Shader program did not link successfully. "
			+ "Error log: " + linkErrLog;
		return;
	}

	initializeAttributes();

	gl.useProgram(program);
	const pentagram = getPentagram();
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(pentagram), gl.STATIC_DRAW);
	gl.drawArrays(gl.TRIANGLES, 0, pentagram.length / 2);

	cleanup();
}

function getPentagram() {
	const pentagram = [];
	const pi = Math.atan(1) * 4;
	const angle = pi * 2 / 5;
	const rw = 13, rh = 15;
	const steps = 16;
	for (let j = 0; j < steps; j++) {
		const x = 15.5 + (j & 7) * 32, y = 15.5 + (j >> 3) * 32;
		for (let i = 0; i < 5; i++) {
			const p = i + j / steps;
			pentagram.push(x + rw * Math.sin(p * angle), y - rh * Math.cos(p * angle));
			pentagram.push(x + rw * Math.sin((p + 2) * angle), y - rh * Math.cos((p + 2) * angle));
			pentagram.push(x, y);
		}
	}

	for (let i = 0; i < pentagram.length; i += 2) {
		pentagram[i + 0] = pentagram[i + 0] / 128 - 1;
		pentagram[i + 1] = 1 - pentagram[i + 1] / 96;
	}
	return pentagram;
}

var buffer;
function initializeAttributes() {
	buffer = gl.createBuffer();
	gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
	var a_Position = gl.getAttribLocation(program, 'a_Position');
	if (a_Position < 0) {
			throw new Error('Failed to get the storage location of a_Position');
	}
	gl.vertexAttribPointer(a_Position, 2, gl.FLOAT, false, 0, 0);
	gl.enableVertexAttribArray(a_Position);
}

function cleanup() {
	gl.useProgram(null);
	if (buffer)
		gl.deleteBuffer(buffer);
	if (program)
		gl.deleteProgram(program);
}

function getRenderingContext() {
	var canvas = document.querySelector("canvas");
	var gl = canvas.getContext("webgl", {antialias: false});
	if (!gl) {
		var paragraph = document.querySelector("p");
		paragraph.innerHTML = "Failed to get WebGL context."
			+ "Your browser or device may not support WebGL.";
		return null;
	}
	gl.viewport(0, 0, 256, 192);
	// gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
	gl.clearColor(0.0, 0.0, 0.0, 1.0);
	gl.clear(gl.COLOR_BUFFER_BIT);
	return gl;
}
})();
