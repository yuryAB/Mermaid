//
//  AudioManager.swift
//  Ester
//
//  Lightweight sound effect and ambience routing for gameplay feedback.
//

import AVFoundation
import Foundation
import QuartzCore
import UIKit

enum GameSound: String, CaseIterable {
    case uiTap
    case uiConfirm
    case uiReject
    case uiOpenPanel
    case uiClosePanel
    case uiUpgradeBuy
    case uiUpgradeFail

    case worldTapAccept
    case worldTapReject
    case mermaidEat
    case mermaidFishPlay
    case mermaidScared
    case mermaidRest

    case eggTap
    case eggCrack
    case hatch
    case evolution

    case foodRareSpawn
    case pearlReward
    case depthRecord
    case zoneUnlock
    case regionDiscover
    case travelStart
    case travelArrive

    case ambientBubbleBurst
    case currentRush
    case rareFishPass
    case bigShadow
    case boatMuffled
    case fallingSplash
    case refugePortalOpen
    case refugePortalEnter

    case tideSelect
    case tideSwap
    case tideInvalid
    case tideMatch
    case tideCascade
    case tideGoal
    case challengeOpen
    case challengeSuccess
    case challengeFail

    case climbStart
    case climbLand
    case climbBounce
    case climbPop
    case climbGoal
}

enum GameAmbience: String {
    case clear
    case shallow
    case mid
    case deep
    case abyss
    case refuge

    init(zone: DepthZone) {
        switch zone {
        case .surface, .clear:
            self = .clear
        case .shallow:
            self = .shallow
        case .mid, .blue:
            self = .mid
        case .deep:
            self = .deep
        case .abyss:
            self = .abyss
        }
    }
}

final class GameAudio {
    static let shared = GameAudio()

    private struct SoundSpec {
        let file: String
        let volume: Float
        let cooldown: TimeInterval
        let maxPolyphony: Int
    }

    private struct AmbienceSpec {
        let file: String
        let volume: Float
    }

    private let soundSpecs: [GameSound: SoundSpec] = [
        .uiTap: .init(file: "Audio/UI/ui_tap_soft.mp3", volume: 0.34, cooldown: 0.04, maxPolyphony: 3),
        .uiConfirm: .init(file: "Audio/UI/ui_confirm_chime.mp3", volume: 0.42, cooldown: 0.10, maxPolyphony: 2),
        .uiReject: .init(file: "Audio/UI/ui_reject_soft.mp3", volume: 0.36, cooldown: 0.35, maxPolyphony: 1),
        .uiOpenPanel: .init(file: "Audio/UI/ui_panel_open.mp3", volume: 0.35, cooldown: 0.18, maxPolyphony: 1),
        .uiClosePanel: .init(file: "Audio/UI/ui_panel_close.mp3", volume: 0.32, cooldown: 0.18, maxPolyphony: 1),
        .uiUpgradeBuy: .init(file: "Audio/UI/ui_upgrade_buy.mp3", volume: 0.48, cooldown: 0.12, maxPolyphony: 2),
        .uiUpgradeFail: .init(file: "Audio/UI/ui_upgrade_fail.mp3", volume: 0.36, cooldown: 0.35, maxPolyphony: 1),

        .worldTapAccept: .init(file: "Audio/UI/world_tap_accept.mp3", volume: 0.30, cooldown: 0.08, maxPolyphony: 3),
        .worldTapReject: .init(file: "Audio/UI/world_tap_reject.mp3", volume: 0.36, cooldown: 0.35, maxPolyphony: 1),
        .mermaidEat: .init(file: "Audio/Mermaid/mermaid_eat_soft.mp3", volume: 0.42, cooldown: 0.55, maxPolyphony: 2),
        .mermaidFishPlay: .init(file: "Audio/Mermaid/mermaid_fish_play.mp3", volume: 0.38, cooldown: 0.85, maxPolyphony: 2),
        .mermaidScared: .init(file: "Audio/Mermaid/mermaid_scared_swish.mp3", volume: 0.42, cooldown: 1.2, maxPolyphony: 1),
        .mermaidRest: .init(file: "Audio/Mermaid/mermaid_rest_sigh.mp3", volume: 0.30, cooldown: 5.0, maxPolyphony: 1),

        .eggTap: .init(file: "Audio/Progression/egg_tap_warm.mp3", volume: 0.36, cooldown: 0.22, maxPolyphony: 2),
        .eggCrack: .init(file: "Audio/Progression/egg_crack_soft.mp3", volume: 0.50, cooldown: 0.25, maxPolyphony: 2),
        .hatch: .init(file: "Audio/Progression/hatch_birth_shimmer.mp3", volume: 0.58, cooldown: 2.0, maxPolyphony: 1),
        .evolution: .init(file: "Audio/Progression/evolution_shimmer.mp3", volume: 0.58, cooldown: 2.0, maxPolyphony: 1),

        .foodRareSpawn: .init(file: "Audio/World/food_rare_shimmer.mp3", volume: 0.34, cooldown: 1.0, maxPolyphony: 1),
        .pearlReward: .init(file: "Audio/World/pearl_reward_chime.mp3", volume: 0.42, cooldown: 0.25, maxPolyphony: 3),
        .depthRecord: .init(file: "Audio/World/depth_record_low_chime.mp3", volume: 0.42, cooldown: 2.0, maxPolyphony: 1),
        .zoneUnlock: .init(file: "Audio/World/zone_unlock_wave.mp3", volume: 0.54, cooldown: 2.0, maxPolyphony: 1),
        .regionDiscover: .init(file: "Audio/World/region_discover_chime.mp3", volume: 0.52, cooldown: 2.0, maxPolyphony: 1),
        .travelStart: .init(file: "Audio/World/travel_start_current.mp3", volume: 0.36, cooldown: 1.0, maxPolyphony: 1),
        .travelArrive: .init(file: "Audio/World/travel_arrive_chime.mp3", volume: 0.48, cooldown: 1.0, maxPolyphony: 1),

        .ambientBubbleBurst: .init(file: "Audio/World/bubble_burst_cluster.mp3", volume: 0.28, cooldown: 1.3, maxPolyphony: 2),
        .currentRush: .init(file: "Audio/World/current_rush_short.mp3", volume: 0.46, cooldown: 3.0, maxPolyphony: 1),
        .rareFishPass: .init(file: "Audio/World/rare_fish_pass.mp3", volume: 0.34, cooldown: 1.8, maxPolyphony: 1),
        .bigShadow: .init(file: "Audio/World/big_shadow_rumble.mp3", volume: 0.42, cooldown: 4.0, maxPolyphony: 1),
        .boatMuffled: .init(file: "Audio/World/boat_muffled_pass.mp3", volume: 0.34, cooldown: 6.0, maxPolyphony: 1),
        .fallingSplash: .init(file: "Audio/World/falling_object_splash.mp3", volume: 0.42, cooldown: 1.5, maxPolyphony: 1),
        .refugePortalOpen: .init(file: "Audio/Refuge/refuge_portal_open.mp3", volume: 0.48, cooldown: 1.0, maxPolyphony: 1),
        .refugePortalEnter: .init(file: "Audio/Refuge/refuge_portal_enter.mp3", volume: 0.46, cooldown: 1.0, maxPolyphony: 1),

        .tideSelect: .init(file: "Audio/Minigames/tide_select_shell.mp3", volume: 0.26, cooldown: 0.05, maxPolyphony: 3),
        .tideSwap: .init(file: "Audio/Minigames/tide_swap_water.mp3", volume: 0.30, cooldown: 0.06, maxPolyphony: 3),
        .tideInvalid: .init(file: "Audio/Minigames/tide_invalid_soft.mp3", volume: 0.34, cooldown: 0.30, maxPolyphony: 1),
        .tideMatch: .init(file: "Audio/Minigames/tide_match_pop.mp3", volume: 0.38, cooldown: 0.08, maxPolyphony: 4),
        .tideCascade: .init(file: "Audio/Minigames/tide_cascade_chime.mp3", volume: 0.42, cooldown: 0.18, maxPolyphony: 3),
        .tideGoal: .init(file: "Audio/Minigames/tide_goal_complete.mp3", volume: 0.54, cooldown: 0.7, maxPolyphony: 1),
        .challengeOpen: .init(file: "Audio/Minigames/challenge_open.mp3", volume: 0.42, cooldown: 0.5, maxPolyphony: 1),
        .challengeSuccess: .init(file: "Audio/Minigames/challenge_success.mp3", volume: 0.54, cooldown: 0.8, maxPolyphony: 1),
        .challengeFail: .init(file: "Audio/Minigames/challenge_fail_soft.mp3", volume: 0.38, cooldown: 0.8, maxPolyphony: 1),

        .climbStart: .init(file: "Audio/Minigames/climb_start_bubble.mp3", volume: 0.42, cooldown: 0.5, maxPolyphony: 1),
        .climbLand: .init(file: "Audio/Minigames/climb_land_bubble.mp3", volume: 0.28, cooldown: 0.16, maxPolyphony: 2),
        .climbBounce: .init(file: "Audio/Minigames/climb_bounce_pop.mp3", volume: 0.30, cooldown: 0.16, maxPolyphony: 2),
        .climbPop: .init(file: "Audio/Minigames/climb_platform_pop.mp3", volume: 0.20, cooldown: 0.40, maxPolyphony: 1),
        .climbGoal: .init(file: "Audio/Minigames/climb_goal_complete.mp3", volume: 0.54, cooldown: 0.7, maxPolyphony: 1)
    ]

    private let ambienceSpecs: [GameAmbience: AmbienceSpec] = [
        .clear: .init(file: "Audio/Ambience/ambient_clear_water.mp3", volume: 0.16),
        .shallow: .init(file: "Audio/Ambience/ambient_shallow_reef.mp3", volume: 0.18),
        .mid: .init(file: "Audio/Ambience/ambient_mid_water.mp3", volume: 0.18),
        .deep: .init(file: "Audio/Ambience/ambient_deep_sea.mp3", volume: 0.20),
        .abyss: .init(file: "Audio/Ambience/ambient_abyss_hum.mp3", volume: 0.18),
        .refuge: .init(file: "Audio/Ambience/ambient_refuge_soft.mp3", volume: 0.18)
    ]

    private var playerPools: [GameSound: [AVAudioPlayer]] = [:]
    private var lastPlayedAt: [GameSound: TimeInterval] = [:]
    private var ambiencePlayers: [GameAmbience: AVAudioPlayer] = [:]
    private var activeAmbience: GameAmbience?
    private var configured = false

    private init() {}

    func configure() {
        guard !configured else { return }
        configured = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio remains best-effort; gameplay must never depend on it.
        }
    }

    func preloadCoreSounds() {
        [.uiTap, .uiConfirm, .uiReject, .worldTapAccept, .worldTapReject, .pearlReward].forEach {
            _ = pool(for: $0)
        }
    }

    func preloadClimbSounds() {
        [.climbStart, .climbLand, .climbBounce, .climbPop, .climbGoal, .challengeSuccess, .challengeFail].forEach {
            _ = pool(for: $0)
        }
    }

    func play(_ sound: GameSound, volumeMultiplier: Float = 1.0, cooldownOverride: TimeInterval? = nil) {
        guard let spec = soundSpecs[sound] else { return }
        let now = CACurrentMediaTime()
        let cooldown = cooldownOverride ?? spec.cooldown
        if let last = lastPlayedAt[sound], now - last < cooldown { return }
        guard let player = nextAvailablePlayer(for: sound) else { return }
        lastPlayedAt[sound] = now
        player.currentTime = 0
        player.volume = max(0, min(1, spec.volume * volumeMultiplier))
        player.play()
    }

    func updateOceanAmbience(for zone: DepthZone) {
        startAmbience(.init(zone: zone))
    }

    func startRefugeAmbience() {
        startAmbience(.refuge)
    }

    private func startAmbience(_ ambience: GameAmbience) {
        guard activeAmbience != ambience else { return }
        activeAmbience.flatMap { ambiencePlayers[$0] }?.setVolume(0, fadeDuration: 0.8)
        activeAmbience = ambience
        guard let player = ambiencePlayer(for: ambience),
              let spec = ambienceSpecs[ambience] else { return }
        player.numberOfLoops = -1
        player.volume = 0
        if !player.isPlaying { player.play() }
        player.setVolume(spec.volume, fadeDuration: 0.8)
    }

    private func nextAvailablePlayer(for sound: GameSound) -> AVAudioPlayer? {
        let players = pool(for: sound)
        guard !players.isEmpty else { return nil }
        return players.first(where: { !$0.isPlaying }) ?? players.first
    }

    private func pool(for sound: GameSound) -> [AVAudioPlayer] {
        if let pool = playerPools[sound] { return pool }
        guard let spec = soundSpecs[sound],
              let url = bundleURL(for: spec.file) else {
            playerPools[sound] = []
            return []
        }
        let players: [AVAudioPlayer] = (0..<spec.maxPolyphony).compactMap { _ in
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = spec.volume
                player.prepareToPlay()
                return player
            } catch {
                return nil
            }
        }
        playerPools[sound] = players
        return players
    }

    private func ambiencePlayer(for ambience: GameAmbience) -> AVAudioPlayer? {
        if let player = ambiencePlayers[ambience] { return player }
        guard let spec = ambienceSpecs[ambience],
              let url = bundleURL(for: spec.file) else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            ambiencePlayers[ambience] = player
            return player
        } catch {
            return nil
        }
    }

    private func bundleURL(for path: String) -> URL? {
        let nsPath = path as NSString
        let ext = nsPath.pathExtension
        let name = (nsPath.deletingPathExtension as NSString).lastPathComponent
        let subdirectory = nsPath.deletingLastPathComponent
        if let url = Bundle.main.url(forResource: name,
                                     withExtension: ext,
                                     subdirectory: subdirectory.isEmpty ? nil : subdirectory) {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }
}
