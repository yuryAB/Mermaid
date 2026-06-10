import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { assetManifest, requiredAssetIds } from '../generated/asset-manifest';
import { palette } from '../generated/palette';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const publicRoot = path.resolve(__dirname, '../../public');

function fileHash(publicPath: string) {
  const data = fs.readFileSync(path.join(publicRoot, publicPath.replace(/^\//, '')));
  return `sha256:${crypto.createHash('sha256').update(data).digest('hex')}`;
}

describe('generated asset manifest', () => {
  it('includes every required rig texture and optional source assets', () => {
    expect(Object.keys(assetManifest).length).toBeGreaterThanOrEqual(20);
    expect(requiredAssetIds).toEqual([
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
    ]);
  });

  it('preserves alpha, dimensions, and hashes for copied PNGs', () => {
    expect(assetManifest.MermHead.width).toBe(338);
    expect(assetManifest.MermHead.height).toBe(366);
    expect(assetManifest.MermHead.hasAlpha).toBe(true);
    expect(fileHash(assetManifest.MermHead.path)).toBe(assetManifest.MermHead.hash);
  });

  it('rasterizes the SpriteKit PDF masks into 1x, 2x, and 3x web variants', () => {
    expect(assetManifest.roundPiece.kind).toBe('pdf-raster');
    expect(assetManifest.roundPiece.width).toBe(176);
    expect(assetManifest.roundPiece.height).toBe(176);
    expect(assetManifest.roundPiece.variants['2x'].width).toBe(352);
    expect(assetManifest.roundPiece.variants['3x'].height).toBe(528);
    expect(fs.existsSync(path.join(publicRoot, assetManifest.roundPiece.sourcePath.replace(/^\//, '')))).toBe(true);
  });
});

describe('generated palette', () => {
  it('keeps Display P3 CSS values and Pixi fallback tints', () => {
    expect(palette.waters.mid.p3).toContain('color(display-p3');
    expect(palette.waters.mid.hex).toBe('#66AACC');
    expect(palette.themes.upper.skinColor.pixi).toBe(0xf5be78);
  });
});
