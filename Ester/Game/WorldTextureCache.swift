//
//  WorldTextureCache.swift
//  Ester
//
//  Cache das texturas procedurais usadas pelos chunks do oceano.
//

import SpriteKit
import UIKit

final class WorldTextureCache {
    static let shared = WorldTextureCache()

    let softDot: SKTexture
    private let stampTextures: NSCache<NSString, SKTexture> = {
        let cache = NSCache<NSString, SKTexture>()
        cache.name = "WorldTextureCache.stampTextures"
        cache.countLimit = 192
        cache.totalCostLimit = 72 * 1024 * 1024
        return cache
    }()

    private init() {
        let size = CGSize(width: 32, height: 32)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let rect = CGRect(origin: .zero, size: size)
            let context = renderer.cgContext
            context.clear(rect)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let colors = [
                UIColor(white: 1, alpha: 0.85).cgColor,
                UIColor(white: 1, alpha: 0.22).cgColor,
                UIColor(white: 1, alpha: 0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.48, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors,
                                            locations: locations) else { return }
            context.drawRadialGradient(gradient,
                                       startCenter: center,
                                       startRadius: 0,
                                       endCenter: center,
                                       endRadius: size.width / 2,
                                       options: [.drawsAfterEndLocation])
        }
        softDot = SKTexture(image: image)
        softDot.filteringMode = .linear
    }

    func texture(kind: WorldStampKind,
                 zone: DepthZone,
                 biome: AquaticBiome,
                 variant: Int) -> SKTexture {
        let key = WorldTextureKey(kindRaw: kind.rawValue,
                                  zoneRaw: zone.rawValue,
                                  biomeRaw: biome.rawValue,
                                  variant: variant)
        let cacheKey = NSString(string: key.cacheKey)
        if let texture = stampTextures.object(forKey: cacheKey) {
            return texture
        }

        let texture = WorldStampRenderer.makeTexture(kind: kind,
                                                     zone: zone,
                                                     biome: biome,
                                                     variant: variant)
        stampTextures.setObject(texture, forKey: cacheKey, cost: texture.approximateMemoryCost)
        return texture
    }
}

private extension WorldTextureKey {
    var cacheKey: String {
        "\(kindRaw)|\(zoneRaw)|\(biomeRaw)|\(variant)"
    }
}

private extension SKTexture {
    var approximateMemoryCost: Int {
        let size = self.size()
        let pixels = max(1, Int(ceil(size.width)) * Int(ceil(size.height)))
        return pixels * 4
    }
}
