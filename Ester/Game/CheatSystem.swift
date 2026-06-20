//
//  CheatSystem.swift
//  Ester
//
//  Cheats digitados no campo de nome da sereia. Todo cheat precisa comecar
//  com "/c " para nao conflitar com nomes normais.
//

import Foundation
import CoreGraphics

enum CheatSystem {
    struct Suggestion {
        let code: String
        let description: String
    }

    private static let prefix = "/c "
    static let commandPrefix = prefix

    static let allSuggestions: [Suggestion] = [
        Suggestion(code: "help", description: "Mostra os cheats"),
        Suggestion(code: "superspeed", description: "Ativa supervelocidade"),
        Suggestion(code: "normalspeed", description: "Desliga supervelocidade"),
        Suggestion(code: "alwaysaccept", description: "Aceita todos os comandos"),
        Suggestion(code: "normalaccept", description: "Volta ao aceite normal"),
        Suggestion(code: "fullstatus", description: "Status cheio"),
        Suggestion(code: "addpearls500", description: "Adiciona conchas"),
        Suggestion(code: "sethunger0", description: "Define fome"),
        Suggestion(code: "setenergy100", description: "Define energia"),
        Suggestion(code: "setmood100", description: "Define disposicao"),
        Suggestion(code: "settrust100", description: "Define confianca"),
        Suggestion(code: "phasebaby", description: "Fase bebe"),
        Suggestion(code: "phasechild", description: "Fase crianca"),
        Suggestion(code: "phaseteen", description: "Fase adolescente"),
        Suggestion(code: "phaseyoung", description: "Fase jovem"),
        Suggestion(code: "phaseadult", description: "Fase adulta"),
        Suggestion(code: "unlockdepths", description: "Libera profundidades"),
        Suggestion(code: "unlockmaps", description: "Descobre mapas"),
        Suggestion(code: "revealmap", description: "Revela mapa atual"),
        Suggestion(code: "revealallmaps", description: "Revela todos os mapas"),
        Suggestion(code: "unlockall", description: "Libera tudo"),
        Suggestion(code: "unlockmapbirthwaters", description: "Descobre Birth Waters"),
        Suggestion(code: "unlockmapcalmgarden", description: "Descobre Calm Garden"),
        Suggestion(code: "unlockmapemeraldreef", description: "Descobre Emerald Reef"),
        Suggestion(code: "unlockmapgreatdelta", description: "Descobre Great Delta"),
        Suggestion(code: "unlockmapancientruins", description: "Descobre Ancient Ruins"),
        Suggestion(code: "unlockmaplivingabyss", description: "Descobre Living Abyss"),
        Suggestion(code: "unlockmapdistantsurface", description: "Descobre Distant Surface"),
        Suggestion(code: "unlockmapopenbluesea", description: "Descobre Open Blue Sea"),
        Suggestion(code: "unlockmapcrystalfields", description: "Descobre Crystal Fields"),
        Suggestion(code: "unlockmapcavemouth", description: "Descobre Cave Mouth"),
        Suggestion(code: "revealmapbirthwaters", description: "Revela Birth Waters"),
        Suggestion(code: "revealmapcalmgarden", description: "Revela Calm Garden"),
        Suggestion(code: "revealmapemeraldreef", description: "Revela Emerald Reef"),
        Suggestion(code: "revealmapgreatdelta", description: "Revela Great Delta"),
        Suggestion(code: "revealmapancientruins", description: "Revela Ancient Ruins"),
        Suggestion(code: "revealmaplivingabyss", description: "Revela Living Abyss"),
        Suggestion(code: "revealmapdistantsurface", description: "Revela Distant Surface"),
        Suggestion(code: "revealmapopenbluesea", description: "Revela Open Blue Sea"),
        Suggestion(code: "revealmapcrystalfields", description: "Revela Crystal Fields"),
        Suggestion(code: "revealmapcavemouth", description: "Revela Cave Mouth")
    ]

    static func isCheat(_ text: String) -> Bool {
        normalized(text).hasPrefix(prefix)
    }

    static func isCheatEntry(_ text: String) -> Bool {
        let value = normalized(text)
        return value == "/c" || value.hasPrefix(prefix)
    }

    static func suggestions(matching text: String) -> [Suggestion] {
        guard isCheatEntry(text) else { return [] }
        let value = normalized(text)
        let codeFragment: String
        if value.hasPrefix(prefix) {
            codeFragment = String(value.dropFirst(prefix.count))
        } else {
            codeFragment = ""
        }
        guard !codeFragment.isEmpty else { return allSuggestions }
        return allSuggestions.filter {
            $0.code.hasPrefix(codeFragment)
                || normalized($0.description).replacingOccurrences(of: " ", with: "").contains(codeFragment)
        }
    }

    static func run(_ rawText: String, context ctx: GameContext) -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isCheat(trimmed) else { return "" }

        let code = normalized(String(trimmed.dropFirst(prefix.count)))
        guard !code.isEmpty else {
            return "Use /c help para ver os cheats."
        }
        guard !code.contains(where: { $0.isWhitespace }) else {
            return "Cheat invalido: escreva o codigo em ingles e sem espacos."
        }

        let stats = ctx.stats!

        switch code {
        case "help":
            return "Cheats de sessao: superspeed, alwaysaccept, fullstatus, addpearls500, sethunger0, setenergy100, setmood100, settrust100, phaseadult, unlockdepths, unlockmaps, revealmap, revealallmaps, unlockall."
        case "superspeed":
            stats.beginCheatSessionIfNeeded()
            stats.cheatSuperSpeedEnabled = true
            stats.addMemory("Cheat usado: super speed")
            return "Cheat de sessao aplicado: super speed."
        case "normalspeed":
            stats.cheatSuperSpeedEnabled = false
            return "Cheat de sessao desligado: super speed."
        case "alwaysaccept":
            stats.beginCheatSessionIfNeeded()
            stats.cheatAlwaysAcceptCommandsEnabled = true
            stats.addMemory("Cheat usado: always accept")
            return "Cheat de sessao aplicado: always accept."
        case "normalaccept":
            stats.cheatAlwaysAcceptCommandsEnabled = false
            return "Cheat de sessao desligado: always accept."
        case "fullstatus":
            stats.beginCheatSessionIfNeeded()
            applyPerfectStatus(to: stats)
            stats.addMemory("Cheat usado: status")
            return "Cheat de sessao aplicado: status cheio."
        case "unlockdepths":
            stats.beginCheatSessionIfNeeded()
            applyAllDepthAccess(to: stats)
            applyPhase(.adult, context: ctx)
            stats.addMemory("Cheat usado: camadas liberadas")
            return "Cheat de sessao aplicado: todas as profundidades liberadas."
        case "unlockmaps":
            stats.beginCheatSessionIfNeeded()
            discoverAllRegions(stats)
            return "Cheat de sessao aplicado: todos os mapas descobertos."
        case "revealmap":
            let region = ctx.activeRegion ?? RegionDiscoverySystem.region(withId: stats.currentRegionId)
            guard let region else { return "Nenhum mapa ativo para revelar." }
            stats.beginCheatSessionIfNeeded()
            reveal(region, stats: stats)
            return "Cheat de sessao aplicado: minimapa atual revelado."
        case "revealallmaps":
            stats.beginCheatSessionIfNeeded()
            revealAllMaps(stats)
            return "Cheat de sessao aplicado: todos os minimapas revelados."
        case "unlockall":
            stats.beginCheatSessionIfNeeded()
            applyEverything(context: ctx)
            return "Cheat de sessao aplicado: tudo liberado."
        default:
            return runParameterized(code, context: ctx)
        }
    }

    private static func runParameterized(_ code: String, context ctx: GameContext) -> String {
        let stats = ctx.stats!

        if let amount = integerSuffix(in: code, prefix: "addpearls", fallback: 1_000) {
            let clamped = clamp(amount, to: 1...999_999)
            stats.beginCheatSessionIfNeeded()
            stats.pearls += clamped
            stats.addMemory("Cheat usado: conchas +\(GameUI.shellAmountText(clamped))")
            return "Cheat de sessao aplicado: conchas +\(GameUI.shellAmountText(clamped))."
        }
        if let value = numberSuffix(in: code, prefix: "sethunger", fallback: 0) {
            stats.beginCheatSessionIfNeeded()
            stats.hunger = value.clamped(to: 0...100)
            return "Cheat de sessao aplicado: fome \(Int(stats.hunger))."
        }
        if let value = numberSuffix(in: code, prefix: "setenergy", fallback: 100) {
            stats.beginCheatSessionIfNeeded()
            stats.energy = value.clamped(to: 0...100)
            return "Cheat de sessao aplicado: energia \(Int(stats.energy))."
        }
        if let value = numberSuffix(in: code, prefix: "setmood", fallback: 100) {
            stats.beginCheatSessionIfNeeded()
            stats.mood = value.clamped(to: 0...100)
            return "Cheat de sessao aplicado: disposicao \(Int(stats.mood))."
        }
        if let value = numberSuffix(in: code, prefix: "settrust", fallback: 100) {
            stats.beginCheatSessionIfNeeded()
            stats.trust = value.clamped(to: 0...100)
            return "Cheat de sessao aplicado: confianca \(Int(stats.trust))."
        }
        if let phase = phaseCode(code) {
            stats.beginCheatSessionIfNeeded()
            applyPhase(phase, context: ctx)
            stats.addMemory("Cheat usado: fase \(phase.displayName)")
            return "Cheat de sessao aplicado: fase \(phase.displayName)."
        }
        if let region = regionCode(code, prefix: "unlockmap") {
            stats.beginCheatSessionIfNeeded()
            discover(region, stats: stats)
            return "Cheat de sessao aplicado: \(region.name) descoberto."
        }
        if let region = regionCode(code, prefix: "revealmap") {
            stats.beginCheatSessionIfNeeded()
            discover(region, stats: stats)
            reveal(region, stats: stats)
            return "Cheat de sessao aplicado: \(region.name) revelado."
        }

        return "Cheat desconhecido. Use /c help."
    }

    private static func applyEverything(context ctx: GameContext) {
        let stats = ctx.stats!
        applyPerfectStatus(to: stats)
        applyAllDepthAccess(to: stats)
        applyPhase(.adult, context: ctx)
        discoverAllRegions(stats)
        revealAllMaps(stats)
        stats.pearls += 5_000
        stats.speedUpgradeLevel = 100
        stats.shellGainUpgradeLevel = 100
        stats.feedingUpgradeLevel = 100
        stats.energyUpgradeLevel = 100
        stats.dispositionUpgradeLevel = 100
        stats.cheatSuperSpeedEnabled = true
        stats.cheatAlwaysAcceptCommandsEnabled = true
        stats.babyGuaranteedRequestsUsed = 0
        stats.addMemory("Cheat usado: tudo liberado")
    }

    private static func applyPerfectStatus(to stats: MermaidStats) {
        stats.hunger = 0
        stats.energy = 100
        stats.mood = 100
        stats.trust = 100
        stats.curiosity = 100
        stats.scaredTimer = 0
        stats.moodBoost = 0
    }

    private static func applyPhase(_ phase: MermaidPhase, context ctx: GameContext) {
        let stats = ctx.stats!
        stats.phase = phase
        stats.phaseStartedAt = Date()
        if phase >= .baby {
            stats.hatchProgress = 1
        }
        unlockZonesAllowed(by: phase, stats: stats)

        guard let mermaid = ctx.mermaidEntity?.mermaid else { return }
        mermaid.base.setScale(phase.scale)
        if phase != .egg {
            mermaid.setForm(for: phase)
        }
    }

    private static func unlockZonesAllowed(by phase: MermaidPhase, stats: MermaidStats) {
        for zone in DepthZone.allCases where phase >= zone.minPhase {
            stats.unlock(zone)
            stats.setAdaptation(100, for: zone)
        }
    }

    private static func applyAllDepthAccess(to stats: MermaidStats) {
        for zone in DepthZone.allCases {
            stats.unlock(zone)
            stats.setAdaptation(100, for: zone)
        }
        stats.maxDepthMeters = max(stats.maxDepthMeters, abs(World.floorY))
    }

    private static func discoverAllRegions(_ stats: MermaidStats) {
        for region in RegionDiscoverySystem.all {
            discover(region, stats: stats)
        }
        stats.pendingRegionDiscoveryId = nil
        stats.discoveryRouteRegionId = nil
        stats.readyRegionDiscoveryId = nil
    }

    private static func discover(_ region: Region, stats: MermaidStats) {
        stats.discoveredRegionIds.insert(region.id)
        stats.regionProgress[region.id] = max(stats.regionProgress[region.id] ?? 0, 1)
        stats.addMemory("Cheat: descobriu \(region.name)")
    }

    private static func revealAllMaps(_ stats: MermaidStats) {
        discoverAllRegions(stats)
        for region in RegionDiscoverySystem.all {
            reveal(region, stats: stats)
        }
    }

    private static func reveal(_ region: Region, stats: MermaidStats) {
        var reveal: [String: CGFloat] = [:]
        for row in 0..<MermaidStats.expeditionMapRows {
            for column in 0..<MermaidStats.expeditionMapColumns {
                reveal[MermaidStats.expeditionCellKey(column: column, row: row)] = 1
            }
        }
        stats.expeditionRevealByRegion[region.id] = reveal
        stats.regionProgress[region.id] = 1
        for poi in WorldPOICatalog.pois(in: region, stats: stats) {
            stats.discoverPOI(poi.key)
            stats.revealExpeditionMap(in: region, near: poi.position)
        }
    }

    private static func phaseCode(_ code: String) -> MermaidPhase? {
        switch code {
        case "phasebaby": return .baby
        case "phasechild": return .child
        case "phaseteen": return .teen
        case "phaseyoung": return .young
        case "phaseadult": return .adult
        default: return nil
        }
    }

    private static func regionCode(_ code: String, prefix: String) -> Region? {
        guard code.hasPrefix(prefix), code.count > prefix.count else { return nil }
        let value = String(code.dropFirst(prefix.count))
        return RegionDiscoverySystem.all.first { region in
            regionAliases(for: region).contains(value)
        }
    }

    private static func regionAliases(for region: Region) -> Set<String> {
        switch region.id {
        case "nascente":
            return ["birthwaters", "birthwater"]
        case "jardim_calmo":
            return ["calmgarden"]
        case "recife":
            return ["emeraldreef", "reef"]
        case "delta":
            return ["greatdelta", "delta"]
        case "ruinas":
            return ["ancientruins", "ruins"]
        case "abismo_vivo":
            return ["livingabyss", "abyss"]
        case "superficie_distante":
            return ["distantsurface", "surface"]
        case "mar_azul_aberto":
            return ["openbluesea", "bluesea", "opensea"]
        case "campos_cristal":
            return ["crystalfields", "crystals"]
        case "cavernas":
            return ["cavemouth", "caves"]
        default:
            return []
        }
    }

    private static func numberSuffix(in code: String, prefix: String, fallback: CGFloat) -> CGFloat? {
        guard code.hasPrefix(prefix) else { return nil }
        let suffix = String(code.dropFirst(prefix.count))
        guard !suffix.isEmpty else { return fallback }
        guard let number = Double(suffix) else { return nil }
        return CGFloat(number)
    }

    private static func integerSuffix(in code: String, prefix: String, fallback: Int) -> Int? {
        guard code.hasPrefix(prefix) else { return nil }
        let suffix = String(code.dropFirst(prefix.count))
        guard !suffix.isEmpty else { return fallback }
        return Int(suffix)
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
