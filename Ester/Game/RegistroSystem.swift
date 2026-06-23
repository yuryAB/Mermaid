//
//  RegistroSystem.swift
//  Ester
//
//  Bestiario, enciclopedia marinha e diario cientifico da sereia.
//

import Foundation
import SpriteKit
import UIKit

struct RegistroProgressSnapshot {
    let discovered: Int
    let total: Int

    var fraction: CGFloat {
        guard total > 0 else { return 0 }
        return (CGFloat(discovered) / CGFloat(total)).clamped(to: 0...1)
    }

    var percentText: String {
        "\(Int((fraction * 100).rounded()))%"
    }

    var countText: String {
        "\(discovered) de \(total)"
    }
}

struct RegistroSpeciesDefinition {
    let species: AquaticSpecies
    let region: Region
    let shortDescription: String
    let fieldObservation: String
    let visualNotes: String
    let scientificNote: String
    let naturalHistoryNote: String
    let biomeRole: String

    var id: String { species.id }
    var commonName: String { species.commonName }
    var scientificName: String { species.scientificName }
    var category: AquaticAnimalGroup { species.group }
    var biomeName: String { region.name }
    var rowSummary: String { naturalHistoryNote }

    var zoneText: String {
        species.preferredZones.map(\.displayName).joined(separator: ", ")
    }

    var unlockRequirementText: String {
        "Complete pela primeira vez um desafio entregue por esta espécie."
    }
}

struct RegistroMermaidObservation {
    let id: String
    let title: String
    let body: String
    let unlocked: Bool
}

extension AquaticAnimalGroup {
    var registroDisplayName: String {
        switch self {
        case .fish: return "Peixe"
        case .shark: return "Tubarão"
        case .ray: return "Raia"
        case .mammal: return "Mamífero marinho"
        case .reptile: return "Réptil aquático"
        case .crustacean: return "Crustáceo"
        case .mollusk: return "Molusco"
        case .cephalopod: return "Cefalópode"
        case .cnidarian: return "Cnidário"
        case .echinoderm: return "Equinodermo"
        case .annelid: return "Anelídeo"
        case .bird: return "Ave mergulhadora"
        case .arthropod: return "Artrópode"
        }
    }

    var registroFallbackGlyph: String {
        switch self {
        case .fish: return "F"
        case .shark: return "T"
        case .ray: return "R"
        case .mammal: return "M"
        case .reptile: return "Q"
        case .crustacean: return "C"
        case .mollusk: return "O"
        case .cephalopod: return "P"
        case .cnidarian: return "J"
        case .echinoderm: return "*"
        case .annelid: return "~"
        case .bird: return "A"
        case .arthropod: return "A"
        }
    }

    var registroSymbolName: String {
        switch self {
        case .fish: return "fish.fill"
        case .shark: return "fish.fill"
        case .ray: return "triangle.fill"
        case .mammal: return "hare.fill"
        case .reptile: return "tortoise.fill"
        case .crustacean: return "ladybug.fill"
        case .mollusk: return "seal.fill"
        case .cephalopod: return "scribble.variable"
        case .cnidarian: return "aqi.medium"
        case .echinoderm: return "star.fill"
        case .annelid: return "waveform.path.ecg"
        case .bird: return "bird.fill"
        case .arthropod: return "ant.fill"
        }
    }

    var registroTint: UIColor {
        switch self {
        case .fish: return GameUI.accent
        case .shark: return UIColor(red: 0.26, green: 0.43, blue: 0.56, alpha: 1)
        case .ray: return UIColor(red: 0.46, green: 0.62, blue: 0.72, alpha: 1)
        case .mammal: return UIColor(red: 0.45, green: 0.53, blue: 0.58, alpha: 1)
        case .reptile: return GameUI.algae
        case .crustacean: return GameUI.coral
        case .mollusk: return UIColor(red: 0.70, green: 0.58, blue: 0.44, alpha: 1)
        case .cephalopod: return UIColor(red: 0.34, green: 0.62, blue: 0.68, alpha: 1)
        case .cnidarian: return UIColor(red: 0.76, green: 0.55, blue: 0.82, alpha: 1)
        case .echinoderm: return GameUI.gold
        case .annelid: return UIColor(red: 0.76, green: 0.30, blue: 0.28, alpha: 1)
        case .bird: return UIColor(red: 0.18, green: 0.27, blue: 0.34, alpha: 1)
        case .arthropod: return UIColor(red: 0.50, green: 0.36, blue: 0.28, alpha: 1)
        }
    }
}

enum RegistroCatalog {
    static let mermaidEntryId = "sereia"

    static func allSpecies() -> [RegistroSpeciesDefinition] {
        RegionDiscoverySystem.menuRegions.flatMap { species(in: $0) }
    }

    static func species(in region: Region) -> [RegistroSpeciesDefinition] {
        AquaticSpeciesCatalog.species(for: region.id).map { definition(for: $0, region: region) }
    }

    static func definition(for speciesId: String) -> RegistroSpeciesDefinition? {
        allSpecies().first { $0.id == speciesId }
    }

    static func progress(for stats: MermaidStats) -> RegistroProgressSnapshot {
        let total = allSpecies().count + 1
        let discoveredSpecies = allSpecies().filter { stats.isSpeciesRegistered($0.id) }.count
        return RegistroProgressSnapshot(discovered: discoveredSpecies + 1, total: total)
    }

    static func progress(in region: Region, stats: MermaidStats) -> RegistroProgressSnapshot {
        let entries = species(in: region)
        let discovered = entries.filter { stats.isSpeciesRegistered($0.id) }.count
        return RegistroProgressSnapshot(discovered: discovered, total: entries.count)
    }

    static func challengeUnlockCandidate(preferredSpeciesId: String?,
                                         regionId: String?,
                                         zone: DepthZone?,
                                         stats: MermaidStats) -> RegistroSpeciesDefinition? {
        if let preferredSpeciesId,
           let preferred = definition(for: preferredSpeciesId),
           !stats.isSpeciesRegistered(preferred.id) {
            return preferred
        }

        let region = regionId
            .flatMap { RegionDiscoverySystem.region(withId: $0) }
            ?? RegionDiscoverySystem.region(withId: stats.currentRegionId)
            ?? RegionDiscoverySystem.menuRegions.first
        guard let region else { return nil }

        let candidates = species(in: region).filter { definition in
            guard !stats.isSpeciesRegistered(definition.id) else { return false }
            guard let zone else { return true }
            return definition.species.preferredZones.contains(zone)
        }
        return candidates.first ?? species(in: region).first { !stats.isSpeciesRegistered($0.id) }
    }

    @discardableResult
    static func syncAutomaticMermaidObservations(for stats: MermaidStats) -> Bool {
        var changed = false
        changed = stats.unlockMermaidObservation("primeiro_olhar") || changed
        if stats.phase != .egg {
            changed = stats.unlockMermaidObservation("nado_inicial") || changed
        }
        if stats.mealsEaten > 0 {
            changed = stats.unlockMermaidObservation("alimentacao") || changed
        }
        if stats.puzzlesSolved > 0 {
            changed = stats.unlockMermaidObservation("resposta_desafios") || changed
        }
        if stats.discoveredRegionIds.count > 1 || stats.maxDepthMeters > 100 {
            changed = stats.unlockMermaidObservation("exploracao") || changed
        }
        if stats.phase >= .child {
            changed = stats.unlockMermaidObservation("crescimento") || changed
        }
        if stats.trust >= 72 {
            changed = stats.unlockMermaidObservation("preferencias") || changed
        }
        return changed
    }

    static func mermaidObservations(for stats: MermaidStats) -> [RegistroMermaidObservation] {
        let known = stats.mermaidObservationIds
        return [
            RegistroMermaidObservation(
                id: "primeiro_olhar",
                title: "Primeira observação",
                body: "Indivíduo central do estudo. A presença da sereia altera a rotina dos animais próximos e orienta toda a documentação do ecossistema.",
                unlocked: known.contains("primeiro_olhar")),
            RegistroMermaidObservation(
                id: "nado_inicial",
                title: "Nado e orientação",
                body: "Após sair do ovo, responde a direção, descanso e exploração com hesitações próprias. O vínculo muda a chance de aceitar comandos.",
                unlocked: known.contains("nado_inicial")),
            RegistroMermaidObservation(
                id: "alimentacao",
                title: "Alimentação",
                body: "Procura alimento quando a fome aumenta. Comer estabiliza energia e disposição antes de jornadas ou desafios.",
                unlocked: known.contains("alimentacao")),
            RegistroMermaidObservation(
                id: "resposta_desafios",
                title: "Resposta a desafios",
                body: "Demonstra aprendizado quando resolve provas trazidas por criaturas. Cada vitória também expande o Registro do bioma.",
                unlocked: known.contains("resposta_desafios")),
            RegistroMermaidObservation(
                id: "exploracao",
                title: "Exploração",
                body: "A curiosidade cresce em regiões novas. Mapas, profundidades e encontros raros aumentam o diário de campo.",
                unlocked: known.contains("exploracao")),
            RegistroMermaidObservation(
                id: "crescimento",
                title: "Crescimento",
                body: "Mudanças de fase alteram acesso a zonas, ritmo de nado e autonomia diante de ambientes mais difíceis.",
                unlocked: known.contains("crescimento")),
            RegistroMermaidObservation(
                id: "preferencias",
                title: "Preferências",
                body: "Com vínculo alto, aceita melhor convites e responde com mais calma a recursos, brincadeiras e pausas.",
                unlocked: known.contains("preferencias"))
        ]
    }

    private static func definition(for species: AquaticSpecies, region: Region) -> RegistroSpeciesDefinition {
        RegistroSpeciesDefinition(species: species,
                                  region: region,
                                  shortDescription: description(for: species, region: region),
                                  fieldObservation: observation(for: species),
                                  visualNotes: visualNotes(for: species),
                                  scientificNote: scientificNote(for: species),
                                  naturalHistoryNote: naturalHistory(for: species),
                                  biomeRole: biomeRole(for: species, region: region))
    }

    private static func description(for species: AquaticSpecies, region: Region) -> String {
        switch species.group {
        case .fish:
            let zones = species.preferredZones.map(\.displayName).joined(separator: ", ")
            return "Peixe associado a \(region.name), observado principalmente em \(zones)."
        case .shark:
            return "Predador cartilaginoso de nado firme, importante para equilibrar a comunidade de \(region.name)."
        case .ray:
            return "Animal cartilaginoso de corpo achatado, adaptado a planar sobre areia, recife ou água aberta."
        case .mammal:
            return "Mamífero aquático que respira ar, alternando mergulhos e retornos à superfície."
        case .reptile:
            return "Réptil de vida aquática, ligado a respiração na superfície e deslocamento por nadadeiras ou cauda forte."
        case .crustacean:
            return "Invertebrado de carapaça rígida; usa patas, pinças ou antenas para explorar fendas e fundos."
        case .mollusk:
            return "Molusco de corpo macio, muitas vezes protegido por concha e ligado a superfícies duras."
        case .cephalopod:
            return "Cefalópode inteligente, com braços, olhos grandes e mudanças rápidas de cor ou textura."
        case .cnidarian:
            return "Animal gelatinoso com tentáculos, sensível a correntes e luz."
        case .echinoderm:
            return "Invertebrado radial do fundo, parte da limpeza lenta do habitat."
        case .annelid:
            return "Verme marinho segmentado, especializado em tubos, sedimentos ou fontes profundas."
        case .bird:
            return "Ave mergulhadora adaptada a nadar em águas frias e retornar à superfície para respirar."
        case .arthropod:
            return "Artrópode aquático de carapaça externa, registrado como relíquia viva do fundo raso."
        }
    }

    private static func observation(for species: AquaticSpecies) -> String {
        let name = species.commonName.lowercased()
        let id = species.id.lowercased()
        if id.contains("palhaco") {
            return "O padrão em faixas torna o animal fácil de reconhecer entre corais e anêmonas."
        }
        if id.contains("cirurgiao") {
            return "Corpo comprimido e coloração azul intensa ajudam na identificação à distância."
        }
        if id.contains("papagaio") {
            return "Boca forte e cores verdes/alaranjadas sugerem alimentação sobre algas e recifes."
        }
        if id.contains("tartaruga") || id.contains("jabuti") {
            return "O casco é o principal marcador de campo; nadadeiras largas indicam deslocamento calmo."
        }
        if id.contains("tubarao") {
            return "Silhueta alongada, nadadeira dorsal e cauda forte indicam patrulha constante."
        }
        if id.contains("arraia") || id.contains("raia") {
            return "O corpo largo plana como uma asa, com cauda fina usada como estabilizador."
        }
        if id.contains("polvo") || id.contains("lula") {
            return "Braços e manchas cromáticas mudam a leitura do contorno durante aproximações."
        }
        if id.contains("caranguejo") || id.contains("siri") || id.contains("lagosta") || id.contains("camarao") || id.contains("krill") {
            return "Antenas e patas pequenas denunciam movimentos laterais, defesa e coleta de alimento."
        }
        if id.contains("agua_viva") || id.contains("caravela") || id.contains("sifonoforo") {
            return "A campânula translúcida e os tentáculos pedem observação à distância."
        }
        if id.contains("estrela") || id.contains("ourico") || id.contains("pepino") {
            return "Forma radial ou espinhosa revela vida lenta, colada ao fundo do bioma."
        }
        if id.contains("baleia") || id.contains("golfinho") || id.contains("orca") || id.contains("boto") || id.contains("cachalote") {
            return "Respiração aérea, corpo fusiforme e nadadeiras revelam um mamífero de grande mobilidade."
        }
        if id.contains("foca") || id.contains("lontra") || id.contains("leao_marinho") || id.contains("peixe_boi") {
            return "Corpo arredondado e deslocamento flexível indicam mergulhos curtos e curiosos."
        }
        if id.contains("pinguim") {
            return "Plumagem contrastante e asas em forma de nadadeiras transformam a ave em nadadora ágil."
        }
        if name.contains("lanterna") || name.contains("dragão") || name.contains("vibora") || name.contains("machado") {
            return "Traços escuros, prateados ou luminosos ajudam a sobreviver na pouca luz."
        }
        return "Ficha preparada para receber novas notas de comportamento, distribuição e relação com a sereia."
    }

    private static func scientificNote(for species: AquaticSpecies) -> String {
        "\(species.scientificName) é o nome usado no caderno para separar esta espécie de parentes parecidos durante a observação de campo."
    }

    private static func naturalHistory(for species: AquaticSpecies) -> String {
        let id = species.id.lowercased()
        let name = species.commonName.lowercased()
        if id.contains("palhaco") {
            return "Vive perto de anêmonas e usa faixas claras sobre corpo laranja como sinal visual forte no recife."
        }
        if id.contains("cirurgiao") {
            return "Peixe de recife com corpo alto e comprimido; costuma circular entre corais e fendas em busca de alimento."
        }
        if id.contains("papagaio") {
            return "Raspa algas e superfícies duras com boca forte, ajudando a renovar áreas do recife."
        }
        if id.contains("borboleta") || id.contains("anjo") {
            return "Cores contrastantes e corpo alto ajudam no reconhecimento rápido entre corais, sombras e outros peixes recifais."
        }
        if id.contains("garibaldi") {
            return "Peixe territorial de kelp, conhecido pela cor laranja viva e por defender pequenos trechos do fundo."
        }
        if id.contains("cavalo_marinho") {
            return "Nada devagar e se prende a estruturas com a cauda, preferindo abrigo entre raízes, algas ou corais."
        }
        if id.contains("voador") {
            return "Usa nadadeiras peitorais largas para planar acima da superfície quando precisa escapar de predadores."
        }
        if id.contains("lua") && species.group == .fish {
            return "Corpo circular e nadadeiras altas criam uma silhueta incomum em mar aberto."
        }
        if id.contains("atum") || id.contains("marlim") || id.contains("agulhao") || id.contains("espadarte") || id.contains("barracuda") {
            return "Nadador veloz de mar aberto, com corpo alongado e cauda forte para perseguições longas."
        }
        if id.contains("sardinha") || id.contains("arenque") || id.contains("anchova") || id.contains("tainha") || id.contains("krill") {
            return "Forma grupos numerosos; no Registro, indica alimento importante para predadores maiores."
        }
        if id.contains("tartaruga_verde") {
            return "Respira ar na superfície e, quando adulta, pasta em áreas rasas com algas e plantas marinhas."
        }
        if id.contains("pente") {
            return "Tartaruga de recife com bico estreito, associada a fendas e alimento preso em estruturas duras."
        }
        if id.contains("couro") {
            return "Tartaruga oceânica grande, especializada em longos deslocamentos e encontros com águas-vivas."
        }
        if id.contains("tartaruga") || id.contains("jacare") || id.contains("crocodilo") || id.contains("anaconda") {
            return "Réptil que depende da superfície para respirar, mesmo quando passa longos períodos dentro d'água."
        }
        if id.contains("tubarao_baleia") || id.contains("tubarao_frade") {
            return "Tubarão gigante filtrador; apesar do tamanho, a ficha marca comportamento ligado a alimento pequeno em suspensão."
        }
        if id.contains("tubarao") {
            return "Predador cartilaginoso; guelras, nadadeira dorsal e cauda forte ajudam a registrar sua patrulha."
        }
        if id.contains("arraia") || id.contains("raia") || id.contains("peixe_serra") {
            return "Corpo achatado e nadadeiras largas favorecem planar sobre areia, lama ou água aberta."
        }
        if id.contains("polvo") {
            return "Cefalópode de braços flexíveis, olhos atentos e grande capacidade de mudar cor, postura e textura."
        }
        if id.contains("lula") {
            return "Cefalópode de nado ativo; tentáculos, olhos grandes e manchas rápidas ajudam a reconhecer aproximações."
        }
        if id.contains("caravela") || id.contains("agua_viva") || id.contains("sifonoforo") {
            return "Animal gelatinoso levado por correntes; tentáculos longos tornam a distância de observação parte da ficha."
        }
        if id.contains("estrela") || id.contains("ourico") || id.contains("pepino") {
            return "Invertebrado do fundo, lento e radial, útil para notar a saúde de superfícies e sedimentos."
        }
        if id.contains("caranguejo") || id.contains("siri") {
            return "Crustáceo de carapaça rígida; patas laterais, pinças e abrigo em fendas aparecem como sinais de campo."
        }
        if id.contains("lagosta") || id.contains("camarao") || id.contains("anfipode") || id.contains("isopode") {
            return "Crustáceo com antenas e carapaça; registra alimento, limpeza do fundo e vida em frestas."
        }
        if id.contains("ostra") || id.contains("mexilhao") || id.contains("abalone") {
            return "Molusco preso a superfícies; filtra partículas ou raspa alimento e deixa pistas em rochas e raízes."
        }
        if id.contains("verme") {
            return "Anelídeo de fundo profundo; vive em tubos e depende de condições muito específicas do habitat."
        }
        if id.contains("boto") || id.contains("golfinho") || id.contains("orca") {
            return "Mamífero social que respira ar; sons, retornos à superfície e curiosidade guiam a observação."
        }
        if id.contains("baleia") || id.contains("cachalote") {
            return "Mamífero de grande porte; alterna mergulhos longos com respirações na superfície."
        }
        if id.contains("foca") || id.contains("lontra") || id.contains("leao_marinho") || id.contains("peixe_boi") {
            return "Mamífero costeiro ou fluvial; mergulhos curtos e subidas para respirar ajudam a localizar o animal."
        }
        if id.contains("pinguim") {
            return "Ave que nada com asas transformadas em nadadeiras e volta à superfície para respirar."
        }
        if name.contains("lanterna") || name.contains("dragão") || name.contains("dragao") || name.contains("vibora") || name.contains("machado") {
            return "Peixe de pouca luz; corpo escuro, prateado ou luminoso reduz sua silhueta no profundo."
        }
        if id.contains("gulper") {
            return "Peixe profundo de boca expansível, preparado para encontros raros e alimento imprevisível."
        }
        switch species.group {
        case .fish:
            return "Peixe registrado pelas zonas preferidas, silhueta e relação com cardumes, abrigo ou alimento local."
        case .shark:
            return "Tubarão cartilaginoso; sua presença indica rotas de patrulha e equilíbrio entre presas do bioma."
        case .ray:
            return "Raia ou parente achatado; observa-se melhor pelo contorno largo e pela ligação com fundo ou coluna d'água."
        case .mammal:
            return "Mamífero aquático que precisa respirar ar, então sua ficha valoriza mergulhos, pausas e superfície."
        case .reptile:
            return "Réptil aquático de respiração aérea; casco, escamas ou cauda forte são marcas de identificação."
        case .crustacean:
            return "Crustáceo de carapaça externa, ligado a frestas, fundo e pequenos movimentos de coleta."
        case .mollusk:
            return "Molusco de corpo macio, muitas vezes protegido por concha ou fixo a superfícies."
        case .cephalopod:
            return "Cefalópode inteligente, reconhecido por braços, olhos grandes e mudanças rápidas de aparência."
        case .cnidarian:
            return "Cnidário gelatinoso, guiado por luz e correntes, com tentáculos como principal sinal visual."
        case .echinoderm:
            return "Equinodermo radial do fundo, importante para ler sedimento, rochas e micro-habitats."
        case .annelid:
            return "Anelídeo segmentado, associado a tubos, sedimentos ou fontes profundas."
        case .bird:
            return "Ave mergulhadora; respira na superfície e caça sob a água com movimentos rápidos."
        case .arthropod:
            return "Artrópode aquático com carapaça externa, registrado por rastros lentos no fundo raso."
        }
    }

    private static func biomeRole(for species: AquaticSpecies, region: Region) -> String {
        let zones = species.preferredZones.map(\.displayName).joined(separator: ", ")
        switch species.group {
        case .fish:
            return "Em \(region.name), ocupa \(zones) e ajuda a mostrar onde há abrigo, alimento ou passagem de cardumes."
        case .shark:
            return "Em \(region.name), funciona como sentinela de topo: sua rota sugere onde a cadeia alimentar está ativa."
        case .ray:
            return "Em \(region.name), conecta fundo e coluna d'água, levantando pistas de areia, lama ou plâncton."
        case .mammal:
            return "Em \(region.name), marca zonas de respiro e deslocamento; cada aparição liga superfície e profundidade."
        case .reptile:
            return "Em \(region.name), usa água e superfície, revelando áreas calmas para descanso, caça ou travessia."
        case .crustacean:
            return "Em \(region.name), trabalha perto do fundo, reciclando alimento pequeno e ocupando fendas."
        case .mollusk:
            return "Em \(region.name), registra superfícies estáveis: raízes, rochas, recifes ou fontes onde há partículas para filtrar."
        case .cephalopod:
            return "Em \(region.name), indica abrigo complexo e oportunidades de caça curta, camuflagem e fuga."
        case .cnidarian:
            return "Em \(region.name), revela a direção das correntes e a presença de alimento suspenso."
        case .echinoderm:
            return "Em \(region.name), lê a saúde do fundo por movimentos lentos, raspagem e ocupação de superfícies."
        case .annelid:
            return "Em \(region.name), aponta sedimentos ou fontes profundas com química própria."
        case .bird:
            return "Em \(region.name), liga céu, gelo e água rasa; seus mergulhos denunciam cardumes pequenos."
        case .arthropod:
            return "Em \(region.name), age como fóssil vivo do fundo, útil para notar áreas rasas preservadas."
        }
    }

    private static func visualNotes(for species: AquaticSpecies) -> String {
        let id = species.id.lowercased()
        var notes = [species.group.registroDisplayName]
        if id.contains("palhaco") { notes.append("laranja com faixas claras") }
        if id.contains("cirurgiao") { notes.append("azul vivo e corpo comprimido") }
        if id.contains("papagaio") { notes.append("verde, laranja e boca marcada") }
        if id.contains("borboleta") || id.contains("anjo") { notes.append("corpo alto com listras") }
        if id.contains("barracuda") || id.contains("agulhao") || id.contains("marlim") || id.contains("espadarte") { notes.append("corpo longo e bico/cauda fortes") }
        if id.contains("tubarao") { notes.append("dorsal triangular e guelras") }
        if id.contains("arraia") || id.contains("raia") { notes.append("asas largas e cauda fina") }
        if id.contains("tartaruga") { notes.append("casco oval e nadadeiras") }
        if id.contains("polvo") || id.contains("lula") { notes.append("braços, olhos grandes e manchas") }
        if id.contains("caranguejo") || id.contains("siri") || id.contains("lagosta") { notes.append("pinças, patas e antenas") }
        if id.contains("agua_viva") || id.contains("caravela") { notes.append("campânula translúcida e tentáculos") }
        if id.contains("estrela") || id.contains("ourico") { notes.append("simetria radial") }
        if id.contains("pinguim") { notes.append("preto e branco, nadadeiras laterais") }
        if id.contains("lanterna") || id.contains("dragao") || id.contains("vibora") { notes.append("pontos luminosos de águas profundas") }
        return notes.joined(separator: " • ")
    }
}

final class RegistroOverlay: SKNode {
    private let size: CGSize
    private let insets: UIEdgeInsets
    private let stats: MermaidStats
    private let onClose: () -> Void

    private var showingMermaid = true
    private var selectedRegionIndex = 0
    private var selectedSpeciesId: String?
    private var selectedSpeciesByRegionId: [String: String] = [:]
    private var speciesPage = 0
    private let speciesPerPage = 6

    init(size: CGSize,
         insets: UIEdgeInsets,
         stats: MermaidStats,
         onClose: @escaping () -> Void) {
        self.size = size
        self.insets = insets
        self.stats = stats
        self.onClose = onClose
        super.init()
        isUserInteractionEnabled = true
        if RegistroCatalog.syncAutomaticMermaidObservations(for: stats) {
            stats.save()
        }
        render()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var topInset: CGFloat { max(insets.top, 34) }
    private var bottomInset: CGFloat { max(insets.bottom, 14) }
    private var usesNarrowLayout: Bool { size.width < 620 }
    private var currentSpeciesPageSize: Int { usesNarrowLayout ? 4 : speciesPerPage }
    private var chapterCount: Int { RegionDiscoverySystem.menuRegions.count + 1 }
    private var currentChapterIndex: Int { showingMermaid ? 0 : selectedRegionIndex + 1 }

    private func render() {
        removeAllChildren()

        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillTexture = GameUI.paperTexture(size: CGSize(width: size.width * 2, height: size.height * 2),
                                                   base: GameUI.palePaper)
        backdrop.fillColor = .white
        backdrop.strokeColor = .clear
        addChild(backdrop)

        let top = size.height / 2 - topInset
        let bottom = -size.height / 2 + bottomInset
        let panelWidth = min(size.width - 24, 760)
        if usesNarrowLayout {
            let narrowWidth = min(max(size.width - 28, 286), 520)
            let chapterY = top - 112
            let contentTop = chapterY - 38
            let contentBottom = bottom + 10
            let contentHeight = max(320, contentTop - contentBottom)
            let contentCenterY = contentBottom + contentHeight / 2

            addHeader(top: top, width: narrowWidth, narrow: true)
            addCloseButton(top: top)
            addChapterSelector(width: narrowWidth,
                               center: CGPoint(x: 0, y: chapterY))

            if showingMermaid {
                addMermaidPanel(width: narrowWidth,
                                height: contentHeight,
                                center: CGPoint(x: 0, y: contentCenterY))
            } else {
                addBiomePanel(width: narrowWidth,
                              height: contentHeight,
                              center: CGPoint(x: 0, y: contentCenterY))
            }
            return
        }

        let leftWidth = min(190, max(142, panelWidth * 0.32))
        let gutter: CGFloat = 10
        let rightWidth = panelWidth - leftWidth - gutter
        let contentHeight = top - bottom - 112
        let leftX = -panelWidth / 2 + leftWidth / 2
        let rightX = leftX + leftWidth / 2 + gutter + rightWidth / 2
        let contentCenterY = bottom + contentHeight / 2 + 58

        addHeader(top: top, width: panelWidth, narrow: false)
        addCloseButton(top: top)
        addNavigationPanel(width: leftWidth,
                           height: contentHeight,
                           center: CGPoint(x: leftX, y: contentCenterY))

        if showingMermaid {
            addMermaidPanel(width: rightWidth,
                            height: contentHeight,
                            center: CGPoint(x: rightX, y: contentCenterY))
        } else {
            addBiomePanel(width: rightWidth,
                          height: contentHeight,
                          center: CGPoint(x: rightX, y: contentCenterY))
        }
    }

    private func addHeader(top: CGFloat, width: CGFloat, narrow: Bool) {
        let title = makeLabel("Registro", fontSize: narrow ? 23 : 24, bold: true, color: GameUI.ink)
        title.position = CGPoint(x: 0, y: top - 30)
        title.zPosition = 3
        addChild(title)

        let progress = RegistroCatalog.progress(for: stats)
        let subtitle = makeLabel("Conclusão global \(progress.countText) • \(progress.percentText)",
                                 fontSize: 12,
                                 color: GameUI.mutedInk)
        subtitle.position = CGPoint(x: 0, y: top - (narrow ? 58 : 56))
        subtitle.preferredMaxLayoutWidth = width - (narrow ? 112 : 80)
        subtitle.numberOfLines = 1
        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.zPosition = 3
        addChild(subtitle)

        let bar = progressBar(width: min(width - 80, 430),
                              height: 7,
                              fraction: progress.fraction,
                              tint: GameUI.accent)
        bar.position = CGPoint(x: 0, y: top - (narrow ? 84 : 78))
        bar.zPosition = 3
        addChild(bar)
    }

    private func addCloseButton(top: CGFloat) {
        let close = GameUI.pill(text: "Voltar",
                                fontSize: 12,
                                fill: [GameUI.coral.withAlphaComponent(0.92)],
                                strokeColor: GameUI.coral.withAlphaComponent(0.55),
                                minWidth: 86,
                                height: 34)
        close.name = "registro_close"
        close.position = CGPoint(x: size.width / 2 - 58, y: top - 34)
        close.zPosition = 6
        nameTree(close, "registro_close")
        addChild(close)
    }

    private func addChapterSelector(width: CGFloat, center: CGPoint) {
        let index = currentChapterIndex.clamped(to: 0...max(0, chapterCount - 1))
        let regions = RegionDiscoverySystem.menuRegions
        let tint: UIColor
        let titleText: String
        let detailText: String
        if index == 0 {
            let observations = RegistroCatalog.mermaidObservations(for: stats)
            tint = GameUI.coral
            titleText = "Sereia"
            detailText = "\(observations.filter(\.unlocked).count) de \(observations.count) notas"
        } else {
            let region = regions[index - 1]
            let progress = RegistroCatalog.progress(in: region, stats: stats)
            tint = region.tint
            titleText = region.name
            detailText = "\(progress.countText) • \(progress.percentText)"
        }

        let buttonWidth: CGFloat = 38
        let cardWidth = max(180, width - buttonWidth * 2 - 18)
        let previous = GameUI.pill(text: "‹",
                                   fontSize: 18,
                                   fill: [tint.withAlphaComponent(0.82)],
                                   strokeColor: tint.withAlphaComponent(0.38),
                                   minWidth: buttonWidth,
                                   height: 34)
        previous.position = CGPoint(x: center.x - width / 2 + buttonWidth / 2, y: center.y)
        previous.zPosition = 6
        previous.name = "registro_chapter_prev"
        nameTree(previous, "registro_chapter_prev")
        addChild(previous)

        let next = GameUI.pill(text: "›",
                               fontSize: 18,
                               fill: [tint.withAlphaComponent(0.82)],
                               strokeColor: tint.withAlphaComponent(0.38),
                               minWidth: buttonWidth,
                               height: 34)
        next.position = CGPoint(x: center.x + width / 2 - buttonWidth / 2, y: center.y)
        next.zPosition = 6
        next.name = "registro_chapter_next"
        nameTree(next, "registro_chapter_next")
        addChild(next)

        let bg = SKShapeNode(rectOf: CGSize(width: cardWidth, height: 42), cornerRadius: 8)
        bg.fillColor = UIColor.lerp(GameUI.paper, tint, 0.14)
        bg.strokeColor = tint.withAlphaComponent(0.28)
        bg.lineWidth = 1
        bg.position = center
        bg.zPosition = 4
        addChild(bg)

        let title = makeLabel(titleText, fontSize: 11.4, bold: true, color: GameUI.ink)
        title.position = CGPoint(x: center.x, y: center.y + 7)
        title.preferredMaxLayoutWidth = cardWidth - 22
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.zPosition = 5
        addChild(title)

        let detail = makeLabel(detailText, fontSize: 9.2, color: GameUI.mutedInk)
        detail.position = CGPoint(x: center.x, y: center.y - 10)
        detail.preferredMaxLayoutWidth = cardWidth - 22
        detail.numberOfLines = 1
        detail.lineBreakMode = .byTruncatingTail
        detail.zPosition = 5
        addChild(detail)
    }

    private func addNavigationPanel(width: CGFloat, height: CGFloat, center: CGPoint) {
        let panel = GameUI.card(size: CGSize(width: width, height: height),
                                cornerRadius: 9,
                                tint: GameUI.accent,
                                baseColors: [GameUI.paper])
        panel.position = center
        panel.zPosition = 2
        addChild(panel)

        let title = makeLabel("Caderno", fontSize: 13, bold: true, color: GameUI.ink)
        title.position = CGPoint(x: center.x, y: center.y + height / 2 - 24)
        title.zPosition = 4
        addChild(title)

        let rows = RegionDiscoverySystem.menuRegions
        let totalRows = rows.count + 1
        let rowHeight = min(CGFloat(40), max(CGFloat(28), (height - 62) / CGFloat(totalRows)))
        let startY = center.y + height / 2 - 56

        addNavRow(name: "registro_mermaid",
                  title: "Sereia",
                  detail: "\(stats.mermaidObservationIds.count) notas",
                  selected: showingMermaid,
                  tint: GameUI.coral,
                  width: width - 18,
                  height: rowHeight - 4,
                  position: CGPoint(x: center.x, y: startY))

        for (index, region) in rows.enumerated() {
            let progress = RegistroCatalog.progress(in: region, stats: stats)
            addNavRow(name: "registro_biome_\(index)",
                      title: region.name,
                      detail: "\(progress.countText) • \(progress.percentText)",
                      selected: !showingMermaid && index == selectedRegionIndex,
                      tint: region.tint,
                      width: width - 18,
                      height: rowHeight - 4,
                      position: CGPoint(x: center.x, y: startY - CGFloat(index + 1) * rowHeight))
        }
    }

    private func addNavRow(name: String,
                           title: String,
                           detail: String,
                           selected: Bool,
                           tint: UIColor,
                           width: CGFloat,
                           height: CGFloat,
                           position: CGPoint) {
        let node = SKNode()
        node.name = name
        node.position = position
        node.zPosition = 5
        addChild(node)

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 7)
        bg.fillColor = selected ? UIColor.lerp(GameUI.paper, tint, 0.20) : UIColor.white.withAlphaComponent(0.28)
        bg.strokeColor = selected ? tint.withAlphaComponent(0.72) : GameUI.line.withAlphaComponent(0.18)
        bg.lineWidth = selected ? 1.3 : 0.8
        bg.name = name
        node.addChild(bg)

        let marker = SKShapeNode(rectOf: CGSize(width: 4, height: height - 8), cornerRadius: 2)
        marker.fillColor = tint.withAlphaComponent(selected ? 0.82 : 0.36)
        marker.strokeColor = .clear
        marker.position = CGPoint(x: -width / 2 + 8, y: 0)
        marker.name = name
        node.addChild(marker)

        let label = makeLabel(title, fontSize: width < 160 ? 9.2 : 10.2, bold: true, color: GameUI.ink)
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: -width / 2 + 18, y: 6)
        label.preferredMaxLayoutWidth = width - 28
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.name = name
        node.addChild(label)

        let sub = makeLabel(detail, fontSize: 8.2, color: GameUI.mutedInk)
        sub.horizontalAlignmentMode = .left
        sub.position = CGPoint(x: -width / 2 + 18, y: -9)
        sub.preferredMaxLayoutWidth = width - 28
        sub.lineBreakMode = .byTruncatingTail
        sub.numberOfLines = 1
        sub.name = name
        node.addChild(sub)
    }

    private func addMermaidPanel(width: CGFloat, height: CGFloat, center: CGPoint) {
        addPanelBackground(width: width, height: height, center: center, tint: GameUI.coral)

        let art = makeMermaidStudyIcon(size: 94)
        art.position = CGPoint(x: center.x - width / 2 + 64, y: center.y + height / 2 - 72)
        art.zPosition = 5
        addChild(art)

        let title = makeLabel(stats.mermaidName, fontSize: 20, bold: true, color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: center.x - width / 2 + 124, y: center.y + height / 2 - 50)
        title.preferredMaxLayoutWidth = width - 142
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.zPosition = 5
        addChild(title)

        let detail = makeLabel("Objeto principal de estudo • Diário científico gradual",
                               fontSize: 11,
                               color: GameUI.mutedInk)
        detail.horizontalAlignmentMode = .left
        detail.position = CGPoint(x: title.position.x, y: title.position.y - 26)
        detail.preferredMaxLayoutWidth = width - 142
        detail.numberOfLines = 2
        detail.zPosition = 5
        addChild(detail)

        let observations = RegistroCatalog.mermaidObservations(for: stats)
        let unlockedCount = observations.filter(\.unlocked).count
        let count = makeLabel("\(unlockedCount) de \(observations.count) observações",
                              fontSize: 11,
                              bold: true,
                              color: GameUI.coral)
        count.horizontalAlignmentMode = .left
        count.position = CGPoint(x: title.position.x, y: detail.position.y - 30)
        count.zPosition = 5
        addChild(count)

        let rowWidth = width - 34
        let rowHeight = min(CGFloat(58), max(CGFloat(44), (height - 176) / CGFloat(observations.count)))
        let startY = center.y + height / 2 - 162
        for (index, observation) in observations.enumerated() {
            addObservationRow(observation,
                              width: rowWidth,
                              height: rowHeight - 6,
                              center: CGPoint(x: center.x, y: startY - CGFloat(index) * rowHeight))
        }
    }

    private func addBiomePanel(width: CGFloat, height: CGFloat, center: CGPoint) {
        let regions = RegionDiscoverySystem.menuRegions
        guard regions.indices.contains(selectedRegionIndex) else { return }
        let region = regions[selectedRegionIndex]
        let species = RegistroCatalog.species(in: region)
        let progress = RegistroCatalog.progress(in: region, stats: stats)
        let pageSize = currentSpeciesPageSize
        addPanelBackground(width: width, height: height, center: center, tint: region.tint)

        let title = makeLabel(region.name, fontSize: 19, bold: true, color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: center.x - width / 2 + 18, y: center.y + height / 2 - 34)
        title.preferredMaxLayoutWidth = width - 36
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.zPosition = 5
        addChild(title)

        let progressLine = makeLabel("\(progress.countText) espécies descobertas • \(progress.percentText)",
                                     fontSize: 11,
                                     bold: true,
                                     color: region.tint)
        progressLine.horizontalAlignmentMode = .left
        progressLine.position = CGPoint(x: title.position.x, y: title.position.y - 25)
        progressLine.zPosition = 5
        addChild(progressLine)

        let bar = progressBar(width: width - 36, height: 7, fraction: progress.fraction, tint: region.tint)
        bar.position = CGPoint(x: center.x, y: progressLine.position.y - 22)
        bar.zPosition = 5
        addChild(bar)

        let maxPage = max(0, Int(ceil(CGFloat(species.count) / CGFloat(pageSize))) - 1)
        speciesPage = speciesPage.clamped(to: 0...maxPage)
        let start = speciesPage * pageSize
        let pageSpecies = Array(species.dropFirst(start).prefix(pageSize))
        let storedSelection = selectedSpeciesByRegionId[region.id]
        if let selectedSpeciesId,
           pageSpecies.contains(where: { $0.id == selectedSpeciesId }) {
            selectedSpeciesByRegionId[region.id] = selectedSpeciesId
        } else if let storedSelection,
                  pageSpecies.contains(where: { $0.id == storedSelection }) {
            selectedSpeciesId = storedSelection
        } else {
            selectedSpeciesId = pageSpecies.first?.id
            if let selectedSpeciesId {
                selectedSpeciesByRegionId[region.id] = selectedSpeciesId
            }
        }

        let compact = usesNarrowLayout || width < 520
        let listWidth = compact ? width - 34 : min(width * 0.48, 240)
        let detailWidth = compact ? width - 34 : width - listWidth - 18
        let listX = compact ? center.x : center.x - width / 2 + 18 + listWidth / 2
        let detailX = compact ? center.x : listX + listWidth / 2 + 18 + detailWidth / 2
        let listTop = bar.position.y - 28
        let rowHeight: CGFloat = compact ? 39 : 48

        for (index, definition) in pageSpecies.enumerated() {
            addSpeciesRow(definition,
                          selected: definition.id == selectedSpeciesId,
                          width: listWidth,
                          height: rowHeight - 5,
                          center: CGPoint(x: listX, y: listTop - CGFloat(index) * rowHeight))
        }

        let controlsY: CGFloat
        let detailHeight: CGFloat
        let detailCenterY: CGFloat
        if compact {
            controlsY = listTop - CGFloat(max(1, pageSpecies.count)) * rowHeight - 18
            let detailTop = controlsY - 28
            let detailBottom = center.y - height / 2 + 14
            detailHeight = max(150, detailTop - detailBottom)
            detailCenterY = (detailTop + detailBottom) / 2
        } else {
            controlsY = center.y - height / 2 + 26
            detailHeight = max(190, height - 116)
            detailCenterY = center.y - 14
        }
        addPageControls(page: speciesPage,
                        maxPage: maxPage,
                        center: CGPoint(x: listX, y: controlsY),
                        width: listWidth)

        if let selectedSpeciesId,
           let selected = species.first(where: { $0.id == selectedSpeciesId }) {
            addSpeciesDetail(selected,
                             width: detailWidth,
                             height: detailHeight,
                             center: CGPoint(x: detailX, y: detailCenterY))
        }
    }

    private func addPanelBackground(width: CGFloat, height: CGFloat, center: CGPoint, tint: UIColor) {
        let panel = GameUI.card(size: CGSize(width: width, height: height),
                                cornerRadius: 9,
                                tint: tint,
                                baseColors: [GameUI.paper])
        panel.position = center
        panel.zPosition = 2
        addChild(panel)
    }

    private func addObservationRow(_ observation: RegistroMermaidObservation,
                                   width: CGFloat,
                                   height: CGFloat,
                                   center: CGPoint) {
        let tint = observation.unlocked ? GameUI.coral : GameUI.mutedInk
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 8)
        bg.fillColor = observation.unlocked
            ? UIColor.white.withAlphaComponent(0.34)
            : GameUI.fadedPaper.withAlphaComponent(0.54)
        bg.strokeColor = tint.withAlphaComponent(observation.unlocked ? 0.34 : 0.20)
        bg.lineWidth = 1
        bg.position = center
        bg.zPosition = 4
        addChild(bg)

        let seal = makeLabel(observation.unlocked ? "✓" : "?", fontSize: 14, bold: true, color: tint)
        seal.position = CGPoint(x: center.x - width / 2 + 20, y: center.y + 7)
        seal.zPosition = 5
        addChild(seal)

        let title = makeLabel(observation.unlocked ? observation.title : "Observação bloqueada",
                              fontSize: 11,
                              bold: true,
                              color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: center.x - width / 2 + 42, y: center.y + 11)
        title.preferredMaxLayoutWidth = width - 56
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.zPosition = 5
        addChild(title)

        let body = makeLabel(observation.unlocked ? observation.body : "Continue observando comportamento, crescimento e exploração.",
                             fontSize: 9.5,
                             color: GameUI.mutedInk)
        body.horizontalAlignmentMode = .left
        body.position = CGPoint(x: title.position.x, y: center.y - 10)
        body.preferredMaxLayoutWidth = width - 56
        body.numberOfLines = 2
        body.lineBreakMode = .byWordWrapping
        body.zPosition = 5
        addChild(body)
    }

    private func addSpeciesRow(_ definition: RegistroSpeciesDefinition,
                               selected: Bool,
                               width: CGFloat,
                               height: CGFloat,
                               center: CGPoint) {
        let discovered = stats.isSpeciesRegistered(definition.id)
        let actionName = "registro_species_\(definition.id)"
        let tint = discovered ? definition.category.registroTint : GameUI.mutedInk
        let row = SKNode()
        row.name = actionName
        row.position = center
        row.zPosition = 5
        addChild(row)

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 8)
        bg.fillColor = selected
            ? UIColor.lerp(GameUI.paper, tint, 0.18)
            : UIColor.white.withAlphaComponent(discovered ? 0.34 : 0.18)
        bg.strokeColor = selected ? tint.withAlphaComponent(0.70) : tint.withAlphaComponent(0.24)
        bg.lineWidth = selected ? 1.4 : 0.9
        bg.name = actionName
        row.addChild(bg)

        let icon = discovered
            ? FishNode.makeSpeciesDisplayNode(species: definition.species, discovered: true, scale: 0.34)
            : FishNode.makeSpeciesDisplayNode(species: definition.species, discovered: false, scale: 0.30)
        icon.position = CGPoint(x: -width / 2 + 28, y: 2)
        icon.zPosition = 2
        icon.name = actionName
        row.addChild(icon)

        let title = makeLabel(discovered ? definition.commonName : "Espécie não registrada",
                              fontSize: 9.5,
                              bold: true,
                              color: discovered ? GameUI.ink : GameUI.mutedInk)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -width / 2 + 56, y: 8)
        title.preferredMaxLayoutWidth = width - 66
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.name = actionName
        row.addChild(title)

        let detail = makeLabel(discovered ? definition.rowSummary : "Complete um desafio para revelar a ficha",
                               fontSize: 8.2,
                               color: GameUI.mutedInk)
        detail.horizontalAlignmentMode = .left
        detail.position = CGPoint(x: title.position.x, y: -9)
        detail.preferredMaxLayoutWidth = width - 66
        detail.numberOfLines = 1
        detail.lineBreakMode = .byTruncatingTail
        detail.name = actionName
        row.addChild(detail)
    }

    private func addSpeciesDetail(_ definition: RegistroSpeciesDefinition,
                                  width: CGFloat,
                                  height: CGFloat,
                                  center: CGPoint) {
        let discovered = stats.isSpeciesRegistered(definition.id)
        let tint = discovered ? definition.category.registroTint : GameUI.mutedInk
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 9)
        bg.fillColor = UIColor.white.withAlphaComponent(0.28)
        bg.strokeColor = tint.withAlphaComponent(0.30)
        bg.lineWidth = 1
        bg.position = center
        bg.zPosition = 4
        addChild(bg)

        let left = center.x - width / 2 + 14
        let right = center.x + width / 2 - 14
        let top = center.y + height / 2 - 14
        let bottom = center.y - height / 2 + 14
        let compact = usesNarrowLayout || width < 340

        let art = FishNode.makeSpeciesDisplayNode(species: definition.species,
                                                  discovered: discovered,
                                                  scale: compact ? 0.48 : 0.60)
        art.position = CGPoint(x: left + 42, y: top - 42)
        art.zPosition = 5
        addChild(art)

        let status = makeLabel(discovered ? "REGISTRADA" : "A DESCOBRIR",
                               fontSize: 9,
                               bold: true,
                               color: tint)
        status.horizontalAlignmentMode = .left
        status.position = CGPoint(x: left + 88, y: top - 13)
        status.zPosition = 5
        addChild(status)

        let title = makeLabel(discovered ? definition.commonName : "Espécie não registrada",
                              fontSize: compact ? 13.2 : 15.2,
                              bold: true,
                              color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: status.position.x, y: top - 37)
        title.preferredMaxLayoutWidth = max(120, right - title.position.x)
        title.numberOfLines = 2
        title.lineBreakMode = .byWordWrapping
        title.zPosition = 5
        addChild(title)

        let identityText = discovered
            ? definition.scientificNote
            : "Nome científico e notas de campo ficam ocultos até a primeira conclusão."
        let identity = makeLabel(identityText,
                                 fontSize: 9.0,
                                 color: GameUI.mutedInk)
        identity.horizontalAlignmentMode = .left
        identity.position = CGPoint(x: title.position.x, y: top - 70)
        identity.preferredMaxLayoutWidth = max(120, right - title.position.x)
        identity.numberOfLines = 2
        identity.lineBreakMode = .byWordWrapping
        identity.zPosition = 5
        addChild(identity)

        let lines: [String]
        if discovered {
            lines = [
                "Bioma: \(definition.biomeName) • \(definition.category.registroDisplayName)",
                "Zonas: \(definition.zoneText)"
            ]
        } else {
            lines = [
                "Bioma: \(definition.biomeName)",
                "Zonas prováveis: \(definition.zoneText)",
                definition.unlockRequirementText
            ]
        }

        var y = top - 112
        for (index, line) in lines.enumerated() {
            let label = makeLabel(line,
                                  fontSize: 9.2,
                                  bold: true,
                                  color: index < 3 ? GameUI.ink : GameUI.mutedInk)
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: left, y: y)
            label.preferredMaxLayoutWidth = width - 28
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            label.zPosition = 5
            addChild(label)
            y -= 20
        }

        if discovered {
            y -= 3
            if y > bottom + 48 {
                y = addDetailBlock(title: "Nota de campo",
                                   body: definition.naturalHistoryNote,
                                   topY: y,
                                   x: left,
                                   width: width - 28,
                                   tint: tint,
                                   maxBodyLines: compact ? 3 : 4)
            }
            if y > bottom + 44 {
                y = addDetailBlock(title: "Papel no bioma",
                                   body: definition.biomeRole,
                                   topY: y,
                                   x: left,
                                   width: width - 28,
                                   tint: tint,
                                   maxBodyLines: compact ? 3 : 4)
            }
            if y > bottom + 38 {
                _ = addDetailBlock(title: "Leitura visual",
                                   body: definition.visualNotes,
                                   topY: y,
                                   x: left,
                                   width: width - 28,
                                   tint: tint,
                                   maxBodyLines: compact ? 2 : 3)
            }
        } else if y > bottom + 52 {
            _ = addDetailBlock(title: "Pista",
                               body: "A silhueta confirma que há algo para encontrar neste bioma, mas a ficha científica ainda está bloqueada.",
                               topY: y - 4,
                               x: left,
                               width: width - 28,
                               tint: tint,
                               maxBodyLines: 3)
        }
    }

    @discardableResult
    private func addDetailBlock(title: String,
                                body: String,
                                topY: CGFloat,
                                x: CGFloat,
                                width: CGFloat,
                                tint: UIColor,
                                maxBodyLines: Int) -> CGFloat {
        let titleLabel = makeLabel(title.uppercased(),
                                   fontSize: 8.2,
                                   bold: true,
                                   color: tint)
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: x, y: topY)
        titleLabel.preferredMaxLayoutWidth = width
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.zPosition = 5
        addChild(titleLabel)

        let bodyLabel = makeLabel(body,
                                  fontSize: 9.0,
                                  color: GameUI.mutedInk)
        bodyLabel.horizontalAlignmentMode = .left
        bodyLabel.position = CGPoint(x: x, y: topY - 17)
        bodyLabel.preferredMaxLayoutWidth = width
        bodyLabel.numberOfLines = maxBodyLines
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.zPosition = 5
        addChild(bodyLabel)

        return topY - 23 - CGFloat(maxBodyLines) * 13
    }

    private func addPageControls(page: Int, maxPage: Int, center: CGPoint, width: CGFloat) {
        let prev = GameUI.pill(text: "‹",
                               fontSize: 18,
                               fill: [page > 0 ? GameUI.accent : GameUI.fadedPaper],
                               strokeColor: GameUI.accent.withAlphaComponent(0.35),
                               minWidth: 42,
                               height: 30)
        prev.position = CGPoint(x: center.x - width / 2 + 25, y: center.y)
        prev.zPosition = 6
        prev.name = "registro_prev"
        nameTree(prev, "registro_prev")
        addChild(prev)

        let label = makeLabel("\(page + 1)/\(maxPage + 1)", fontSize: 10, bold: true, color: GameUI.mutedInk)
        label.position = center
        label.zPosition = 6
        addChild(label)

        let next = GameUI.pill(text: "›",
                               fontSize: 18,
                               fill: [page < maxPage ? GameUI.accent : GameUI.fadedPaper],
                               strokeColor: GameUI.accent.withAlphaComponent(0.35),
                               minWidth: 42,
                               height: 30)
        next.position = CGPoint(x: center.x + width / 2 - 25, y: center.y)
        next.zPosition = 6
        next.name = "registro_next"
        nameTree(next, "registro_next")
        addChild(next)
    }

    private func progressBar(width: CGFloat, height: CGFloat, fraction: CGFloat, tint: UIColor) -> SKNode {
        let node = SKNode()
        let track = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        track.fillColor = GameUI.line.withAlphaComponent(0.12)
        track.strokeColor = GameUI.line.withAlphaComponent(0.18)
        track.lineWidth = 0.8
        node.addChild(track)

        let fillWidth = max(height, width * fraction)
        let fill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: height), cornerRadius: height / 2)
        fill.fillColor = tint.withAlphaComponent(0.78)
        fill.strokeColor = .clear
        fill.position = CGPoint(x: -width / 2 + fillWidth / 2, y: 0)
        fill.zPosition = 2
        node.addChild(fill)
        return node
    }

    private func makeMermaidStudyIcon(size: CGFloat) -> SKNode {
        let node = SKNode()
        let halo = SKShapeNode(circleOfRadius: size * 0.45)
        halo.fillColor = GameUI.coral.withAlphaComponent(0.10)
        halo.strokeColor = GameUI.coral.withAlphaComponent(0.34)
        halo.lineWidth = 1.2
        node.addChild(halo)

        let head = SKShapeNode(circleOfRadius: size * 0.12)
        head.fillColor = UIColor(red: 0.86, green: 0.64, blue: 0.54, alpha: 1)
        head.strokeColor = .clear
        head.position = CGPoint(x: -size * 0.10, y: size * 0.14)
        head.zPosition = 3
        node.addChild(head)

        let hair = SKShapeNode(ellipseOf: CGSize(width: size * 0.32, height: size * 0.22))
        hair.fillColor = GameUI.coral.withAlphaComponent(0.82)
        hair.strokeColor = .clear
        hair.position = CGPoint(x: -size * 0.13, y: size * 0.18)
        hair.zRotation = -0.25
        hair.zPosition = 2
        node.addChild(hair)

        let body = SKShapeNode(ellipseOf: CGSize(width: size * 0.18, height: size * 0.32))
        body.fillColor = UIColor(red: 0.78, green: 0.58, blue: 0.52, alpha: 1)
        body.strokeColor = .clear
        body.position = CGPoint(x: -size * 0.02, y: -size * 0.06)
        body.zRotation = -0.28
        node.addChild(body)

        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: size * 0.03, y: -size * 0.18))
        tailPath.addCurve(to: CGPoint(x: size * 0.31, y: -size * 0.24),
                          controlPoint1: CGPoint(x: size * 0.15, y: -size * 0.27),
                          controlPoint2: CGPoint(x: size * 0.23, y: -size * 0.12))
        tailPath.addCurve(to: CGPoint(x: size * 0.12, y: -size * 0.40),
                          controlPoint1: CGPoint(x: size * 0.31, y: -size * 0.36),
                          controlPoint2: CGPoint(x: size * 0.22, y: -size * 0.42))
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.strokeColor = GameUI.accent
        tail.lineWidth = max(5, size * 0.08)
        tail.lineCap = .round
        tail.fillColor = .clear
        tail.zPosition = 1
        node.addChild(tail)

        let fin = SKShapeNode(ellipseOf: CGSize(width: size * 0.22, height: size * 0.10))
        fin.fillColor = GameUI.accent.withAlphaComponent(0.70)
        fin.strokeColor = .clear
        fin.position = CGPoint(x: size * 0.18, y: -size * 0.39)
        fin.zRotation = -0.2
        node.addChild(fin)

        return node
    }

    private func makeLabel(_ text: String,
                           fontSize: CGFloat,
                           bold: Bool = false,
                           color: UIColor = GameUI.ink) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        return label
    }

    private func nameTree(_ node: SKNode, _ name: String) {
        node.name = name
        for child in node.children {
            nameTree(child, name)
        }
    }

    private func selectChapter(at rawIndex: Int) {
        let count = max(1, chapterCount)
        let index = ((rawIndex % count) + count) % count
        speciesPage = 0
        if index == 0 {
            showingMermaid = true
            selectedSpeciesId = nil
            return
        }

        let regionIndex = index - 1
        guard RegionDiscoverySystem.menuRegions.indices.contains(regionIndex) else { return }
        showingMermaid = false
        selectedRegionIndex = regionIndex
        let region = RegionDiscoverySystem.menuRegions[regionIndex]
        selectedSpeciesId = selectedSpeciesByRegionId[region.id]
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            if let name = current.name {
                if name == "registro_close" {
                    onClose()
                    return
                }
                if name == "registro_chapter_prev" {
                    selectChapter(at: currentChapterIndex - 1)
                    GameAudio.shared.play(.uiTap)
                    render()
                    return
                }
                if name == "registro_chapter_next" {
                    selectChapter(at: currentChapterIndex + 1)
                    GameAudio.shared.play(.uiTap)
                    render()
                    return
                }
                if name == "registro_mermaid" {
                    selectChapter(at: 0)
                    GameAudio.shared.play(.uiTap)
                    render()
                    return
                }
                if name.hasPrefix("registro_biome_"),
                   let index = Int(String(name.dropFirst("registro_biome_".count))),
                   RegionDiscoverySystem.menuRegions.indices.contains(index) {
                    selectChapter(at: index + 1)
                    GameAudio.shared.play(.uiTap)
                    render()
                    return
                }
                if name.hasPrefix("registro_species_") {
                    let speciesId = String(name.dropFirst("registro_species_".count))
                    if selectedSpeciesId == speciesId { return }
                    if RegionDiscoverySystem.menuRegions.indices.contains(selectedRegionIndex) {
                        let region = RegionDiscoverySystem.menuRegions[selectedRegionIndex]
                        selectedSpeciesByRegionId[region.id] = speciesId
                    }
                    showingMermaid = false
                    selectedSpeciesId = speciesId
                    GameAudio.shared.play(.uiTap)
                    render()
                    return
                }
                if name == "registro_prev" {
                    guard speciesPage > 0 else { return }
                    speciesPage -= 1
                    selectedSpeciesId = nil
                    GameAudio.shared.play(.uiTap)
                    render()
                    return
                }
                if name == "registro_next" {
                    let regions = RegionDiscoverySystem.menuRegions
                    guard regions.indices.contains(selectedRegionIndex) else { return }
                    let count = RegistroCatalog.species(in: regions[selectedRegionIndex]).count
                    let maxPage = max(0, Int(ceil(CGFloat(count) / CGFloat(currentSpeciesPageSize))) - 1)
                    guard speciesPage < maxPage else { return }
                    speciesPage += 1
                    selectedSpeciesId = nil
                    GameAudio.shared.play(.uiTap)
                    render()
                    return
                }
            }
            node = current.parent
        }
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
