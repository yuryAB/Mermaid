import { execFile } from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';
import { PNG } from 'pngjs';

const execFileAsync = promisify(execFile);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.resolve(__dirname, '..');
const repoRoot = path.resolve(webRoot, '..');
const assetRoot = path.join(repoRoot, 'Ester', 'Assets.xcassets');
const outRoot = path.join(webRoot, 'public', 'assets');
const mermaidOut = path.join(outRoot, 'mermaid');
const sourceOut = path.join(outRoot, 'source');
const generatedOut = path.join(webRoot, 'src', 'generated');

const pngAssets = [
  ['MermHead', 'MermHead/MermHead.imageset/MermHead.png', true, 'skin'],
  ['MermHairFront', 'MermHead/MermHairFront.imageset/MermHairFront.png', true, 'hair'],
  ['MermHairBack', 'MermHead/MermHairBack.imageset/MermHairBack.png', true, 'hair'],
  ['hand1', 'MermArms/hand1.imageset/hand1.png', true, 'skin'],
  ['hand2', 'MermArms/hand2.imageset/hand2.png', true, 'skin'],
  ['hand3', 'MermArms/hand3.imageset/hand3.png', false, 'skin'],
  ['hand4', 'MermArms/hand4.imageset/hand4.png', false, 'skin'],
  ['finBack', 'finBack.imageset/finBack.png', true, 'vibrant2'],
  ['finFront', 'finFront.imageset/finFront.png', true, 'vibrant1'],
  ['eye', 'MermFace/eye.imageset/eye.png', true, 'none'],
  ['eyeBrow', 'MermFace/eyeBrow.imageset/eyeBrow.png', true, 'hair'],
  ['mouth', 'MermFace/mouth.imageset/mouth.png', true, 'none'],
  ['bubble', 'bubble.imageset/bubble.png', false, 'none'],
  ['spark', 'Particle Sprite Atlas.spriteatlas/spark.imageset/spark.png', false, 'none'],
  ['bokeh', 'Particle Sprite Atlas.spriteatlas/bokeh.imageset/bokeh.png', false, 'none'],
  ['settingsIcon', 'settingsIcon.imageset/settingsIcon.png', false, 'none']
];

const pdfAssets = [
  ['roundPiece', 'roundPiece.imageset/waistBack.pdf', true, 'skin'],
  ['waist', 'waist.imageset/waistFront.pdf', true, 'vibrant1'],
  ['leftArm', 'leftArm.imageset/leftArm.pdf', false, 'skin'],
  ['rightArm', 'rightArm.imageset/rightArm.pdf', false, 'skin']
];

const requiredIds = [
  'MermHead',
  'MermHairFront',
  'MermHairBack',
  'hand1',
  'hand2',
  'roundPiece',
  'waist',
  'finBack',
  'finFront',
  'eye',
  'eyeBrow',
  'mouth'
];

function posixAsset(...parts) {
  return `/${path.posix.join('assets', ...parts)}`;
}

async function sha256(filePath) {
  const data = await fs.readFile(filePath);
  return `sha256:${crypto.createHash('sha256').update(data).digest('hex')}`;
}

async function sipsProperties(filePath) {
  const { stdout } = await execFileAsync('sips', ['-g', 'pixelWidth', '-g', 'pixelHeight', '-g', 'hasAlpha', filePath]);
  const prop = (name) => {
    const match = stdout.match(new RegExp(`${name}:\\s+([^\\n]+)`));
    return match?.[1]?.trim();
  };
  return {
    width: Number(prop('pixelWidth')),
    height: Number(prop('pixelHeight')),
    hasAlpha: prop('hasAlpha') === 'yes'
  };
}

async function normalizeTintMask(filePath) {
  const png = PNG.sync.read(await fs.readFile(filePath));
  for (let index = 0; index < png.data.length; index += 4) {
    if (png.data[index + 3] === 0) {
      png.data[index] = 255;
      png.data[index + 1] = 255;
      png.data[index + 2] = 255;
      continue;
    }
    png.data[index] = 255;
    png.data[index + 1] = 255;
    png.data[index + 2] = 255;
  }
  await fs.writeFile(filePath, PNG.sync.write(png));
}

async function ensureDirs() {
  await fs.mkdir(mermaidOut, { recursive: true });
  await fs.mkdir(sourceOut, { recursive: true });
  await fs.mkdir(generatedOut, { recursive: true });
}

async function copyPngAssets(manifest) {
  for (const [id, sourceRel, required, tintRole] of pngAssets) {
    const source = path.join(assetRoot, sourceRel);
    const destName = `${id}.png`;
    const dest = path.join(mermaidOut, destName);
    await fs.copyFile(source, dest);
    if (tintRole !== 'none') {
      await normalizeTintMask(dest);
    }
    const props = await sipsProperties(dest);
    manifest[id] = {
      id,
      kind: 'png',
      required,
      tintRole,
      path: posixAsset('mermaid', destName),
      width: props.width,
      height: props.height,
      hasAlpha: props.hasAlpha,
      hash: await sha256(dest),
      source: `Ester/Assets.xcassets/${sourceRel}`
    };
  }
}

async function rasterizePdfAssets(manifest) {
  for (const [id, sourceRel, required, tintRole] of pdfAssets) {
    const source = path.join(assetRoot, sourceRel);
    const sourceDestName = `${id}.pdf`;
    await fs.copyFile(source, path.join(sourceOut, sourceDestName));

    const sourceProps = await sipsProperties(source);
    const variants = {};
    let primaryProps;
    let primaryHash;
    for (const scale of [1, 2, 3]) {
      const width = Math.round(sourceProps.width * scale);
      const height = Math.round(sourceProps.height * scale);
      const destName = scale === 1 ? `${id}.png` : `${id}@${scale}x.png`;
      const dest = path.join(mermaidOut, destName);
      await execFileAsync('sips', ['-s', 'format', 'png', '-z', String(height), String(width), '-o', dest, source]);
      if (tintRole !== 'none') {
        await normalizeTintMask(dest);
      }
      const props = await sipsProperties(dest);
      const hash = await sha256(dest);
      variants[`${scale}x`] = {
        path: posixAsset('mermaid', destName),
        width: props.width,
        height: props.height,
        hash
      };
      if (scale === 1) {
        primaryProps = props;
        primaryHash = hash;
      }
    }

    manifest[id] = {
      id,
      kind: 'pdf-raster',
      required,
      tintRole,
      path: variants['1x'].path,
      width: primaryProps.width,
      height: primaryProps.height,
      hasAlpha: primaryProps.hasAlpha,
      hash: primaryHash,
      variants,
      source: `Ester/Assets.xcassets/${sourceRel}`,
      sourcePath: posixAsset('source', sourceDestName)
    };
  }
}

async function readColorSets() {
  const colorsRoot = path.join(assetRoot, 'Colors');
  const colorSets = [];

  async function walk(dir) {
    for (const entry of await fs.readdir(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (entry.name.endsWith('.colorset')) {
          colorSets.push(full);
        } else {
          await walk(full);
        }
      }
    }
  }

  await walk(colorsRoot);
  const tokens = {};
  for (const dir of colorSets) {
    const name = path.basename(dir, '.colorset');
    const data = JSON.parse(await fs.readFile(path.join(dir, 'Contents.json'), 'utf8'));
    const components = data.colors[0].color.components;
    const red = Number(components.red);
    const green = Number(components.green);
    const blue = Number(components.blue);
    const alpha = Number(components.alpha);
    const rgb = [red, green, blue].map((value) => Math.round(value * 255));
    const hex = `#${rgb.map((value) => value.toString(16).padStart(2, '0')).join('').toUpperCase()}`;
    tokens[name] = {
      p3: `color(display-p3 ${components.red} ${components.green} ${components.blue} / ${components.alpha})`,
      rgb: `rgb(${rgb[0]}, ${rgb[1]}, ${rgb[2]})`,
      hex,
      pixi: Number(`0x${hex.slice(1)}`),
      components: { red, green, blue, alpha }
    };
  }

  return {
    waters: {
      surface: tokens.Surface,
      shallow: tokens.Shallow,
      mid: tokens.Mid,
      deep: tokens.Deep,
      abyssal: tokens.Abyssal
    },
    themes: {
      main: {
        hairColor: tokens.MainHair,
        skinColor: tokens.MainSkin,
        vibrant1: tokens.MainVibrance1,
        vibrant2: tokens.MainVibrance2
      },
      upper: {
        hairColor: tokens.UpperHair,
        skinColor: tokens.UpperSkin,
        vibrant1: tokens.UpperVibrance1,
        vibrant2: tokens.UpperVibrance2
      },
      abyss: {
        hairColor: tokens.AbyssHair,
        skinColor: tokens.AbyssSkin,
        vibrant1: tokens.AbyssVibrance1,
        vibrant2: tokens.AbyssVibrance2
      }
    }
  };
}

function writeTsConst(name, value) {
  return `export const ${name} = ${JSON.stringify(value, null, 2)} as const;\n`;
}

async function writeGeneratedFiles(manifest, palette) {
  const header = '// Generated by scripts/extract-assets.mjs. Do not edit by hand.\n\n';
  await fs.writeFile(
    path.join(generatedOut, 'asset-manifest.ts'),
    `${header}${writeTsConst('assetManifest', manifest)}
export const requiredAssetIds = ${JSON.stringify(requiredIds, null, 2)} as const;
export type AssetId = keyof typeof assetManifest;
export type RequiredAssetId = (typeof requiredAssetIds)[number];
`,
    'utf8'
  );

  await fs.writeFile(
    path.join(generatedOut, 'palette.ts'),
    `${header}${writeTsConst('palette', palette)}
export type ThemeName = keyof typeof palette.themes;
export type DepthZone = keyof typeof palette.waters;
`,
    'utf8'
  );
}

async function main() {
  await ensureDirs();
  const manifest = {};
  await copyPngAssets(manifest);
  await rasterizePdfAssets(manifest);
  await writeGeneratedFiles(manifest, await readColorSets());
  console.log(`Extracted ${Object.keys(manifest).length} assets into ${path.relative(repoRoot, mermaidOut)}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
