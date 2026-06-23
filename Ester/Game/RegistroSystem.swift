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

enum RegistroUnlockRequirement {
    case challengeFromSpecies(String)

    var displayText: String {
        switch self {
        case .challengeFromSpecies:
            return "Complete pela primeira vez um desafio entregue por esta espécie."
        }
    }

    var challengeGiverSpeciesId: String? {
        switch self {
        case .challengeFromSpecies(let speciesId):
            return speciesId
        }
    }
}

struct RegistroSpeciesDefinition {
    let species: AquaticSpecies
    let region: Region
    let unlockRequirement: RegistroUnlockRequirement
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
        unlockRequirement.displayText
    }
}

struct RegistroMermaidObservation {
    let id: String
    let title: String
    let body: String
    let unlocked: Bool
}

private struct RegistroMermaidObservationDefinition {
    let id: String
    let title: String
    let body: String
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

    private static let mermaidObservationDefinitions: [RegistroMermaidObservationDefinition] = [
        RegistroMermaidObservationDefinition(
            id: "primeiro_olhar",
            title: "Primeira observação",
            body: "Indivíduo central do estudo. A presença da sereia altera a rotina dos animais próximos e orienta toda a documentação do ecossistema."),
        RegistroMermaidObservationDefinition(
            id: "nado_inicial",
            title: "Nado e orientação",
            body: "Após sair do ovo, responde a direção, descanso e exploração com hesitações próprias. O vínculo muda a chance de aceitar comandos."),
        RegistroMermaidObservationDefinition(
            id: "alimentacao",
            title: "Alimentação",
            body: "Procura alimento quando a fome aumenta. Comer estabiliza energia e disposição antes de jornadas ou desafios."),
        RegistroMermaidObservationDefinition(
            id: "resposta_desafios",
            title: "Resposta a desafios",
            body: "Demonstra aprendizado quando resolve provas trazidas por criaturas. A primeira vitória com uma espécie documenta aquela ficha no Registro."),
        RegistroMermaidObservationDefinition(
            id: "exploracao",
            title: "Exploração",
            body: "A curiosidade cresce em regiões novas. Mapas, profundidades e encontros raros aumentam o diário de campo."),
        RegistroMermaidObservationDefinition(
            id: "crescimento",
            title: "Crescimento",
            body: "Mudanças de fase alteram acesso a zonas, ritmo de nado e autonomia diante de ambientes mais difíceis."),
        RegistroMermaidObservationDefinition(
            id: "preferencias",
            title: "Preferências",
            body: "Com vínculo alto, aceita melhor convites e responde com mais calma a recursos, brincadeiras e pausas.")
    ]

    static let validMermaidObservationIds = Set(mermaidObservationDefinitions.map(\.id))

    private static let speciesDefinitionsByRegionId: [String: [RegistroSpeciesDefinition]] = {
        var definitionsByRegionId: [String: [RegistroSpeciesDefinition]] = [:]
        for region in RegionDiscoverySystem.menuRegions {
            definitionsByRegionId[region.id] = AquaticSpeciesCatalog.species(for: region.id).map {
                definition(for: $0, region: region)
            }
        }
        return definitionsByRegionId
    }()

    private static let speciesDefinitions: [RegistroSpeciesDefinition] = {
        RegionDiscoverySystem.menuRegions.flatMap { region in
            speciesDefinitionsByRegionId[region.id] ?? []
        }
    }()

    private static let speciesDefinitionsById: [String: RegistroSpeciesDefinition] = {
        var definitionsById: [String: RegistroSpeciesDefinition] = [:]
        for definition in speciesDefinitions {
            #if DEBUG
            if definitionsById[definition.id] != nil {
                assertionFailure("Registro species id duplicado: \(definition.id)")
            }
            #endif
            if definitionsById[definition.id] == nil {
                definitionsById[definition.id] = definition
            }
        }
        return definitionsById
    }()

    private static let challengeUnlockDefinitionsByGiverSpeciesId: [String: RegistroSpeciesDefinition] = {
        var definitionsByGiverSpeciesId: [String: RegistroSpeciesDefinition] = [:]
        for definition in speciesDefinitions {
            guard let giverSpeciesId = definition.unlockRequirement.challengeGiverSpeciesId else { continue }
            #if DEBUG
            if definitionsByGiverSpeciesId[giverSpeciesId] != nil {
                assertionFailure("Registro challenge giver duplicado: \(giverSpeciesId)")
            }
            #endif
            if definitionsByGiverSpeciesId[giverSpeciesId] == nil {
                definitionsByGiverSpeciesId[giverSpeciesId] = definition
            }
        }
        return definitionsByGiverSpeciesId
    }()

    #if DEBUG
    private static let catalogDebugValidation: Void = {
        for region in RegionDiscoverySystem.menuRegions {
            let rawSpeciesCount = AquaticSpeciesCatalog.species(for: region.id).count
            let registroSpecies = speciesDefinitionsByRegionId[region.id] ?? []
            if rawSpeciesCount == 0 {
                assertionFailure("Registro sem especies para bioma: \(region.id)")
            }
            if registroSpecies.count != rawSpeciesCount {
                assertionFailure("Registro desalinhado em \(region.id): \(registroSpecies.count)/\(rawSpeciesCount)")
            }
        }

        for definition in speciesDefinitions {
            if definition.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                assertionFailure("Registro com species id vazio")
            }
            if definition.commonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                assertionFailure("Registro sem nome comum: \(definition.id)")
            }
            if definition.scientificName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                assertionFailure("Registro sem nome cientifico: \(definition.id)")
            }
            if definition.shortDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                definition.fieldObservation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                definition.naturalHistoryNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                assertionFailure("Registro com ficha incompleta: \(definition.id)")
            }
            guard let giverSpeciesId = definition.unlockRequirement.challengeGiverSpeciesId else {
                assertionFailure("Registro sem requisito de desafio: \(definition.id)")
                continue
            }
            guard let unlockTarget = challengeUnlockDefinitionsByGiverSpeciesId[giverSpeciesId] else {
                assertionFailure("Registro requisito sem alvo: \(giverSpeciesId)")
                continue
            }
            if unlockTarget.id != definition.id {
                assertionFailure("Registro requisito aponta para ficha errada: \(giverSpeciesId)")
            }
        }
    }()

    static func validateCatalogForDebug() {
        _ = catalogDebugValidation
    }
    #endif

    static func allSpecies() -> [RegistroSpeciesDefinition] {
        speciesDefinitions
    }

    static func species(in region: Region) -> [RegistroSpeciesDefinition] {
        speciesDefinitionsByRegionId[region.id] ?? []
    }

    static func definition(for speciesId: String) -> RegistroSpeciesDefinition? {
        speciesDefinitionsById[speciesId]
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

    static func challengeUnlockCandidate(giverSpeciesId: String?,
                                         stats: MermaidStats) -> RegistroSpeciesDefinition? {
        guard let giverSpeciesId,
              let definition = challengeUnlockDefinitionsByGiverSpeciesId[giverSpeciesId],
              !stats.isSpeciesRegistered(definition.id) else { return nil }
        return definition
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
        return mermaidObservationDefinitions.map { definition in
            RegistroMermaidObservation(id: definition.id,
                                       title: definition.title,
                                       body: definition.body,
                                       unlocked: known.contains(definition.id))
        }
    }

    private static func definition(for species: AquaticSpecies, region: Region) -> RegistroSpeciesDefinition {
        RegistroSpeciesDefinition(species: species,
                                  region: region,
                                  unlockRequirement: .challengeFromSpecies(species.id),
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

    private static let observationBySpeciesId: [String: String] = [
        "peixe_palhaco_comum": "O padrão em faixas torna o animal fácil de reconhecer entre corais e anêmonas.",
        "peixe_cirurgiao_azul": "Corpo comprimido e coloração azul intensa ajudam na identificação à distância.",
        "peixe_papagaio_arco_iris": "Boca forte e cores verdes/alaranjadas sugerem alimentação sobre algas e recifes.",
        "tartaruga_verde": "O casco é o principal marcador de campo; nadadeiras largas indicam deslocamento calmo.",
        "tartaruga_de_pente": "O casco é o principal marcador de campo; nadadeiras largas indicam deslocamento calmo.",
        "tartaruga_de_couro": "O casco escuro e o corpo oceânico ajudam a separar esta espécie das tartarugas recifais.",
        "peixe_lanterna": "Traços escuros, prateados ou luminosos ajudam a sobreviver na pouca luz.",
        "peixe_dragao_negro": "Traços escuros, prateados ou luminosos ajudam a sobreviver na pouca luz.",
        "peixe_vibora": "Traços escuros, prateados ou luminosos ajudam a sobreviver na pouca luz.",
        "peixe_machado_marinho": "Traços escuros, prateados ou luminosos ajudam a sobreviver na pouca luz."
    ]

    private static func observation(for species: AquaticSpecies) -> String {
        if let specific = observationBySpeciesId[species.id] { return specific }
        switch species.group {
        case .fish:
            return "Silhueta, cor e zona preferida ajudam a separar esta espécie de outros peixes do bioma."
        case .shark:
            return "Silhueta alongada, nadadeira dorsal e cauda forte indicam patrulha constante."
        case .ray:
            return "O corpo largo plana como uma asa, com cauda fina usada como estabilizador."
        case .mammal:
            return "Respiração aérea, corpo fusiforme ou arredondado e nadadeiras revelam grande mobilidade."
        case .reptile:
            return "Escamas, casco ou cauda forte são os principais marcadores durante observação em campo."
        case .crustacean, .arthropod:
            return "Antenas, patas e carapaça denunciam movimento lateral, defesa e coleta de alimento."
        case .mollusk:
            return "Concha, fixação ao substrato ou corpo macio revelam adaptação a superfícies estáveis."
        case .cephalopod:
            return "Braços e manchas cromáticas mudam a leitura do contorno durante aproximações."
        case .cnidarian:
            return "A campânula translúcida e os tentáculos pedem observação à distância."
        case .echinoderm:
            return "Forma radial ou espinhosa revela vida lenta, colada ao fundo do bioma."
        case .annelid:
            return "Segmentos e tubos revelam vida escondida em sedimentos ou fontes profundas."
        case .bird:
            return "Plumagem contrastante e asas em forma de nadadeiras transformam a ave em nadadora ágil."
        }
    }

    private static func scientificNote(for species: AquaticSpecies) -> String {
        "\(species.scientificName) é o nome usado no caderno para separar esta espécie de parentes parecidos durante a observação de campo."
    }

    private static let naturalHistoryBySpeciesId: [String: String] = [
        "peixe_palhaco_comum": "Vive perto de anêmonas e usa faixas claras sobre corpo laranja como sinal visual forte no recife.",
        "peixe_cirurgiao_azul": "Peixe de recife com corpo alto e comprimido; costuma circular entre corais e fendas em busca de alimento.",
        "peixe_papagaio_arco_iris": "Raspa algas e superfícies duras com boca forte, ajudando a renovar áreas do recife.",
        "peixe_borboleta_lavrado": "Cores contrastantes e corpo alto ajudam no reconhecimento rápido entre corais, sombras e outros peixes recifais.",
        "peixe_anjo_rainha": "Cores contrastantes e corpo alto ajudam no reconhecimento rápido entre corais, sombras e outros peixes recifais.",
        "garibaldi": "Peixe territorial de kelp, conhecido pela cor laranja viva e por defender pequenos trechos do fundo.",
        "cavalo_marinho_focinho_longo": "Nada devagar e se prende a estruturas com a cauda, preferindo abrigo entre raízes, algas ou corais.",
        "peixe_voador": "Usa nadadeiras peitorais largas para planar acima da superfície quando precisa escapar de predadores.",
        "peixe_lua": "Corpo circular e nadadeiras altas criam uma silhueta incomum em mar aberto.",
        "barracuda_grande": "Nadador veloz de mar aberto, com corpo alongado e cauda forte para perseguições longas.",
        "atum_albacora": "Nadador veloz de mar aberto, com corpo alongado e cauda forte para perseguições longas.",
        "atum_bonito": "Nadador veloz de mar aberto, com corpo alongado e cauda forte para perseguições longas.",
        "atum_rabilho": "Nadador veloz de mar aberto, com corpo alongado e cauda forte para perseguições longas.",
        "agulhao_vela": "Nadador veloz de mar aberto, com corpo alongado e cauda forte para perseguições longas.",
        "marlim_azul": "Nadador veloz de mar aberto, com corpo alongado e cauda forte para perseguições longas.",
        "espadarte": "Nadador veloz de mar aberto, com corpo alongado e cauda forte para perseguições longas.",
        "sardinha_europeia": "Forma grupos numerosos; no Registro, indica alimento importante para predadores maiores.",
        "arenque_atlantico": "Forma grupos numerosos; no Registro, indica alimento importante para predadores maiores.",
        "anchova_do_atlantico": "Forma grupos numerosos; no Registro, indica alimento importante para predadores maiores.",
        "tainha": "Forma grupos numerosos; no Registro, indica alimento importante para predadores maiores.",
        "tainha_estuarina": "Forma grupos numerosos; no Registro, indica alimento importante para predadores maiores.",
        "krill_antartico": "Forma grupos numerosos; no Registro, indica alimento importante para predadores maiores.",
        "tartaruga_verde": "Respira ar na superfície e, quando adulta, pasta em áreas rasas com algas e plantas marinhas.",
        "tartaruga_de_pente": "Tartaruga de recife com bico estreito, associada a fendas e alimento preso em estruturas duras.",
        "tartaruga_de_couro": "Tartaruga oceânica grande, especializada em longos deslocamentos e encontros com águas-vivas.",
        "tubarao_baleia": "Tubarão gigante filtrador; apesar do tamanho, a ficha marca comportamento ligado a alimento pequeno em suspensão.",
        "tubarao_frade": "Tubarão gigante filtrador; apesar do tamanho, a ficha marca comportamento ligado a alimento pequeno em suspensão.",
        "enguia_gulper": "Peixe profundo de boca expansível, preparado para encontros raros e alimento imprevisível."
    ]

    private static func naturalHistory(for species: AquaticSpecies) -> String {
        if let specific = naturalHistoryBySpeciesId[species.id] { return specific }
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

    private static let visualNotesBySpeciesId: [String: String] = [
        "peixe_palhaco_comum": "Peixe • laranja com faixas claras",
        "peixe_cirurgiao_azul": "Peixe • azul vivo e corpo comprimido",
        "peixe_papagaio_arco_iris": "Peixe • verde, laranja e boca marcada",
        "peixe_borboleta_lavrado": "Peixe • corpo alto com listras",
        "peixe_anjo_rainha": "Peixe • corpo alto com listras",
        "barracuda_grande": "Peixe • corpo longo e cauda forte",
        "agulhao_vela": "Peixe • corpo longo e bico evidente",
        "marlim_azul": "Peixe • corpo longo e bico evidente",
        "espadarte": "Peixe • corpo longo e bico evidente",
        "tartaruga_verde": "Réptil aquático • casco oval e nadadeiras",
        "tartaruga_de_pente": "Réptil aquático • casco oval e nadadeiras",
        "tartaruga_de_couro": "Réptil aquático • casco oval escuro e nadadeiras",
        "peixe_lanterna": "Peixe • pontos luminosos de águas profundas",
        "peixe_dragao_negro": "Peixe • pontos luminosos de águas profundas",
        "peixe_vibora": "Peixe • pontos luminosos de águas profundas",
        "pinguim_imperador": "Ave mergulhadora • preto e branco, nadadeiras laterais",
        "pinguim_adelia": "Ave mergulhadora • preto e branco, nadadeiras laterais"
    ]

    private static func visualNotes(for species: AquaticSpecies) -> String {
        if let specific = visualNotesBySpeciesId[species.id] { return specific }
        switch species.group {
        case .fish:
            return "Peixe • silhueta, cor e zona de nado"
        case .shark:
            return "Tubarão • dorsal triangular e guelras"
        case .ray:
            return "Raia • asas largas e cauda fina"
        case .mammal:
            return "Mamífero marinho • nadadeiras e respiração aérea"
        case .reptile:
            return "Réptil aquático • escamas, casco ou cauda forte"
        case .crustacean, .arthropod:
            return "\(species.group.registroDisplayName) • pinças, patas ou antenas"
        case .mollusk:
            return "Molusco • concha ou corpo macio"
        case .cephalopod:
            return "Cefalópode • braços, olhos grandes e manchas"
        case .cnidarian:
            return "Cnidário • campânula translúcida e tentáculos"
        case .echinoderm:
            return "Equinodermo • simetria radial"
        case .annelid:
            return "Anelídeo • segmentos e tubos"
        case .bird:
            return "Ave mergulhadora • plumagem contrastante"
        }
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
    private var scrollOffsets: [String: CGFloat] = [:]
    private var scrollMaxOffsets: [String: CGFloat] = [:]
    private var scrollViewFrames: [String: CGRect] = [:]
    private var activeScrollKey: String?
    private var lastScrollTouchY: CGFloat = 0

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
        #if DEBUG
        RegistroCatalog.validateCatalogForDebug()
        #endif
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
        scrollViewFrames.removeAll()
        scrollMaxOffsets.removeAll()

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

        let mermaidObservations = RegistroCatalog.mermaidObservations(for: stats)
        addNavRow(name: "registro_mermaid",
                  title: "Sereia",
                  detail: "\(mermaidObservations.filter(\.unlocked).count) notas",
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

        let art = makeStaticMermaidIcon(size: 106)
        art.position = CGPoint(x: center.x - width / 2 + 64, y: center.y + height / 2 - 72)
        art.zPosition = 5
        addChild(art)

        let title = makeLabel(stats.mermaidName, fontSize: 23, bold: true, color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: center.x - width / 2 + 124, y: center.y + height / 2 - 50)
        title.preferredMaxLayoutWidth = width - 142
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.zPosition = 5
        addChild(title)

        let detail = makeLabel("Objeto principal de estudo • Diário científico gradual",
                               fontSize: 13.4,
                               color: GameUI.mutedInk)
        detail.horizontalAlignmentMode = .left
        detail.position = CGPoint(x: title.position.x, y: title.position.y - 31)
        detail.preferredMaxLayoutWidth = width - 142
        detail.numberOfLines = 2
        detail.lineBreakMode = .byWordWrapping
        detail.zPosition = 5
        addChild(detail)

        let observations = RegistroCatalog.mermaidObservations(for: stats)
        let unlockedCount = observations.filter(\.unlocked).count
        let count = makeLabel("\(unlockedCount) de \(observations.count) observações",
                              fontSize: 13.2,
                              bold: true,
                              color: GameUI.coral)
        count.horizontalAlignmentMode = .left
        count.position = CGPoint(x: title.position.x, y: detail.position.y - 39)
        count.zPosition = 5
        addChild(count)

        let rowWidth = width - 42
        let rowHeight: CGFloat = 88
        let rowSpacing: CGFloat = 100
        let viewportTop = center.y + height / 2 - 188
        let viewportBottom = center.y - height / 2 + 22
        let viewportHeight = max(148, viewportTop - viewportBottom)
        let contentHeight = max(viewportHeight, CGFloat(observations.count) * rowSpacing)

        addScrollView(key: "registro_scroll_mermaid",
                      width: rowWidth,
                      height: viewportHeight,
                      center: CGPoint(x: center.x, y: (viewportTop + viewportBottom) / 2),
                      contentHeight: contentHeight,
                      tint: GameUI.coral) { content, contentHeight in
            let startY = contentHeight / 2 - rowSpacing / 2
            for (index, observation) in observations.enumerated() {
                addObservationRow(observation,
                                  width: rowWidth,
                                  height: rowHeight,
                                  center: CGPoint(x: 0, y: startY - CGFloat(index) * rowSpacing),
                                  parent: content)
            }
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
        let rowHeight: CGFloat = compact ? 52 : 56

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
                                   center: CGPoint,
                                   parent: SKNode) {
        let tint = observation.unlocked ? GameUI.coral : GameUI.mutedInk
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 8)
        bg.fillColor = observation.unlocked
            ? UIColor.white.withAlphaComponent(0.34)
            : GameUI.fadedPaper.withAlphaComponent(0.54)
        bg.strokeColor = tint.withAlphaComponent(observation.unlocked ? 0.34 : 0.20)
        bg.lineWidth = 1
        bg.position = center
        bg.zPosition = 4
        parent.addChild(bg)

        let seal = makeLabel(observation.unlocked ? "✓" : "?", fontSize: 18, bold: true, color: tint)
        seal.position = CGPoint(x: center.x - width / 2 + 24, y: center.y + 12)
        seal.zPosition = 5
        parent.addChild(seal)

        let title = makeLabel(observation.unlocked ? observation.title : "Observação bloqueada",
                              fontSize: 14,
                              bold: true,
                              color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: center.x - width / 2 + 52, y: center.y + 21)
        title.preferredMaxLayoutWidth = width - 66
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.zPosition = 5
        parent.addChild(title)

        let body = makeLabel(observation.unlocked ? observation.body : "Continue observando comportamento, crescimento e exploração.",
                             fontSize: 12.2,
                             color: GameUI.mutedInk)
        body.horizontalAlignmentMode = .left
        body.position = CGPoint(x: title.position.x, y: center.y - 6)
        body.preferredMaxLayoutWidth = width - 66
        body.numberOfLines = 3
        body.lineBreakMode = .byWordWrapping
        body.zPosition = 5
        parent.addChild(body)
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
                              fontSize: 12.0,
                              bold: true,
                              color: discovered ? GameUI.ink : GameUI.mutedInk)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -width / 2 + 58, y: 10)
        title.preferredMaxLayoutWidth = width - 66
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.name = actionName
        row.addChild(title)

        let detail = makeLabel(discovered ? "Ficha registrada • \(definition.category.registroDisplayName)" : "Vença um desafio da própria espécie para revelar",
                               fontSize: 10.2,
                               color: GameUI.mutedInk)
        detail.horizontalAlignmentMode = .left
        detail.position = CGPoint(x: title.position.x, y: -12)
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

        let viewportWidth = max(120, width - 18)
        let viewportHeight = max(120, height - 18)
        let compact = usesNarrowLayout || width < 340
        let bodyFont: CGFloat = compact ? 13.0 : 12.7
        let contentHeight = speciesDetailContentHeight(definition,
                                                       viewportWidth: viewportWidth,
                                                       viewportHeight: viewportHeight,
                                                       bodyFont: bodyFont,
                                                       discovered: discovered)

        addScrollView(key: "registro_scroll_species_\(definition.id)",
                      width: viewportWidth,
                      height: viewportHeight,
                      center: center,
                      contentHeight: contentHeight,
                      tint: tint) { content, contentHeight in
            let left = -viewportWidth / 2 + 16
            let right = viewportWidth / 2 - 16
            let top = contentHeight / 2 - 18
            let contentWidth = right - left
            let headerTextX = min(left + 110, right - 132)
            let headerWidth = max(124, right - headerTextX)

            let art = FishNode.makeSpeciesDisplayNode(species: definition.species,
                                                      discovered: discovered,
                                                      scale: compact ? 0.50 : 0.60)
            art.position = CGPoint(x: left + 50, y: top - 52)
            art.zPosition = 5
            content.addChild(art)

            let status = makeLabel(discovered ? "REGISTRADA" : "A DESCOBRIR",
                                   fontSize: 11.4,
                                   bold: true,
                                   color: tint)
            status.horizontalAlignmentMode = .left
            status.position = CGPoint(x: headerTextX, y: top - 16)
            status.zPosition = 5
            content.addChild(status)

            let titleText = discovered ? definition.commonName : "Espécie não registrada"
            let titleFont: CGFloat = compact ? 17.2 : 18.0
            let titleLineCount = estimateLineCount(titleText,
                                                   width: headerWidth,
                                                   fontSize: titleFont).clamped(to: 1...2)
            let title = makeLabel(titleText,
                                  fontSize: titleFont,
                                  bold: true,
                                  color: GameUI.ink)
            title.horizontalAlignmentMode = .left
            title.position = CGPoint(x: headerTextX, y: top - 46)
            title.preferredMaxLayoutWidth = headerWidth
            title.numberOfLines = titleLineCount
            title.lineBreakMode = .byWordWrapping
            title.zPosition = 5
            content.addChild(title)

            let identityText = discovered
                ? definition.scientificNote
                : "Nome científico e notas de campo ficam ocultos até a primeira conclusão."
            let identityLineCount = estimateLineCount(identityText,
                                                       width: headerWidth,
                                                       fontSize: bodyFont).clamped(to: 2...4)
            let identity = makeLabel(identityText,
                                     fontSize: bodyFont,
                                     color: GameUI.mutedInk)
            identity.horizontalAlignmentMode = .left
            identity.verticalAlignmentMode = .top
            identity.position = CGPoint(x: headerTextX,
                                        y: title.position.y - CGFloat(titleLineCount) * (titleFont + 4) - 8)
            identity.preferredMaxLayoutWidth = headerWidth
            identity.numberOfLines = identityLineCount
            identity.lineBreakMode = .byWordWrapping
            identity.zPosition = 5
            content.addChild(identity)

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

            var y = identity.position.y - CGFloat(identityLineCount) * (bodyFont + 4) - 18
            for line in lines {
                let metadataFont: CGFloat = compact ? 13.0 : 12.8
                let lineCount = estimateLineCount(line,
                                                  width: contentWidth,
                                                  fontSize: metadataFont).clamped(to: 1...2)
                let label = makeLabel(line,
                                      fontSize: metadataFont,
                                      bold: true,
                                      color: GameUI.ink)
                label.horizontalAlignmentMode = .left
                label.verticalAlignmentMode = .top
                label.position = CGPoint(x: left, y: y)
                label.preferredMaxLayoutWidth = contentWidth
                label.numberOfLines = lineCount
                label.lineBreakMode = .byWordWrapping
                label.zPosition = 5
                content.addChild(label)
                y -= CGFloat(lineCount) * (metadataFont + 4) + 12
            }

            y -= 10
            if discovered {
                y = addDetailBlock(to: content,
                                   title: "Resumo",
                                   body: definition.shortDescription,
                                   topY: y,
                                   x: left,
                                   width: contentWidth,
                                   tint: tint,
                                   bodyFont: bodyFont)
                y = addDetailBlock(to: content,
                                   title: "Observação",
                                   body: definition.fieldObservation,
                                   topY: y,
                                   x: left,
                                   width: contentWidth,
                                   tint: tint,
                                   bodyFont: bodyFont)
                y = addDetailBlock(to: content,
                                   title: "Nota de campo",
                                   body: definition.naturalHistoryNote,
                                   topY: y,
                                   x: left,
                                   width: contentWidth,
                                   tint: tint,
                                   bodyFont: bodyFont)
                y = addDetailBlock(to: content,
                                   title: "Papel no bioma",
                                   body: definition.biomeRole,
                                   topY: y,
                                   x: left,
                                   width: contentWidth,
                                   tint: tint,
                                   bodyFont: bodyFont)
                _ = addDetailBlock(to: content,
                                   title: "Leitura visual",
                                   body: definition.visualNotes,
                                   topY: y,
                                   x: left,
                                   width: contentWidth,
                                   tint: tint,
                                   bodyFont: bodyFont)
            } else {
                _ = addDetailBlock(to: content,
                                   title: "Pista",
                                   body: "A silhueta confirma que há algo para encontrar neste bioma, mas a ficha científica ainda está bloqueada.",
                                   topY: y,
                                   x: left,
                                   width: contentWidth,
                                   tint: tint,
                                   bodyFont: bodyFont)
            }
        }
    }

    @discardableResult
    private func addDetailBlock(to parent: SKNode,
                                title: String,
                                body: String,
                                topY: CGFloat,
                                x: CGFloat,
                                width: CGFloat,
                                tint: UIColor,
                                bodyFont: CGFloat) -> CGFloat {
        let lineCount = estimateLineCount(body, width: width, fontSize: bodyFont).clamped(to: 1...5)
        let lineHeight = bodyFont + 4
        let titleLabel = makeLabel(title.uppercased(),
                                   fontSize: 11.2,
                                   bold: true,
                                   color: tint)
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: x, y: topY)
        titleLabel.preferredMaxLayoutWidth = width
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.zPosition = 5
        parent.addChild(titleLabel)

        let bodyLabel = makeLabel(body,
                                  fontSize: bodyFont,
                                  color: GameUI.mutedInk)
        bodyLabel.horizontalAlignmentMode = .left
        bodyLabel.verticalAlignmentMode = .top
        bodyLabel.position = CGPoint(x: x, y: topY - 18)
        bodyLabel.preferredMaxLayoutWidth = width
        bodyLabel.numberOfLines = lineCount
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.zPosition = 5
        parent.addChild(bodyLabel)

        return topY - 34 - CGFloat(lineCount) * lineHeight
    }

    private func speciesDetailContentHeight(_ definition: RegistroSpeciesDefinition,
                                            viewportWidth: CGFloat,
                                            viewportHeight: CGFloat,
                                            bodyFont: CGFloat,
                                            discovered: Bool) -> CGFloat {
        let contentWidth = max(120, viewportWidth - 32)
        let headerWidth = max(124, contentWidth - 110)
        let compact = usesNarrowLayout || viewportWidth < 340
        let titleFont: CGFloat = compact ? 17.2 : 18.0
        let titleText = discovered ? definition.commonName : "Espécie não registrada"
        let titleLines = estimateLineCount(titleText,
                                           width: headerWidth,
                                           fontSize: titleFont).clamped(to: 1...2)
        let identityText = discovered
            ? definition.scientificNote
            : "Nome científico e notas de campo ficam ocultos até a primeira conclusão."
        let identityLines = estimateLineCount(identityText,
                                              width: headerWidth,
                                              fontSize: bodyFont).clamped(to: 2...4)
        var total: CGFloat = 162
            + CGFloat(max(0, titleLines - 1)) * (titleFont + 4)
            + CGFloat(max(0, identityLines - 2)) * (bodyFont + 4)
        total += discovered ? 66 : 94

        if discovered {
            total += detailBlockHeight(body: definition.shortDescription,
                                       width: contentWidth,
                                       bodyFont: bodyFont)
            total += detailBlockHeight(body: definition.fieldObservation,
                                       width: contentWidth,
                                       bodyFont: bodyFont)
            total += detailBlockHeight(body: definition.naturalHistoryNote,
                                       width: contentWidth,
                                       bodyFont: bodyFont)
            total += detailBlockHeight(body: definition.biomeRole,
                                       width: contentWidth,
                                       bodyFont: bodyFont)
            total += detailBlockHeight(body: definition.visualNotes,
                                       width: contentWidth,
                                       bodyFont: bodyFont)
        } else {
            total += detailBlockHeight(body: "A silhueta confirma que há algo para encontrar neste bioma, mas a ficha científica ainda está bloqueada.",
                                       width: contentWidth,
                                       bodyFont: bodyFont)
        }

        return max(viewportHeight, total + 32)
    }

    private func detailBlockHeight(body: String, width: CGFloat, bodyFont: CGFloat) -> CGFloat {
        let lines = estimateLineCount(body, width: width, fontSize: bodyFont).clamped(to: 1...5)
        return 34 + CGFloat(lines) * (bodyFont + 4)
    }

    private func estimateLineCount(_ text: String, width: CGFloat, fontSize: CGFloat) -> Int {
        let usableWidth = max(40, width)
        let charactersPerLine = max(10, Int(usableWidth / max(5.4, fontSize * 0.54)))
        return max(1, Int(ceil(CGFloat(text.count) / CGFloat(charactersPerLine))))
    }

    private func addScrollView(key: String,
                               width: CGFloat,
                               height: CGFloat,
                               center: CGPoint,
                               contentHeight: CGFloat,
                               tint: UIColor,
                               buildContent: (SKNode, CGFloat) -> Void) {
        let maxOffset = max(0, contentHeight - height)
        let offset = min(max(scrollOffsets[key] ?? 0, 0), maxOffset)
        scrollOffsets[key] = offset
        scrollMaxOffsets[key] = maxOffset
        scrollViewFrames[key] = CGRect(x: center.x - width / 2,
                                       y: center.y - height / 2,
                                       width: width,
                                       height: height)

        let crop = SKCropNode()
        crop.position = center
        crop.zPosition = 5

        let mask = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 6)
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask

        let content = SKNode()
        content.position = CGPoint(x: 0, y: (height - contentHeight) / 2 + offset)
        buildContent(content, contentHeight)
        crop.addChild(content)
        addChild(crop)

        guard maxOffset > 1 else { return }
        let trackHeight = max(32, height - 16)
        let track = SKShapeNode(rectOf: CGSize(width: 4, height: trackHeight), cornerRadius: 2)
        track.fillColor = GameUI.line.withAlphaComponent(0.13)
        track.strokeColor = .clear
        track.position = CGPoint(x: center.x + width / 2 - 7, y: center.y)
        track.zPosition = 7
        addChild(track)

        let thumbHeight = max(28, trackHeight * min(1, height / contentHeight))
        let travel = max(0, trackHeight - thumbHeight)
        let progress = maxOffset > 0 ? offset / maxOffset : 0
        let thumb = SKShapeNode(rectOf: CGSize(width: 4, height: thumbHeight), cornerRadius: 2)
        thumb.fillColor = tint.withAlphaComponent(0.55)
        thumb.strokeColor = .clear
        thumb.position = CGPoint(x: track.position.x,
                                 y: center.y + travel / 2 - progress * travel)
        thumb.zPosition = 8
        addChild(thumb)
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

    private func makeStaticMermaidIcon(size: CGFloat) -> SKNode {
        let node = SKNode()
        let halo = SKShapeNode(circleOfRadius: size * 0.45)
        halo.fillColor = GameUI.coral.withAlphaComponent(0.10)
        halo.strokeColor = GameUI.coral.withAlphaComponent(0.34)
        halo.lineWidth = 1.2
        node.addChild(halo)

        let mermaid = Mermaid()
        mermaid.setForm(for: stats.phase)
        mermaid.applyFacePose(.pose(for: .neutral), animated: false)
        stripActions(from: mermaid.base)

        let frame = mermaid.base.calculateAccumulatedFrame()
        let maxDimension = max(frame.width, frame.height)
        let fitScale = maxDimension > 0 ? (size * 0.86) / maxDimension : 0.18
        mermaid.base.setScale(fitScale)
        mermaid.base.position = CGPoint(x: -frame.midX * fitScale,
                                        y: -frame.midY * fitScale)
        mermaid.base.zPosition = 2
        node.addChild(mermaid.base)

        return node
    }

    private func stripActions(from node: SKNode) {
        node.removeAllActions()
        for child in node.children {
            stripActions(from: child)
        }
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

    private func scrollKey(containing point: CGPoint) -> String? {
        scrollViewFrames.first { entry in
            entry.value.contains(point) && (scrollMaxOffsets[entry.key] ?? 0) > 1
        }?.key
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        activeScrollKey = scrollKey(containing: point)
        lastScrollTouchY = point.y
        var node: SKNode? = atPoint(point)
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

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let key = activeScrollKey,
              let maxOffset = scrollMaxOffsets[key],
              maxOffset > 1 else { return }
        let point = touch.location(in: self)
        let deltaY = point.y - lastScrollTouchY
        guard abs(deltaY) > 0.5 else { return }
        let nextOffset = min(max((scrollOffsets[key] ?? 0) - deltaY, 0), maxOffset)
        guard abs(nextOffset - (scrollOffsets[key] ?? 0)) > 0.1 else {
            lastScrollTouchY = point.y
            return
        }
        scrollOffsets[key] = nextOffset
        lastScrollTouchY = point.y
        render()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeScrollKey = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeScrollKey = nil
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
