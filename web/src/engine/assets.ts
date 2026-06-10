import { Assets, Texture } from 'pixi.js';
import { assetManifest, requiredAssetIds, type RequiredAssetId } from '../generated/asset-manifest';

export type MermaidTextures = Record<RequiredAssetId, Texture>;

export async function loadMermaidTextures(): Promise<MermaidTextures> {
  const loaded = {} as MermaidTextures;
  await Promise.all(
    requiredAssetIds.map(async (id) => {
      loaded[id] = await Assets.load(assetManifest[id].path);
    })
  );
  return loaded;
}
