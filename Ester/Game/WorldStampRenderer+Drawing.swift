//
//  WorldStampRenderer+Drawing.swift
//  Ester
//
//  Primitivas CoreGraphics reutilizadas pelos stamps procedurais.
//

import UIKit

extension WorldStampRenderer {
    static func fill(_ path: UIBezierPath,
                     in rect: CGRect,
                     top: UIColor,
                     bottom: UIColor,
                     context: CGContext) {
        context.saveGState()
        path.addClip()
        let colors = [top.cgColor, bottom.cgColor] as CFArray
        let locations: [CGFloat] = [0, 1]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors,
                                        locations: locations) else {
            context.restoreGState()
            return
        }
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: rect.midX, y: rect.minY),
                                   end: CGPoint(x: rect.midX, y: rect.maxY),
                                   options: [])
        context.restoreGState()
    }

    static func stroke(_ path: UIBezierPath, color: UIColor, width: CGFloat) {
        color.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    static func drawEllipse(context: CGContext,
                            center: CGPoint,
                            size: CGSize,
                            angle: CGFloat,
                            fill: UIColor,
                            stroke: UIColor,
                            lineWidth: CGFloat) {
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: angle)
        let rect = CGRect(x: -size.width / 2,
                          y: -size.height / 2,
                          width: size.width,
                          height: size.height)
        let path = UIBezierPath(ovalIn: rect)
        fill.setFill()
        path.fill()
        if lineWidth > 0 {
            stroke.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
        context.restoreGState()
    }

    static func drawSoftGlow(context: CGContext,
                             center: CGPoint,
                             radius: CGFloat,
                             color: UIColor) {
        let colors = [
            color.cgColor,
            color.withAlphaComponent(0).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0, 1]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors,
                                        locations: locations) else { return }
        context.saveGState()
        context.drawRadialGradient(gradient,
                                   startCenter: center,
                                   startRadius: 0,
                                   endCenter: center,
                                   endRadius: radius,
                                   options: [.drawsAfterEndLocation])
        context.restoreGState()
    }

    static func cubic(_ a: CGFloat,
                      _ b: CGFloat,
                      _ c: CGFloat,
                      _ d: CGFloat,
                      _ t: CGFloat) -> CGFloat {
        let u = 1 - t
        return u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d
    }
}
