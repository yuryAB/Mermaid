//
//  MermaidStats.swift
//  Ester
//
//  Atributos da sereia, persistência e dinâmica de fome/energia/humor.
//

import Foundation
import CoreGraphics

final class MermaidStats: Codable {
    // 0 = satisfeita, 100 = faminta
    var hunger: CGFloat = 25
    var energy: CGFloat = 85
    var mood: CGFloat = 70
    var xp: CGFloat = 0
    var courage: CGFloat = 12
    var trust: CGFloat = 50
    var curiosity: CGFloat = 60
    var pearls: Int = 20
    var phase: MermaidPhase = .egg
    var birthDate: Date = Date()
    var adaptationByZone: [String: CGFloat] = [DepthZone.shallow.storageKey: 30]
    var unlockedZoneKeys: Set<String> = [DepthZone.shallow.storageKey]
    var shelterLevel: Int = 1
    var storedFood: Int = 0
    var maxDepthMeters: CGFloat = 0
    var puzzlesSolved: Int = 0
    var mealsEaten: Int = 0
    var memories: [String] = []
    var lastSaved: Date = Date()
    /// 0–1: progresso até o ovo chocar (tempo + carinho + desafios).
    var hatchProgress: CGFloat = 0

    // Estado transitório, não persiste
    var moodBoost: CGFloat = 0
    var scaredTimer: CGFloat = 0

    enum CodingKeys: String, CodingKey {
        case hunger, energy, mood, xp, courage, trust, curiosity, pearls
        case phase, birthDate, adaptationByZone, unlockedZoneKeys
        case shelterLevel, storedFood, maxDepthMeters
        case puzzlesSolved, mealsEaten, memories, lastSaved, hatchProgress
    }

    init() {}

    /// Decoder tolerante: campos novos ganham default em vez de invalidar o save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hunger = try c.decodeIfPresent(CGFloat.self, forKey: .hunger) ?? 25
        energy = try c.decodeIfPresent(CGFloat.self, forKey: .energy) ?? 85
        mood = try c.decodeIfPresent(CGFloat.self, forKey: .mood) ?? 70
        xp = try c.decodeIfPresent(CGFloat.self, forKey: .xp) ?? 0
        courage = try c.decodeIfPresent(CGFloat.self, forKey: .courage) ?? 12
        trust = try c.decodeIfPresent(CGFloat.self, forKey: .trust) ?? 50
        curiosity = try c.decodeIfPresent(CGFloat.self, forKey: .curiosity) ?? 60
        pearls = try c.decodeIfPresent(Int.self, forKey: .pearls) ?? 20
        phase = try c.decodeIfPresent(MermaidPhase.self, forKey: .phase) ?? .egg
        birthDate = try c.decodeIfPresent(Date.self, forKey: .birthDate) ?? Date()
        adaptationByZone = try c.decodeIfPresent([String: CGFloat].self, forKey: .adaptationByZone) ?? [DepthZone.shallow.storageKey: 30]
        unlockedZoneKeys = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedZoneKeys) ?? [DepthZone.shallow.storageKey]
        shelterLevel = try c.decodeIfPresent(Int.self, forKey: .shelterLevel) ?? 1
        storedFood = try c.decodeIfPresent(Int.self, forKey: .storedFood) ?? 0
        maxDepthMeters = try c.decodeIfPresent(CGFloat.self, forKey: .maxDepthMeters) ?? 0
        puzzlesSolved = try c.decodeIfPresent(Int.self, forKey: .puzzlesSolved) ?? 0
        mealsEaten = try c.decodeIfPresent(Int.self, forKey: .mealsEaten) ?? 0
        memories = try c.decodeIfPresent([String].self, forKey: .memories) ?? []
        lastSaved = try c.decodeIfPresent(Date.self, forKey: .lastSaved) ?? Date()
        hatchProgress = try c.decodeIfPresent(CGFloat.self, forKey: .hatchProgress) ?? 0
    }

    // MARK: - Derivados

    var wellbeing: CGFloat { ((100 - hunger) + energy + mood) / 3 }

    var ageDays: Double { Date().timeIntervalSince(birthDate) / 86400 }

    var ageText: String {
        let days = Int(ageDays)
        if days < 1 {
            let hours = Int(ageDays * 24)
            return hours < 1 ? "recém-chegada" : "\(hours)h"
        }
        return "\(days)d"
    }

    // MARK: - Adaptação e zonas

    func adaptation(for zone: DepthZone) -> CGFloat {
        adaptationByZone[zone.storageKey] ?? 0
    }

    func setAdaptation(_ value: CGFloat, for zone: DepthZone) {
        adaptationByZone[zone.storageKey] = value.clamped(to: 0...100)
    }

    func isUnlocked(_ zone: DepthZone) -> Bool {
        unlockedZoneKeys.contains(zone.storageKey)
    }

    func unlock(_ zone: DepthZone) {
        unlockedZoneKeys.insert(zone.storageKey)
    }

    // MARK: - Ganhos

    func gainXP(_ amount: CGFloat) {
        xp += amount
    }

    func boostMood(_ amount: CGFloat) {
        moodBoost = min(40, moodBoost + amount)
    }

    func scare(duration: CGFloat) {
        scaredTimer = max(scaredTimer, duration)
        mood = max(0, mood - 8)
        moodBoost = max(-30, moodBoost - 10)
    }

    func addMemory(_ text: String) {
        memories.append(text)
        if memories.count > 60 { memories.removeFirst() }
    }

    // MARK: - Dinâmica contínua

    /// Avança fome, humor e energia. `energyDelta` é a taxa por segundo da atividade atual.
    func tick(dt: CGFloat, energyDelta: CGFloat) {
        hunger = (hunger + dt * 0.022).clamped(to: 0...100)
        energy = (energy + energyDelta * dt).clamped(to: 0...100)

        let moodTarget = ((100 - hunger) * 0.45 + energy * 0.35 + 18 + moodBoost)
            .clamped(to: 0...100)
        mood += (moodTarget - mood) * min(1, dt * 0.03)
        mood = mood.clamped(to: 0...100)

        if moodBoost > 0 { moodBoost = max(0, moodBoost - dt * 0.4) }
        if moodBoost < 0 { moodBoost = min(0, moodBoost + dt * 0.4) }
        if scaredTimer > 0 { scaredTimer -= dt }
    }

    // MARK: - Persistência

    private static let saveKey = "EsterSave.v1"

    static func load() -> MermaidStats {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let stats = try? JSONDecoder().decode(MermaidStats.self, from: data) {
            stats.applyOfflineProgress()
            return stats
        }
        return MermaidStats()
    }

    func save() {
        lastSaved = Date()
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: MermaidStats.saveKey)
        }
    }

    /// Progresso enquanto o app esteve fechado: fome cresce devagar, energia recupera.
    private func applyOfflineProgress() {
        let elapsed = CGFloat(Date().timeIntervalSince(lastSaved))
        guard elapsed > 30 else { return }
        let capped = min(elapsed, 60 * 60 * 16)
        hunger = (hunger + capped * 0.008).clamped(to: 0...100)
        energy = (energy + capped * 0.01).clamped(to: 0...100)
        mood += (55 - mood) * min(1, capped / (60 * 60 * 6))
        mood = mood.clamped(to: 0...100)
        scaredTimer = 0
        moodBoost = 0
    }
}
