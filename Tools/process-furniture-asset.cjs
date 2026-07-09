#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const projectRoot = path.resolve(__dirname, "..");

const usage = () => {
  console.log(`Furniture asset post-process helper

Removes a flat chroma-key background, writes RGBA PNG, then crops transparent
canvas to the visible illustration bounds. Use this before importing furniture
assets into Assets.xcassets so floor furniture bottom anchors line up correctly.

Usage:
  node Tools/process-furniture-asset.cjs --input tmp/furniture-chroma.png --out Ester/Assets.xcassets/MermaidSideboard.imageset/mermaid-sideboard.png

Options:
  --input PATH                 Source PNG on chroma-key background. Required.
  --out PATH                   Output RGBA PNG. Required.
  --key auto | #RRGGBB         Chroma key. Default: auto from border pixels.
  --transparent-threshold N    Distance treated as transparent. Default: 18.
  --opaque-threshold N         Distance treated as opaque. Default: 220.
  --crop-alpha N               Alpha threshold for crop bbox. Default: 5.
  --padding N                  Transparent padding after crop. Default: 0.
  --no-despill                 Skip green/magenta despill.
`);
};

const parseArgs = (argv) => {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (!value.startsWith("--")) {
      continue;
    }
    const key = value.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith("--")) {
      options[key] = true;
      continue;
    }
    options[key] = next;
    index += 1;
  }
  return options;
};

const findPython = () => {
  const candidates = [
    process.env.PYTHON,
    path.join(process.env.HOME || "", ".cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"),
    "python3",
    "python",
  ].filter(Boolean);

  for (const candidate of candidates) {
    const result = spawnSync(candidate, ["-c", "import PIL"], { encoding: "utf8" });
    if (result.status === 0) {
      return candidate;
    }
  }
  return null;
};

const pythonCode = String.raw`
import json
import math
import os
import sys
from PIL import Image

opts = json.loads(sys.argv[1])
input_path = opts["input"]
out_path = opts["out"]
transparent_threshold = float(opts.get("transparent_threshold", 18))
opaque_threshold = float(opts.get("opaque_threshold", 220))
crop_alpha = int(opts.get("crop_alpha", 5))
padding = int(opts.get("padding", 0))
despill = bool(opts.get("despill", True))

def parse_hex(value):
    value = value.strip()
    if value.startswith("#"):
        value = value[1:]
    if len(value) != 6:
        raise ValueError("--key must be auto or #RRGGBB")
    return tuple(int(value[i:i+2], 16) for i in (0, 2, 4))

def auto_key(image):
    width, height = image.size
    pixels = image.load()
    samples = []
    for x in range(width):
        samples.append(pixels[x, 0][:3])
        samples.append(pixels[x, height - 1][:3])
    for y in range(height):
        samples.append(pixels[0, y][:3])
        samples.append(pixels[width - 1, y][:3])
    # Median is robust against antialiased subject pixels near borders.
    return tuple(sorted(channel)[len(channel) // 2] for channel in zip(*samples))

source = Image.open(input_path).convert("RGBA")
key_opt = opts.get("key", "auto")
key = auto_key(source) if key_opt == "auto" else parse_hex(key_opt)
kr, kg, kb = key
width, height = source.size
pixels = source.load()

transparent_count = 0
partial_count = 0
out = Image.new("RGBA", source.size)
out_pixels = out.load()
range_size = max(1.0, opaque_threshold - transparent_threshold)

for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]
        distance = math.sqrt((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2)
        if distance <= transparent_threshold:
            out_pixels[x, y] = (r, g, b, 0)
            transparent_count += 1
            continue
        if distance < opaque_threshold:
            alpha_scale = max(0.0, min(1.0, (distance - transparent_threshold) / range_size))
            a = int(round(a * alpha_scale))
            partial_count += 1
        if despill:
            # Pull chroma-key spill back toward the other channels without
            # changing the flat sprite colors more than needed at soft edges.
            if kg > kr and kg > kb and g > max(r, b):
                g = int(min(g, max(r, b) + (g - max(r, b)) * 0.25))
            elif kr > kg and kb > kg and abs(kr - kb) < 36:
                rb = int((r + b) / 2)
                r = int(min(r, max(g, rb) + (r - max(g, rb)) * 0.25))
                b = int(min(b, max(g, rb) + (b - max(g, rb)) * 0.25))
        out_pixels[x, y] = (r, g, b, a)

alpha = out.getchannel("A")
bbox = alpha.point(lambda value: 255 if value > crop_alpha else 0).getbbox()
if not bbox:
    raise SystemExit("No visible pixels after chroma-key removal")

left, top, right, bottom = bbox
left = max(0, left - padding)
top = max(0, top - padding)
right = min(width, right + padding)
bottom = min(height, bottom + padding)
cropped = out.crop((left, top, right, bottom))

os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
cropped.save(out_path)

corner_alpha = [
    cropped.getpixel((0, 0))[3],
    cropped.getpixel((cropped.size[0] - 1, 0))[3],
    cropped.getpixel((0, cropped.size[1] - 1))[3],
    cropped.getpixel((cropped.size[0] - 1, cropped.size[1] - 1))[3],
]
print(json.dumps({
    "input": input_path,
    "out": out_path,
    "key": "#%02x%02x%02x" % key,
    "source_size": list(source.size),
    "crop_box": [left, top, right, bottom],
    "output_size": list(cropped.size),
    "transparent_pixels": transparent_count,
    "partial_pixels": partial_count,
    "corner_alpha": corner_alpha,
}, ensure_ascii=False, indent=2))
`;

const options = parseArgs(process.argv.slice(2));
if (options.help || options.h) {
  usage();
  process.exit(0);
}

if (!options.input || !options.out) {
  usage();
  process.exit(1);
}

const input = path.resolve(projectRoot, options.input);
const out = path.resolve(projectRoot, options.out);
if (!fs.existsSync(input)) {
  console.error(`Input not found: ${input}`);
  process.exit(1);
}

const python = findPython();
if (!python) {
  console.error("Python with Pillow is required. Set PYTHON to an interpreter that can `import PIL`.");
  process.exit(1);
}

const payload = {
  input,
  out,
  key: options.key || "auto",
  transparent_threshold: Number(options["transparent-threshold"] ?? 18),
  opaque_threshold: Number(options["opaque-threshold"] ?? 220),
  crop_alpha: Number(options["crop-alpha"] ?? 5),
  padding: Number(options.padding ?? 0),
  despill: !options["no-despill"],
};

const result = spawnSync(python, ["-c", pythonCode, JSON.stringify(payload)], {
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});

if (result.stdout) {
  process.stdout.write(result.stdout);
}
if (result.stderr) {
  process.stderr.write(result.stderr);
}
process.exit(result.status ?? 1);
