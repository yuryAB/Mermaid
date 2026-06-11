//
//  MermaidStats.swift
//  Ester
//
//  Atributos da sereia, persistência e dinâmica de fome/energia/disposição.
//

import Foundation
import CoreGraphics

final class MermaidStats: Codable {
    var mermaidName: String = "Eistrelinha"
    // 0 = satisfeita, 100 = faminta
    var hunger: CGFloat = 25
    var energy: CGFloat = 85
    // Mantém a chave antiga do save; no jogo este atributo aparece como Disposição.
    var mood: CGFloat = 70
    var xp: CGFloat = 0
    var courage: CGFloat = 12
    var trust: CGFloat = 50
    var curiosity: CGFloat = 60
    var pearls: Int = 20
    var phase: MermaidPhase = .egg
    var birthDate: Date = Date()
    var phaseStartedAt: Date = Date()
    var adaptationByZone: [String: CGFloat] = [DepthZone.mid.storageKey: 30]
    var unlockedZoneKeys: Set<String> = [DepthZone.shallow.storageKey, DepthZone.mid.storageKey]
    var maxDepthMeters: CGFloat = 0
    var puzzlesSolved: Int = 0
    var mealsEaten: Int = 0
    var memories: [String] = []
    var lastSaved: Date = Date()
    /// 0–1: progresso até o ovo chocar (tempo + carinho + desafios).
    var hatchProgress: CGFloat = 0
    /// Posição persistente no mundo (coordenadas reais).
    var posX: CGFloat = World.startPosition.x
    var posY: CGFloat = World.startPosition.y
    /// Regiões descobertas e progresso de exploração por região.
    var discoveredRegionIds: Set<String> = ["nascente"]
    var regionProgress: [String: CGFloat] = [:]
    /// Destino de viagem atual (id de região), se houver.
    var destinationRegionId: String?
    var speedUpgradeLevel: Int = 0
    var shellGainUpgradeLevel: Int = 0
    var feedingUpgradeLevel: Int = 0
    var energyUpgradeLevel: Int = 0
    var dispositionUpgradeLevel: Int = 0

    // Estado transitório, não persiste
    var moodBoost: CGFloat = 0
    var scaredTimer: CGFloat = 0

    enum CodingKeys: String, CodingKey {
        case mermaidName, hunger, energy, mood, xp, courage, trust, curiosity, pearls
        case phase, birthDate, phaseStartedAt, adaptationByZone, unlockedZoneKeys
        case maxDepthMeters
        case puzzlesSolved, mealsEaten, memories, lastSaved, hatchProgress
        case posX, posY, discoveredRegionIds, regionProgress, destinationRegionId
        case speedUpgradeLevel, shellGainUpgradeLevel, feedingUpgradeLevel
        case energyUpgradeLevel, dispositionUpgradeLevel
    }

    init() {}

    /// Decoder tolerante: campos novos ganham default em vez de invalidar o save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mermaidName = try c.decodeIfPresent(String.self, forKey: .mermaidName) ?? "Eistrelinha"
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
        phaseStartedAt = try c.decodeIfPresent(Date.self, forKey: .phaseStartedAt)
            ?? MermaidStats.estimatedPhaseStartedAt(for: phase, birthDate: birthDate)
        adaptationByZone = try c.decodeIfPresent([String: CGFloat].self, forKey: .adaptationByZone) ?? [DepthZone.shallow.storageKey: 30]
        unlockedZoneKeys = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedZoneKeys) ?? [DepthZone.shallow.storageKey]
        maxDepthMeters = try c.decodeIfPresent(CGFloat.self, forKey: .maxDepthMeters) ?? 0
        puzzlesSolved = try c.decodeIfPresent(Int.self, forKey: .puzzlesSolved) ?? 0
        mealsEaten = try c.decodeIfPresent(Int.self, forKey: .mealsEaten) ?? 0
        memories = try c.decodeIfPresent([String].self, forKey: .memories) ?? []
        lastSaved = try c.decodeIfPresent(Date.self, forKey: .lastSaved) ?? Date()
        hatchProgress = try c.decodeIfPresent(CGFloat.self, forKey: .hatchProgress) ?? 0
        posX = try c.decodeIfPresent(CGFloat.self, forKey: .posX) ?? World.startPosition.x
        posY = try c.decodeIfPresent(CGFloat.self, forKey: .posY) ?? World.startPosition.y
        discoveredRegionIds = try c.decodeIfPresent(Set<String>.self, forKey: .discoveredRegionIds) ?? ["nascente"]
        regionProgress = try c.decodeIfPresent([String: CGFloat].self, forKey: .regionProgress) ?? [:]
        destinationRegionId = try c.decodeIfPresent(String.self, forKey: .destinationRegionId)
        speedUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .speedUpgradeLevel) ?? 0
        shellGainUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .shellGainUpgradeLevel) ?? 0
        feedingUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .feedingUpgradeLevel) ?? 0
        energyUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .energyUpgradeLevel) ?? 0
        dispositionUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .dispositionUpgradeLevel) ?? 0
    }

    private static func estimatedPhaseStartedAt(for phase: MermaidPhase, birthDate: Date) -> Date {
        let completedGrowthSteps = max(0, phase.rawValue - MermaidPhase.baby.rawValue)
        let completedMonths = completedGrowthSteps * (completedGrowthSteps + 1) / 2
        let estimated = birthDate.addingTimeInterval(Double(completedMonths) * 30 * 86_400)
        return Swift.min(estimated, Date())
    }

    // MARK: - Derivados

    var wellbeing: CGFloat { ((100 - hunger) + energy + mood) / 3 }

    var disposition: CGFloat {
        get { mood }
        set { mood = newValue }
    }

    var ageDays: Double { Date().timeIntervalSince(birthDate) / 86400 }

    var phaseAgeSeconds: Double { max(0, Date().timeIntervalSince(phaseStartedAt)) }

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

    // MARK: - Aprimoramentos

    private let maximumUpgradeLevel = 100

    enum UpgradeKind: String, CaseIterable {
        case speed
        case shellGain
        case feeding
        case energy
        case disposition

        var title: String {
            switch self {
            case .speed: return "Velocidade"
            case .shellGain: return "Ganho de conchas"
            case .feeding: return "Alimentação"
            case .energy: return "Energia"
            case .disposition: return "Disposição"
            }
        }

        var description: String {
            switch self {
            case .speed:
                return "A Eistrelinha nada mais rápido e leva menos tempo para explorar e viajar."
            case .shellGain:
                return "Aumenta a quantidade de conchas recebidas nas ações."
            case .feeding:
                return "A Eistrelinha demora mais para sentir fome."
            case .energy:
                return "A energia diminui mais devagar durante atividades."
            case .disposition:
                return "A Eistrelinha fica mais disposta e nega menos os seus pedidos."
            }
        }
    }

    func upgradeLevel(for kind: UpgradeKind) -> Int {
        switch kind {
        case .speed: return speedUpgradeLevel
        case .shellGain: return shellGainUpgradeLevel
        case .feeding: return feedingUpgradeLevel
        case .energy: return energyUpgradeLevel
        case .disposition: return dispositionUpgradeLevel
        }
    }

    func upgradeCost(for kind: UpgradeKind) -> Int? {
        let level = upgradeLevel(for: kind)
        guard level < maximumUpgradeLevel else { return nil }
        return (level + 1) * 100
    }

    @discardableResult
    func buyUpgrade(_ kind: UpgradeKind) -> Bool {
        guard let cost = upgradeCost(for: kind) else { return false }
        guard pearls >= cost else { return false }
        pearls -= cost
        switch kind {
        case .speed: speedUpgradeLevel += 1
        case .shellGain: shellGainUpgradeLevel += 1
        case .feeding: feedingUpgradeLevel += 1
        case .energy: energyUpgradeLevel += 1
        case .disposition: dispositionUpgradeLevel += 1
        }
        addMemory("Cuidou de \(kind.title.lowercased()) no Refúgio")
        save()
        return true
    }

    var speedMultiplier: CGFloat {
        (1 + CGFloat(speedUpgradeLevel) * 0.0045).clamped(to: 1...1.45)
    }

    var explorationProgressMultiplier: CGFloat {
        (1 + CGFloat(speedUpgradeLevel) * 0.005).clamped(to: 1...1.5)
    }

    var shellRewardMultiplier: CGFloat {
        (0.85 + CGFloat(shellGainUpgradeLevel) * 0.011).clamped(to: 0.85...1.95)
    }

    var feedingDrainMultiplier: CGFloat {
        (1 - CGFloat(feedingUpgradeLevel) * 0.004).clamped(to: 0.60...1)
    }

    var energyDrainMultiplier: CGFloat {
        (1.15 - CGFloat(energyUpgradeLevel) * 0.005).clamped(to: 0.65...1.15)
    }

    var dispositionDrainMultiplier: CGFloat {
        (1 - CGFloat(dispositionUpgradeLevel) * 0.004).clamped(to: 0.60...1)
    }

    var dispositionAcceptanceBonus: CGFloat {
        CGFloat(dispositionUpgradeLevel) * 0.003
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
        mood = max(0, mood - 8 * dispositionDrainMultiplier)
        moodBoost = max(-30, moodBoost - 10 * dispositionDrainMultiplier)
    }

    func addMemory(_ text: String) {
        memories.append(text)
        if memories.count > 60 { memories.removeFirst() }
    }

    @discardableResult
    func awardPearls(_ baseAmount: Int) -> Int {
        guard baseAmount > 0 else { return 0 }
        let amount = max(1, Int((CGFloat(baseAmount) * shellRewardMultiplier).rounded()))
        pearls += amount
        return amount
    }

    // MARK: - Dinâmica contínua

    /// Avança fome, disposição e energia. `energyDelta` é a taxa por segundo da atividade atual.
    func tick(dt: CGFloat, energyDelta: CGFloat) {
        let hungerRate = 0.08 * feedingDrainMultiplier
        hunger = (hunger + dt * hungerRate).clamped(to: 0...100)

        let adjustedEnergyDelta = energyDelta < 0 ? energyDelta * energyDrainMultiplier : energyDelta
        energy = (energy + adjustedEnergyDelta * dt).clamped(to: 0...100)

        let moodTarget = ((100 - hunger) * 0.45 + energy * 0.35 + 18 + moodBoost)
            .clamped(to: 0...100)
        let moodRate = moodTarget < mood ? 0.03 * dispositionDrainMultiplier : 0.03
        mood += (moodTarget - mood) * min(1, dt * moodRate)
        mood = mood.clamped(to: 0...100)

        if moodBoost > 0 { moodBoost = max(0, moodBoost - dt * 0.4) }
        if moodBoost < 0 { moodBoost = min(0, moodBoost + dt * 0.4 * dispositionDrainMultiplier) }
        if scaredTimer > 0 { scaredTimer -= dt }
    }

    // MARK: - Persistência

    private static let saveKey = "EsterSave.v1"

    static func load() -> MermaidStats {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let stats = try? JSONDecoder().decode(MermaidStats.self, from: data) {
            // garantias de base após migrações de mundo
            stats.unlock(.shallow)
            stats.unlock(.mid)
            stats.discoveredRegionIds.insert("nascente")
            let range = World.floorY...World.surfaceTopY
            if !range.contains(stats.posY) || !(World.minX...World.maxX).contains(stats.posX) {
                stats.posX = World.startPosition.x
                stats.posY = World.startPosition.y
            }
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
        hunger = (hunger + capped * 0.015 * feedingDrainMultiplier).clamped(to: 0...100)
        energy = (energy + capped * 0.01).clamped(to: 0...100)
        let targetDisposition: CGFloat = 52
        let dispositionRate = mood > targetDisposition ? dispositionDrainMultiplier : 1
        mood += (targetDisposition - mood) * min(1, capped / (60 * 60 * 6) * dispositionRate)
        mood = mood.clamped(to: 0...100)
        scaredTimer = 0
        moodBoost = 0
    }
}
