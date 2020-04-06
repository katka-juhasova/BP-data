# Shape Detector

> Shape/gesture/stroke detection/recognition algorithm based on the $1 (dollar) recognizer

This is a quick and dirty port of [this gesture shape recognition library by MatthieuLoutre](https://github.com/MathieuLoutre/shape-detector) to Lua, with some little tweaks. Plays nicely with LÖVE. *Should* work like the original. If not, please do tell me.

## Usage

```lua
	local ShapeDetector = require("ShapeDetector")
	local detector = ShapeDetector.new(ShapeDetector.defaultShapes)
	local stroke = {{ x = 127, y = 141 }, { x = 124, y = 140 }, { x = 120, y = 139 }, { x = 118, y = 139 }, { x = 116, y = 139 }, { x = 111, y = 140 }, { x = 109, y = 141 }, { x = 104, y = 144 }, { x = 100, y = 147 }, { x = 96, y = 152 }, { x = 93, y = 157 }, { x = 90, y = 163 }, { x = 87, y = 169 }, { x = 85, y = 175 }, { x = 83, y = 181 }, { x = 82, y = 190 }, { x = 82, y = 195 }, { x = 83, y = 200 }, { x = 84, y = 205 }, { x = 88, y = 213 }, { x = 91, y = 216 }, { x = 96, y = 219 }, { x = 103, y = 222 }, { x = 108, y = 224 }, { x = 111, y = 224 }, { x = 120, y = 224 }, { x = 133, y = 223 }, { x = 142, y = 222 }, { x = 152, y = 218 }, { x = 160, y = 214 }, { x = 167, y = 210 }, { x = 173, y = 204 }, { x = 178, y = 198 }, { x = 179, y = 196 }, { x = 182, y = 188 }, { x = 182, y = 177 }, { x = 178, y = 167 }, { x = 170, y = 150 }, { x = 163, y = 138 }, { x = 152, y = 130 }, { x = 143, y = 129 }, { x = 140, y = 131 }, { x = 129, y = 136 }, { x = 126, y = 139 }}

	-- Just pass a list of points to :spot()!
	local detected = detector:spot(stroke) -- returns circle
	print(detected.pattern)
	print(detected.score)

	-- You can also specify what you're looking for
	detector:spot(stroke, "triangle") -- returns nil as the circle doesn't match the triangle

	-- The detector can also learn new shapes
	local stroke = {{ x = 307, y = 216 }, { x = 333, y = 186 }, { x = 356, y = 215 }, { x = 375, y = 186 }, { x = 399, y = 216 }, { x = 418, y = 186 }}
	detector:learn("zig-zag", stroke)

	-- If the name of multiple shapes start with the same string, the detector will check for all of them
	detector:learn("zig-zag", stroke)
	detector:learn("zig-zag 2", stroke)

	detector:spot(stroke, "zig-zag") -- will check for both "zig-zag"s and for "zig-zag 2" and return the closest

	-- ShapeDetector can also take options
	-- nbSamplePoints (integer) is 64 by default. Increasing it potentially improves accuracy
	-- threshold (0.0-1.0) is 0.9 by default. High numbers are less forgiving to wonky shapes
	-- rotatable is true by default. Allows you to detect a shape regardless of its rotation.
	detector = ShapeDetector.new(ShapeDetector.defaultShapes, { nbSamplePoints = 128, threshold = 0.8, rotatable = true })
```