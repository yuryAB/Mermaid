//
//  MermaidAppearance.swift
//  Ester
//
//  Aplicação dinâmica de paleta (adaptação à profundidade) e variantes
//  visuais de direção/animação que não movem o nó base.
//

import Foundation
import SpriteKit
import UIKit

enum MermaidTemplateTexture {
    private static let cache: NSCache<NSString, SKTexture> = {
        let cache = NSCache<NSString, SKTexture>()
        cache.name = "MermaidTemplateTexture.cache"
        cache.countLimit = 96
        cache.totalCostLimit = 28 * 1024 * 1024
        return cache
    }()

    static func texture(named name: String, color: UIColor) -> SKTexture? {
        guard let source = UIImage(named: name) else { return nil }
        let key = "\(name)|\(source.size.width)x\(source.size.height)|\(color.mermaidTemplateCacheKey)"
        let cacheKey = NSString(string: key)
        if let cached = cache.object(forKey: cacheKey) { return cached }

        let format = UIGraphicsImageRendererFormat()
        format.scale = source.scale
        format.opaque = false
        let bounds = CGRect(origin: .zero, size: source.size)
        let image = UIGraphicsImageRenderer(size: source.size, format: format).image { context in
            color.setFill()
            context.cgContext.fill(bounds)
            source.draw(in: bounds, blendMode: .destinationIn, alpha: 1)
        }

        let texture = SKTexture(image: image)
        cache.setObject(texture,
                        forKey: cacheKey,
                        cost: Self.approximateCost(for: source.size, scale: source.scale))
        return texture
    }

    private static func approximateCost(for size: CGSize, scale: CGFloat) -> Int {
        let width = max(1, Int(ceil(size.width * scale)))
        let height = max(1, Int(ceil(size.height * scale)))
        return width * height * 4
    }
}

extension SKSpriteNode {
    func applyTemplateTexture(named name: String,
                              color: UIColor,
                              fallbackBlendFactor: CGFloat = 1.0) {
        if let texture = MermaidTemplateTexture.texture(named: name, color: color) {
            self.texture = texture
            self.color = .white
            self.colorBlendFactor = 0
        } else {
            self.color = color
            self.colorBlendFactor = fallbackBlendFactor
        }
    }
}

private extension UIColor {
    var mermaidTemplateCacheKey: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "%.4f,%.4f,%.4f,%.4f", red, green, blue, alpha)
    }
}

extension Mermaid {
    /// Tinge todas as partes do corpo com a paleta interpolada pela profundidade.
    func applyPalette(_ palette: MermaidPalette) {
        figure.applyPalette(palette)
    }

    /// Atualiza apenas os visuais de direção (cabelo, braços, rosto),
    /// sem disparar as SKActions de deslocamento do nó base.
    func setVisualDirection(_ direction: Direction) {
        currentDirection = direction
        switch direction {
        case .up:
            figure.applyDirection(.up)
        case .down:
            figure.applyDirection(.down)
        case .right:
            figure.applyDirection(.right)
        case .left:
            figure.applyDirection(.left)
        case .none:
            break
        }
    }

    /// Ritmo de nado (ondulação do corpo) sem mover o nó base.
    func setAnimationMode(_ mode: MovementType) {
        switch mode {
        case .idle:
            currentDirection = .none
            figure.applyAnimationMode(.idle)
        case .swing:
            figure.applyAnimationMode(.swing)
        case .fast:
            figure.applyAnimationMode(.fast)
        }
    }
}
