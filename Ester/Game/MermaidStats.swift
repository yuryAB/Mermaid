//
//  MermaidStats.swift
//  Ester
//
//  Atributos da sereia, persistência e dinâmica de fome/energia/disposição.
//

import Foundation
import CoreGraphics

final class MermaidStats: Codable {
    static let defaultMermaidName = "Eistrelinha"
    private static var activeSessionStats: MermaidStats?

    var mermaidName: String = MermaidStats.defaultMermaidName
    // 0 = satisfeita, 100 = faminta
    var hunger: CGFloat = 25
    var energy: CGFloat = 85
    // Mantém a chave antiga do save; no jogo este atributo aparece como Disposição.
    var mood: CGFloat = 70
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
    var unlockedZoneKeys: Set<String> = [DepthZone.shallow.storageKey,
                                         DepthZone.mid.storageKey]
    var maxDepthMeters: CGFloat = 0
    var puzzlesSolved: Int = 0
    var challengeHighScores: [String: Int] = [:]
    var mealsEaten: Int = 0
    var memories: [String] = []
    var lastSaved: Date = Date()
    /// 0–1: progresso até o ovo chocar (tempo + carinho + desafios).
    var hatchProgress: CGFloat = 0
    /// Posição persistente no mundo (coordenadas reais).
    var posX: CGFloat = World.startPosition.x
    var posY: CGFloat = World.startPosition.y
    /// Regiões descobertas e progresso de exploração por região.
    var discoveredRegionIds: Set<String> = ["recife_tropical"]
    var regionProgress: [String: CGFloat] = [:]
    /// Fog of war do mapa de expedição: regionId -> "col,row" -> 0...1.
    var expeditionRevealByRegion: [String: [String: CGFloat]] = [:]
    var discoveredPOIKeys: Set<String> = []
    var visitedPOIKeys: Set<String> = []
    var collectedPOIRewardKeys: Set<String> = []
    var repeatablePOIRewardAvailableAtByKey: [String: Date] = [:]
    var inventoryItems: [String: Int] = [:]
    var activeBuffs: [TimedBuff] = []
    var currentRegionId: String = "recife_tropical"
    var mapPositionByRegion: [String: CGPoint] = [:]
    var mapEntryPointByRegion: [String: CGPoint] = [:]
    var entryTextKeys: Set<String> = []
    var pendingRegionDiscoveryId: String?
    var discoveryRouteRegionId: String?
    var readyRegionDiscoveryId: String?
    var discoveryPointByRegion: [String: CGPoint] = [:]
    /// Destino de viagem atual (id de região), se houver.
    var destinationRegionId: String?
    var speedUpgradeLevel: Int = 0
    var shellGainUpgradeLevel: Int = 0
    var feedingUpgradeLevel: Int = 0
    var energyUpgradeLevel: Int = 0
    var dispositionUpgradeLevel: Int = 0
    // Cheats sao apenas da sessao em memoria. Eles nao entram no save.
    var cheatSuperSpeedEnabled: Bool = false
    var cheatAlwaysAcceptCommandsEnabled: Bool = false
    var cheatDepthAccessEnabled: Bool = false
    var babyGuaranteedRequestsUsed: Int = 0
    var balanceVersion: Int = GameBalance.currentVersion

    // Estado transitório, não persiste
    var moodBoost: CGFloat = 0
    var scaredTimer: CGFloat = 0
    private var regionIdsMigratedThisSession = false
    private var cheatSessionBaselineData: Data?
    private var cheatSessionPersistenceBlocked = false

    enum CodingKeys: String, CodingKey {
        case mermaidName, hunger, energy, mood, courage, trust, curiosity, pearls
        case phase, birthDate, phaseStartedAt, adaptationByZone, unlockedZoneKeys
        case maxDepthMeters
        case puzzlesSolved, challengeHighScores, mealsEaten, memories, lastSaved, hatchProgress
        case posX, posY, discoveredRegionIds, regionProgress, expeditionRevealByRegion
        case discoveredPOIKeys, visitedPOIKeys, collectedPOIRewardKeys
        case repeatablePOIRewardAvailableAtByKey
        case inventoryItems, activeBuffs, currentRegionId
        case mapPositionByRegion, mapEntryPointByRegion, entryTextKeys
        case pendingRegionDiscoveryId, discoveryRouteRegionId, readyRegionDiscoveryId
        case discoveryPointByRegion, destinationRegionId
        case speedUpgradeLevel, shellGainUpgradeLevel, feedingUpgradeLevel
        case energyUpgradeLevel, dispositionUpgradeLevel
        case babyGuaranteedRequestsUsed
        case balanceVersion
    }

    init() {}

    /// Decoder tolerante: campos novos ganham default em vez de invalidar o save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mermaidName = try c.decodeIfPresent(String.self, forKey: .mermaidName) ?? MermaidStats.defaultMermaidName
        hunger = try c.decodeIfPresent(CGFloat.self, forKey: .hunger) ?? 25
        energy = try c.decodeIfPresent(CGFloat.self, forKey: .energy) ?? 85
        mood = try c.decodeIfPresent(CGFloat.self, forKey: .mood) ?? 70
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
            ?? [DepthZone.shallow.storageKey, DepthZone.mid.storageKey]
        if phase < DepthZone.clear.minPhase {
            unlockedZoneKeys.remove(DepthZone.clear.storageKey)
        }
        maxDepthMeters = try c.decodeIfPresent(CGFloat.self, forKey: .maxDepthMeters) ?? 0
        puzzlesSolved = try c.decodeIfPresent(Int.self, forKey: .puzzlesSolved) ?? 0
        challengeHighScores = try c.decodeIfPresent([String: Int].self, forKey: .challengeHighScores) ?? [:]
        mealsEaten = try c.decodeIfPresent(Int.self, forKey: .mealsEaten) ?? 0
        memories = try c.decodeIfPresent([String].self, forKey: .memories) ?? []
        lastSaved = try c.decodeIfPresent(Date.self, forKey: .lastSaved) ?? Date()
        hatchProgress = try c.decodeIfPresent(CGFloat.self, forKey: .hatchProgress) ?? 0
        posX = try c.decodeIfPresent(CGFloat.self, forKey: .posX) ?? World.startPosition.x
        posY = try c.decodeIfPresent(CGFloat.self, forKey: .posY) ?? World.startPosition.y
        discoveredRegionIds = try c.decodeIfPresent(Set<String>.self, forKey: .discoveredRegionIds) ?? ["recife_tropical"]
        regionProgress = try c.decodeIfPresent([String: CGFloat].self, forKey: .regionProgress) ?? [:]
        expeditionRevealByRegion = try c.decodeIfPresent([String: [String: CGFloat]].self, forKey: .expeditionRevealByRegion) ?? [:]
        discoveredPOIKeys = try c.decodeIfPresent(Set<String>.self, forKey: .discoveredPOIKeys) ?? []
        visitedPOIKeys = try c.decodeIfPresent(Set<String>.self, forKey: .visitedPOIKeys) ?? []
        collectedPOIRewardKeys = try c.decodeIfPresent(Set<String>.self, forKey: .collectedPOIRewardKeys) ?? []
        repeatablePOIRewardAvailableAtByKey = try c.decodeIfPresent([String: Date].self, forKey: .repeatablePOIRewardAvailableAtByKey) ?? [:]
        inventoryItems = try c.decodeIfPresent([String: Int].self, forKey: .inventoryItems) ?? [:]
        activeBuffs = try c.decodeIfPresent([TimedBuff].self, forKey: .activeBuffs) ?? []
        currentRegionId = try c.decodeIfPresent(String.self, forKey: .currentRegionId) ?? "recife_tropical"
        mapPositionByRegion = try c.decodeIfPresent([String: CGPoint].self, forKey: .mapPositionByRegion) ?? [:]
        mapEntryPointByRegion = try c.decodeIfPresent([String: CGPoint].self, forKey: .mapEntryPointByRegion) ?? [:]
        entryTextKeys = try c.decodeIfPresent(Set<String>.self, forKey: .entryTextKeys) ?? []
        pendingRegionDiscoveryId = try c.decodeIfPresent(String.self, forKey: .pendingRegionDiscoveryId)
        discoveryRouteRegionId = try c.decodeIfPresent(String.self, forKey: .discoveryRouteRegionId)
        readyRegionDiscoveryId = try c.decodeIfPresent(String.self, forKey: .readyRegionDiscoveryId)
        discoveryPointByRegion = try c.decodeIfPresent([String: CGPoint].self, forKey: .discoveryPointByRegion) ?? [:]
        destinationRegionId = try c.decodeIfPresent(String.self, forKey: .destinationRegionId)
        speedUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .speedUpgradeLevel) ?? 0
        shellGainUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .shellGainUpgradeLevel) ?? 0
        feedingUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .feedingUpgradeLevel) ?? 0
        energyUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .energyUpgradeLevel) ?? 0
        dispositionUpgradeLevel = try c.decodeIfPresent(Int.self, forKey: .dispositionUpgradeLevel) ?? 0
        babyGuaranteedRequestsUsed = try c.decodeIfPresent(Int.self, forKey: .babyGuaranteedRequestsUsed) ?? 0
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

    func highScore(for kind: ChallengeKind) -> Int {
        challengeHighScores[kind.rawValue] ?? 0
    }

    @discardableResult
    func recordHighScore(_ score: Int, for kind: ChallengeKind) -> Bool {
        guard score > highScore(for: kind) else { return false }
        challengeHighScores[kind.rawValue] = score
        return true
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

    func canAccess(_ zone: DepthZone) -> Bool {
        isUnlocked(zone) && (cheatDepthAccessEnabled || phase >= zone.minPhase)
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

    func mapDiscoveryProgress(in region: Region) -> CGFloat {
        let areaProgress = expeditionAreaProgress(in: region)
        guard hasReachablePOIs(in: region) else { return areaProgress }

        let poiProgress = poiDiscoveryProgress(in: region)
        return ((areaProgress + poiProgress) / 2).clamped(to: 0...1)
    }

    func expeditionAreaProgress(in region: Region) -> CGFloat {
        let reveal = expeditionReveal(for: region.id)
        var total: CGFloat = 0
        var count: CGFloat = 0

        for row in 0..<Self.expeditionMapRows {
            let zone = DepthZone.zone(atY: Self.expeditionWorldY(forRow: row))
            guard canAccess(zone) else { continue }

            for column in 0..<Self.expeditionMapColumns {
                let key = Self.expeditionCellKey(column: column, row: row)
                total += (reveal[key] ?? 0).clamped(to: 0...1)
                count += 1
            }
        }

        guard count > 0 else { return 0 }
        return (total / count).clamped(to: 0...1)
    }

    func poiDiscoveryProgress(in region: Region) -> CGFloat {
        let reachablePOIs = reachablePOIs(in: region)
        guard !reachablePOIs.isEmpty else { return 1 }

        let discoveredCount = reachablePOIs.filter { isPOIDiscovered($0.key) }.count
        return (CGFloat(discoveredCount) / CGFloat(reachablePOIs.count)).clamped(to: 0...1)
    }

    private func hasReachablePOIs(in region: Region) -> Bool {
        !reachablePOIs(in: region).isEmpty
    }

    private func reachablePOIs(in region: Region) -> [WorldPOI] {
        WorldPOICatalog.pois(in: region, stats: self)
            .filter { canAccess($0.zone) }
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

    static func expeditionWorldY(forRow row: Int) -> CGFloat {
        let t = CGFloat(row).clamped(to: 0...CGFloat(expeditionMapRows - 1))
            / CGFloat(max(1, expeditionMapRows - 1))
        return World.floorY + (World.surfaceTopY - World.floorY) * t
    }

    static func expeditionColumn(forX x: CGFloat, in region: Region) -> Int {
        let xRange = region.playableXRange
        let width = max(1, xRange.upperBound - xRange.lowerBound)
        let t = ((x - xRange.lowerBound) / width).clamped(to: 0...1)
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
        addInventoryItem(id: id,
                         amount: 1,
                         memoryText: "Encontrou \(id)",
                         autosave: false)
    }

    func inventoryCount(for id: String) -> Int {
        max(0, inventoryItems[id] ?? 0)
    }

    func addInventoryItem(id: String,
                          amount: Int = 1,
                          memoryText: String? = nil,
                          autosave: Bool = true) {
        guard amount > 0 else { return }
        inventoryItems[id, default: 0] += amount
        if let memoryText {
            addMemory(memoryText)
        }
        if autosave {
            save(immediately: true)
        }
    }

    @discardableResult
    func spendInventoryItem(id: String,
                            amount: Int = 1,
                            autosave: Bool = true) -> Bool {
        guard amount > 0,
              inventoryCount(for: id) >= amount else { return false }
        let nextCount = inventoryCount(for: id) - amount
        if nextCount > 0 {
            inventoryItems[id] = nextCount
        } else {
            inventoryItems.removeValue(forKey: id)
        }
        if autosave {
            save(immediately: true)
        }
        return true
    }

    func discoverPOI(_ key: String) {
        discoveredPOIKeys.insert(key)
    }

    func isPOIDiscovered(_ key: String) -> Bool {
        discoveredPOIKeys.contains(key)
    }

    func visitPOI(_ key: String) {
        visitedPOIKeys.insert(key)
    }

    func isPOIVisited(_ key: String) -> Bool {
        visitedPOIKeys.contains(key)
    }

    func collectPOIReward(_ key: String) {
        collectedPOIRewardKeys.insert(key)
    }

    func isPOIRewardCollected(_ key: String) -> Bool {
        collectedPOIRewardKeys.contains(key)
    }

    func canActivateRepeatablePOIReward(_ key: String, at date: Date = Date()) -> Bool {
        (repeatablePOIRewardAvailableAtByKey[key] ?? .distantPast) <= date
    }

    func markRepeatablePOIRewardActivated(_ key: String,
                                          activeDuration: TimeInterval,
                                          cooldownDuration: TimeInterval? = nil,
                                          at date: Date = Date()) {
        let active = max(1, activeDuration)
        let cooldown = max(1, cooldownDuration ?? active)
        repeatablePOIRewardAvailableAtByKey[key] = date.addingTimeInterval(active + cooldown)
        pruneExpiredRepeatablePOIRewardCooldowns(at: date)
    }

    private func pruneExpiredRepeatablePOIRewardCooldowns(at date: Date = Date()) {
        repeatablePOIRewardAvailableAtByKey = repeatablePOIRewardAvailableAtByKey.filter { $0.value > date }
    }

    var canUseBabyGuaranteedRequest: Bool {
        phase == .baby && babyGuaranteedRequestsUsed < GameBalance.babyGuaranteedRequestCount
    }

    func consumeBabyGuaranteedRequestIfNeeded() {
        guard canUseBabyGuaranteedRequest else { return }
        babyGuaranteedRequestsUsed += 1
    }

    func markEntryTextSeen(region: Region, zone: DepthZone) -> Bool {
        let key = "\(region.id)|\(zone.storageKey)"
        guard !entryTextKeys.contains(key) else { return false }
        entryTextKeys.insert(key)
        return true
    }

    func ensureBaselineRegionAccess() {
        migrateRegionIdsIfNeeded()
        discoveredRegionIds.insert("recife_tropical")
    }

    func isRegionKnown(_ region: Region) -> Bool {
        if region.id == "recife_tropical" { return true }
        return discoveredRegionIds.contains(region.id)
    }

    func removeLegacyAutomaticRegionAccessIfUnused() {
        for regionId in ["floresta_kelp"] where shouldRemoveLegacyAutomaticAccess(for: regionId) {
            discoveredRegionIds.remove(regionId)
        }
    }

    func migrateRegionIdsIfNeeded() {
        guard !regionIdsMigratedThisSession else { return }
        regionIdsMigratedThisSession = true
        discoveredRegionIds = Set(discoveredRegionIds.map(RegionDiscoverySystem.canonicalRegionId))
        regionProgress = canonicalized(regionProgress) { max($0, $1) }
        expeditionRevealByRegion = canonicalized(expeditionRevealByRegion) { current, incoming in
            var merged = current
            for (key, value) in incoming {
                merged[key] = max(merged[key] ?? 0, value)
            }
            return merged
        }
        mapPositionByRegion = canonicalized(mapPositionByRegion) { current, _ in current }
        mapEntryPointByRegion = canonicalized(mapEntryPointByRegion) { current, _ in current }
        discoveryPointByRegion = canonicalized(discoveryPointByRegion) { current, _ in current }
        entryTextKeys = Set(entryTextKeys.map { key in
            let parts = key.split(separator: "|", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return key }
            return "\(RegionDiscoverySystem.canonicalRegionId(parts[0]))|\(parts[1])"
        })
        currentRegionId = RegionDiscoverySystem.canonicalRegionId(currentRegionId)
        pendingRegionDiscoveryId = pendingRegionDiscoveryId.map(RegionDiscoverySystem.canonicalRegionId)
        discoveryRouteRegionId = discoveryRouteRegionId.map(RegionDiscoverySystem.canonicalRegionId)
        readyRegionDiscoveryId = readyRegionDiscoveryId.map(RegionDiscoverySystem.canonicalRegionId)
        destinationRegionId = destinationRegionId.map(RegionDiscoverySystem.canonicalRegionId)
    }

    private func canonicalized<Value>(_ dictionary: [String: Value],
                                      merge: (Value, Value) -> Value) -> [String: Value] {
        var result: [String: Value] = [:]
        for (key, value) in dictionary {
            let canonicalKey = RegionDiscoverySystem.canonicalRegionId(key)
            if let existing = result[canonicalKey] {
                result[canonicalKey] = merge(existing, value)
            } else {
                result[canonicalKey] = value
            }
        }
        return result
    }

    private func shouldRemoveLegacyAutomaticAccess(for regionId: String) -> Bool {
        guard discoveredRegionIds.contains(regionId),
              currentRegionId != regionId,
              destinationRegionId != regionId,
              pendingRegionDiscoveryId != regionId,
              discoveryRouteRegionId != regionId,
              readyRegionDiscoveryId != regionId else { return false }
        guard (regionProgress[regionId] ?? 0) <= 0.001,
              mapPositionByRegion[regionId] == nil,
              (expeditionRevealByRegion[regionId] ?? [:]).isEmpty else { return false }

        let poiKeyPrefixes = ["\(regionId)_", "\(regionId)|"]
        let hasPOIState = discoveredPOIKeys.contains { key in poiKeyPrefixes.contains { key.hasPrefix($0) } }
            || visitedPOIKeys.contains { key in poiKeyPrefixes.contains { key.hasPrefix($0) } }
            || collectedPOIRewardKeys.contains { key in poiKeyPrefixes.contains { key.hasPrefix($0) } }
        return !hasPOIState
    }

    func hasDiscoveryLead(for region: Region) -> Bool {
        pendingRegionDiscoveryId == region.id
            || discoveryRouteRegionId == region.id
            || readyRegionDiscoveryId == region.id
    }

    func discoveryPoint(for destination: Region, from currentRegion: Region) -> CGPoint {
        if let point = discoveryPointByRegion[destination.id] {
            return point
        }

        var rng = StableMapRNG(seed: stableMapHash("\(currentRegion.id)|lead|\(destination.id)|\(Int(birthDate.timeIntervalSince1970))"))
        let xPadding: CGFloat = 720
        let innerMin = currentRegion.playableXRange.lowerBound + xPadding
        let innerMax = currentRegion.playableXRange.upperBound - xPadding
        let xRange = innerMin <= innerMax ? innerMin...innerMax : currentRegion.playableXRange
        let y = destination.entryZone.midY.clamped(to: DepthSystem.allowedYRange(for: self))
        let point = CGPoint(x: rng.next(in: xRange), y: y)
        discoveryPointByRegion[destination.id] = point
        return point
    }

    func addTimedBuff(_ kind: TimedBuffKind, title: String? = nil, duration: TimeInterval) {
        let buff = TimedBuff(kind: kind,
                             title: title ?? kind.title,
                             duration: duration)
        activeBuffs.removeAll { $0.kind == kind || $0.expiresAt <= Date() }
        activeBuffs.append(buff)
        addMemory("Efeito temporário: \(buff.title)")
    }

    func removeTimedBuff(_ kind: TimedBuffKind) {
        activeBuffs.removeAll { $0.kind == kind || $0.expiresAt <= Date() }
    }

    func hasActiveBuff(_ kind: TimedBuffKind) -> Bool {
        activeBuffs.contains { $0.kind == kind && $0.expiresAt > Date() }
    }

    private func pruneExpiredBuffs() {
        activeBuffs.removeAll { $0.expiresAt <= Date() }
    }

    func rememberMapPosition(_ point: CGPoint, in region: Region) {
        let x = point.x.clamped(to: region.playableXRange)
        let y = point.y.clamped(to: World.floorY...World.surfaceTopY)
        mapPositionByRegion[region.id] = CGPoint(x: x, y: y)
    }

    func savedMapPosition(for region: Region) -> CGPoint? {
        mapPositionByRegion[region.id]
    }

    func entryPoint(for region: Region) -> CGPoint {
        if let point = mapEntryPointByRegion[region.id] {
            return point
        }

        var rng = StableMapRNG(seed: stableMapHash("\(region.id)|entry|\(Int(birthDate.timeIntervalSince1970))"))
        let x = rng.next(in: region.playableXRange)
        let y = region.entryZone.midY.clamped(to: DepthSystem.allowedYRange(for: self))
        let point = CGPoint(x: x, y: y)
        mapEntryPointByRegion[region.id] = point
        return point
    }

    private struct StableMapRNG {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0xD1B5_4A32_D192_ED03 : seed
        }

        mutating func nextInt() -> UInt64 {
            state = state &* 2862933555777941757 &+ 3037000493
            return state
        }

        mutating func next(in range: ClosedRange<CGFloat>) -> CGFloat {
            let unit = CGFloat(nextInt() % 10_000) / 10_000
            return range.lowerBound + (range.upperBound - range.lowerBound) * unit
        }
    }

    private func stableMapHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
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
                return "A sereia nada mais rápido e leva menos tempo para explorar e viajar."
            case .shellGain:
                return "Aumenta a quantidade de conchas recebidas nas ações."
            case .feeding:
                return "A sereia demora mais para sentir fome."
            case .energy:
                return "A energia diminui mais devagar durante atividades."
            case .disposition:
                return "A sereia fica mais disposta e nega menos os seus pedidos."
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
        guard spendPearls(cost, autosave: false) else { return false }
        switch kind {
        case .speed: speedUpgradeLevel += 1
        case .shellGain: shellGainUpgradeLevel += 1
        case .feeding: feedingUpgradeLevel += 1
        case .energy: energyUpgradeLevel += 1
        case .disposition: dispositionUpgradeLevel += 1
        }
        addMemory("Cuidou de \(kind.title.lowercased()) no Refúgio")
        save(immediately: true)
        return true
    }

    var speedMultiplier: CGFloat {
        if cheatSuperSpeedEnabled { return 6 }
        let buff: CGFloat = hasActiveBuff(.swiftCurrent) ? 0.28 : 0
        return (1 + buff + CGFloat(speedUpgradeLevel) * 0.007).clamped(to: 1...1.9)
    }

    var explorationProgressMultiplier: CGFloat {
        if cheatSuperSpeedEnabled { return 4 }
        return (1 + CGFloat(speedUpgradeLevel) * 0.007).clamped(to: 1...1.7)
    }

    var shellRewardMultiplier: CGFloat {
        (0.45 + CGFloat(shellGainUpgradeLevel) * 0.02).clamped(to: 0.45...1.8)
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
    func spendPearls(_ amount: Int, autosave: Bool = true) -> Bool {
        guard amount > 0, pearls >= amount else { return false }
        pearls -= amount
        if autosave {
            save(immediately: true)
        }
        return true
    }

    @discardableResult
    func awardPearls(_ baseAmount: Int) -> Int {
        guard baseAmount > 0 else { return 0 }
        let amount = GameBalance.scaledPearlReward(baseAmount: baseAmount,
                                                   multiplier: shellRewardMultiplier)
        pearls += amount
        return amount
    }

    @discardableResult
    func awardChallengePearls(_ baseAmount: Int, points: Int) -> Int {
        guard baseAmount > 0 else { return 0 }
        let amount = GameBalance.scaledChallengePearlReward(baseAmount: baseAmount,
                                                            points: points,
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

        let moodTarget = ((100 - hunger) * 0.58 + energy * 0.30 + 12 + moodBoost)
            .clamped(to: 0...100)
        let moodRate = moodTarget < mood ? 0.055 * dispositionDrainMultiplier : 0.025
        mood += (moodTarget - mood) * min(1, dt * moodRate)
        mood = mood.clamped(to: 0...100)

        if moodBoost > 0 { moodBoost = max(0, moodBoost - dt * 0.4) }
        if moodBoost < 0 { moodBoost = min(0, moodBoost + dt * 0.4 * dispositionDrainMultiplier) }
        if scaredTimer > 0 { scaredTimer -= dt }
    }

    // MARK: - Persistência

    private static let saveKey = "EsterSave.v1"

    static func load() -> MermaidStats {
        if let activeSessionStats {
            return activeSessionStats
        }

        if let data = UserDefaults.standard.data(forKey: saveKey),
           let stats = try? JSONDecoder().decode(MermaidStats.self, from: data) {
            // garantias de base após migrações de mundo
            stats.unlock(.clear)
            stats.unlock(.shallow)
            stats.unlock(.mid)
            stats.ensureBaselineRegionAccess()
            stats.removeLegacyAutomaticRegionAccessIfUnused()
            if RegionDiscoverySystem.region(withId: stats.currentRegionId) == nil {
                stats.currentRegionId = "recife_tropical"
            }
            let range = World.floorY...World.surfaceTopY
            if !range.contains(stats.posY) || !(World.minX...World.maxX).contains(stats.posX) {
                stats.posX = World.startPosition.x
                stats.posY = World.startPosition.y
            }
            stats.applyBalanceMigrationIfNeeded()
            stats.ensureBaselineRegionAccess()
            stats.removeLegacyAutomaticRegionAccessIfUnused()
            activeSessionStats = stats
            return stats
        }
        let stats = MermaidStats()
        stats.ensureBaselineRegionAccess()
        activeSessionStats = stats
        return stats
    }

    func beginCheatSessionIfNeeded() {
        guard !cheatSessionPersistenceBlocked else { return }
        let previousSuperSpeed = cheatSuperSpeedEnabled
        let previousAlwaysAccept = cheatAlwaysAcceptCommandsEnabled
        let previousDepthAccess = cheatDepthAccessEnabled

        cheatSuperSpeedEnabled = false
        cheatAlwaysAcceptCommandsEnabled = false
        cheatDepthAccessEnabled = false
        lastSaved = Date()
        cheatSessionBaselineData = try? JSONEncoder().encode(self)
        cheatSessionPersistenceBlocked = true

        cheatSuperSpeedEnabled = previousSuperSpeed
        cheatAlwaysAcceptCommandsEnabled = previousAlwaysAccept
        cheatDepthAccessEnabled = previousDepthAccess

        if let cheatSessionBaselineData {
            UserDefaults.standard.set(cheatSessionBaselineData, forKey: MermaidStats.saveKey)
        }
    }

    func save(immediately: Bool = false) {
        if cheatSessionPersistenceBlocked {
            guard let cheatSessionBaselineData else { return }
            UserDefaults.standard.set(cheatSessionBaselineData, forKey: MermaidStats.saveKey)
            if immediately {
                _ = UserDefaults.standard.synchronize()
            }
            return
        }

        lastSaved = Date()
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: MermaidStats.saveKey)
            if immediately {
                _ = UserDefaults.standard.synchronize()
            }
        }
    }

    private func applyBalanceMigrationIfNeeded() {
        guard balanceVersion < GameBalance.currentVersion else { return }
        if phase == .baby {
            pearls = GameBalance.babyStartingPearls
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
