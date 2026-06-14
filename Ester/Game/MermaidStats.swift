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
    // Campo legado de saves antigos. Coragem não participa das regras atuais.
    var courage: CGFloat = 12
    var trust: CGFloat = 50
    var curiosity: CGFloat = 60
    var pearls: Int = 20
    var phase: MermaidPhase = .egg
    var birthDate: Date = Date()
    var phaseStartedAt: Date = Date()
    var adaptationByZone: [String: CGFloat] = [DepthZone.clear.storageKey: 30,
                                               DepthZone.shallow.storageKey: 30,
                                               DepthZone.mid.storageKey: 30]
    var unlockedZoneKeys: Set<String> = [DepthZone.clear.storageKey,
                                         DepthZone.shallow.storageKey,
                                         DepthZone.mid.storageKey]
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
    /// Fog of war do mapa de expedição: regionId -> "col,row" -> 0...1.
    var expeditionRevealByRegion: [String: [String: CGFloat]] = [:]
    var discoveredPOIKeys: Set<String> = []
    var inventoryItems: [String: Int] = [:]
    var activeBuffs: [TimedBuff] = []
    var mapPositionByRegion: [String: CGPoint] = [:]
    /// Destino de viagem atual (id de região), se houver.
    var destinationRegionId: String?
    var speedUpgradeLevel: Int = 0
    var shellGainUpgradeLevel: Int = 0
    var feedingUpgradeLevel: Int = 0
    var energyUpgradeLevel: Int = 0
    var dispositionUpgradeLevel: Int = 0
    var balanceVersion: Int = GameBalance.currentVersion

    // Estado transitório, não persiste
    var moodBoost: CGFloat = 0
    var scaredTimer: CGFloat = 0

    enum CodingKeys: String, CodingKey {
        case mermaidName, hunger, energy, mood, xp, courage, trust, curiosity, pearls
        case phase, birthDate, phaseStartedAt, adaptationByZone, unlockedZoneKeys
        case maxDepthMeters
        case puzzlesSolved, mealsEaten, memories, lastSaved, hatchProgress
        case posX, posY, discoveredRegionIds, regionProgress, expeditionRevealByRegion
        case discoveredPOIKeys, inventoryItems, activeBuffs, mapPositionByRegion, destinationRegionId
        case speedUpgradeLevel, shellGainUpgradeLevel, feedingUpgradeLevel
        case energyUpgradeLevel, dispositionUpgradeLevel
        case balanceVersion
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
        adaptationByZone = try c.decodeIfPresent([String: CGFloat].self, forKey: .adaptationByZone)
            ?? [DepthZone.clear.storageKey: 30,
                DepthZone.shallow.storageKey: 30,
                DepthZone.mid.storageKey: 30]
        unlockedZoneKeys = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedZoneKeys)
            ?? [DepthZone.clear.storageKey, DepthZone.shallow.storageKey, DepthZone.mid.storageKey]
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
        expeditionRevealByRegion = try c.decodeIfPresent([String: [String: CGFloat]].self, forKey: .expeditionRevealByRegion) ?? [:]
        discoveredPOIKeys = try c.decodeIfPresent(Set<String>.self, forKey: .discoveredPOIKeys) ?? []
        inventoryItems = try c.decodeIfPresent([String: Int].self, forKey: .inventoryItems) ?? [:]
        activeBuffs = try c.decodeIfPresent([TimedBuff].self, forKey: .activeBuffs) ?? []
        mapPositionByRegion = try c.decodeIfPresent([String: CGPoint].self, forKey: .mapPositionByRegion) ?? [:]
        destinationRegionId = try c.decodeIfPresent(String.self, forKey: .destinationRegionId)
        speedUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .speedUpgradeLevel) ?? 0
        shellGainUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .shellGainUpgradeLevel) ?? 0
        feedingUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .feedingUpgradeLevel) ?? 0
        energyUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .energyUpgradeLevel) ?? 0
        dispositionUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .dispositionUpgradeLevel) ?? 0
        balanceVersion = try c.decodeIfPresent(Int.self, forKey: .balanceVersion) ?? 1
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

    // MARK: - Mapa de expedição

    static let expeditionMapColumns = 28
    static let expeditionMapRows = 34

    func expeditionReveal(for regionId: String) -> [String: CGFloat] {
        expeditionRevealByRegion[regionId] ?? [:]
    }

    func revealExpeditionMap(in region: Region, near point: CGPoint) {
        guard phase != .egg else { return }

        let column = Self.expeditionColumn(forX: point.x, in: region)
        let row = Self.expeditionRow(forY: point.y)
        let radius = Self.revealRadius(for: phase)
        guard radius > 0 else { return }

        var reveal = expeditionRevealByRegion[region.id] ?? [:]
        for dx in -radius...radius {
            for dy in -radius...radius {
                let candidateColumn = column + dx
                let candidateRow = row + dy
                guard (0..<Self.expeditionMapColumns).contains(candidateColumn),
                      (0..<Self.expeditionMapRows).contains(candidateRow) else { continue }

                let distance = sqrt(CGFloat(dx * dx + dy * dy))
                guard distance <= CGFloat(radius) + 0.2 else { continue }

                let falloff = 1 - distance / (CGFloat(radius) + 0.75)
                let gain = (0.16 + falloff * 0.18).clamped(to: 0.08...0.34)
                let key = Self.expeditionCellKey(column: candidateColumn, row: candidateRow)
                reveal[key] = ((reveal[key] ?? 0) + gain).clamped(to: 0...1)
            }
        }
        expeditionRevealByRegion[region.id] = reveal
    }

    static func expeditionCellKey(column: Int, row: Int) -> String {
        "\(column),\(row)"
    }

    static func expeditionCellCoordinates(from key: String) -> (column: Int, row: Int)? {
        let parts = key.split(separator: ",")
        guard parts.count == 2,
              let column = Int(parts[0]),
              let row = Int(parts[1]) else { return nil }
        return (column, row)
    }

    static func expeditionColumn(forX x: CGFloat, in region: Region) -> Int {
        let width = max(1, region.xRange.upperBound - region.xRange.lowerBound)
        let t = ((x - region.xRange.lowerBound) / width).clamped(to: 0...1)
        return Int((t * CGFloat(expeditionMapColumns - 1)).rounded())
    }

    static func expeditionRow(forY y: CGFloat) -> Int {
        let height = max(1, World.surfaceTopY - World.floorY)
        let t = ((y - World.floorY) / height).clamped(to: 0...1)
        return Int((t * CGFloat(expeditionMapRows - 1)).rounded())
    }

    private static func revealRadius(for phase: MermaidPhase) -> Int {
        switch phase {
        case .egg: return 0
        case .baby: return 2
        case .child: return 3
        case .teen: return 4
        case .young: return 5
        case .adult: return 6
        }
    }

    // MARK: - Recompensas persistentes

    func collectItem(id: String) {
        inventoryItems[id, default: 0] += 1
        addMemory("Encontrou \(id)")
    }

    func discoverPOI(_ key: String) {
        discoveredPOIKeys.insert(key)
    }

    func isPOIDiscovered(_ key: String) -> Bool {
        discoveredPOIKeys.contains(key)
    }

    func addTimedBuff(_ kind: TimedBuffKind, title: String? = nil, duration: TimeInterval) {
        let buff = TimedBuff(kind: kind,
                             title: title ?? kind.title,
                             expiresAt: Date().addingTimeInterval(duration))
        activeBuffs.removeAll { $0.kind == kind || $0.expiresAt <= Date() }
        activeBuffs.append(buff)
        addMemory("Efeito temporário: \(buff.title)")
    }

    func hasActiveBuff(_ kind: TimedBuffKind) -> Bool {
        activeBuffs.contains { $0.kind == kind && $0.expiresAt > Date() }
    }

    private func pruneExpiredBuffs() {
        activeBuffs.removeAll { $0.expiresAt <= Date() }
    }

    func rememberMapPosition(_ point: CGPoint, in region: Region) {
        let x = point.x.clamped(to: region.xRange)
        let y = point.y.clamped(to: World.floorY...World.surfaceTopY)
        mapPositionByRegion[region.id] = CGPoint(x: x, y: y)
    }

    func savedMapPosition(for region: Region) -> CGPoint? {
        mapPositionByRegion[region.id]
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
        return 40 + level * 35 + level * level * 3
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
        let buff: CGFloat = hasActiveBuff(.swiftCurrent) ? 0.28 : 0
        return (1 + buff + CGFloat(speedUpgradeLevel) * 0.007).clamped(to: 1...1.9)
    }

    var explorationProgressMultiplier: CGFloat {
        (1 + CGFloat(speedUpgradeLevel) * 0.007).clamped(to: 1...1.7)
    }

    var shellRewardMultiplier: CGFloat {
        (0.65 + CGFloat(shellGainUpgradeLevel) * 0.035).clamped(to: 0.65...2.4)
    }

    var feedingDrainMultiplier: CGFloat {
        (1 - CGFloat(feedingUpgradeLevel) * 0.012).clamped(to: 0.35...1)
    }

    var energyDrainMultiplier: CGFloat {
        (1.12 - CGFloat(energyUpgradeLevel) * 0.012).clamped(to: 0.45...1.12)
    }

    var dispositionDrainMultiplier: CGFloat {
        (1 - CGFloat(dispositionUpgradeLevel) * 0.010).clamped(to: 0.35...1)
    }

    var dispositionAcceptanceBonus: CGFloat {
        (CGFloat(dispositionUpgradeLevel) * 0.008).clamped(to: 0...0.45)
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
        let amount = GameBalance.scaledPearlReward(baseAmount: baseAmount,
                                                   multiplier: shellRewardMultiplier)
        pearls += amount
        return amount
    }

    // MARK: - Dinâmica contínua

    /// Avança fome, disposição e energia. `energyDelta` é a taxa por segundo da atividade atual.
    func tick(dt: CGFloat, energyDelta: CGFloat) {
        pruneExpiredBuffs()
        let hungerRate = hasActiveBuff(.fullBelly) ? 0 : GameBalance.hungerRate(for: phase) * feedingDrainMultiplier
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
            stats.unlock(.clear)
            stats.unlock(.shallow)
            stats.unlock(.mid)
            stats.discoveredRegionIds.insert("nascente")
            let range = World.floorY...World.surfaceTopY
            if !range.contains(stats.posY) || !(World.minX...World.maxX).contains(stats.posX) {
                stats.posX = World.startPosition.x
                stats.posY = World.startPosition.y
            }
            stats.applyBalanceMigrationIfNeeded()
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

    private func applyBalanceMigrationIfNeeded() {
        guard balanceVersion < GameBalance.currentVersion else { return }
        if phase == .baby {
            pearls = GameBalance.babyStartingPearls
            xp = min(xp, 30)
            hunger = max(hunger, 45)
            energy = energy.clamped(to: 55...80)
            mood = min(mood, 65)
            speedUpgradeLevel = 0
            shellGainUpgradeLevel = 0
            feedingUpgradeLevel = 0
            energyUpgradeLevel = 0
            dispositionUpgradeLevel = 0
            addMemory("Economia da fase bebê rebalanceada")
        }
        balanceVersion = GameBalance.currentVersion
    }
}
