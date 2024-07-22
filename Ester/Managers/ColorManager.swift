//
//  ColorManager.swift
//  Ester
//
//  Created by yury antony on 13/06/24.
//

import Foundation
import UIKit

class ColorManager {
    static let shared = ColorManager()
    
    let waters: [String: UIColor]
    let main: [String: UIColor]
    let upper: [String: UIColor]
    let abyss: [String: UIColor]
    
    private init() {
        waters = [
            "surface": UIColor(named: "Surface")!,
            "shallow": UIColor(named: "Shallow")!,
            "mid": UIColor(named: "Mid")!,
            "deep": UIColor(named: "Deep")!,
            "abyssal": UIColor(named: "Abyssal")!
        ]
        
        main = [
            "hairColor": UIColor(named: "MainHair")!,
            "skinColor": UIColor(named: "MainSkin")!,
            "vibrant1": UIColor(named: "MainVibrance1")!,
            "vibrant2": UIColor(named: "MainVibrance2")!
        ]
        
        upper = [
            "hairColor": UIColor(named: "UpperHair")!,
            "skinColor": UIColor(named: "UpperSkin")!,
            "vibrant1": UIColor(named: "UpperVibrance1")!,
            "vibrant2": UIColor(named: "UpperVibrance2")!
        ]
        
        abyss = [
            "hairColor": UIColor(named: "AbyssHair")!,
            "skinColor": UIColor(named: "AbyssSkin")!,
            "vibrant1": UIColor(named: "AbyssVibrance1")!,
            "vibrant2": UIColor(named: "AbyssVibrance2")!
        ]
    }
}
