# Ester Sound Effect Map

Status: code integration is wired and all planned Freesound preview assets are downloaded with sidecar metadata.

Batch download after key is available:

```sh
node Tools/freesound.cjs batch Ester/Audio/freesound-plan.json
```

Preview the plan without a key:

```sh
node Tools/freesound.cjs batch Ester/Audio/freesound-plan.json --dry-run --limit 5
```

## Design Direction

- No music. Use short underwater SFX, soft UI Foley, and low-volume looping ambience.
- Keep clips short for mobile: UI 0.05-0.5s, gameplay rewards 0.2-1.2s, event stingers 0.6-2.5s, ambient loops 12-45s.
- Prefer `Creative Commons 0`; use `Attribution` only when sidecar metadata remains beside the downloaded file and attribution can be preserved.
- Sounds should feel cohesive: muffled water, bubbles, shell clicks, gentle currents, low filtered rumbles. Minigames avoid musical chimes/shimmers and use physical bubble/drop/splash effects only.
- Avoid audio spam: repeated hooks are throttled in `GameAudio` and use player pools only where simultaneous playback helps.

## Complete Event Mapping

| Area | Event | File | Intent |
| --- | --- | --- | --- |
| UI | Button tap | `Audio/UI/ui_tap_soft.mp3` | Soft shell tap for every active HUD/button press |
| UI | Accepted command/request | `Audio/UI/ui_confirm_chime.mp3` | Small positive confirmation |
| UI | Refused command/cooldown | `Audio/UI/ui_reject_soft.mp3` | Muted, non-punitive rejection |
| UI | Open modal/panel | `Audio/UI/ui_panel_open.mp3` | Watery page/panel reveal |
| UI | Close modal/panel | `Audio/UI/ui_panel_close.mp3` | Gentle close swish |
| UI | Upgrade purchased | `Audio/UI/ui_upgrade_buy.mp3` | Shell/chime reward |
| UI | Upgrade unavailable | `Audio/UI/ui_upgrade_fail.mp3` | Soft blocked feedback |
| World touch | Accepted tap target | `Audio/UI/world_tap_accept.mp3` | Small water ripple |
| World touch | Rejected tap target | `Audio/UI/world_tap_reject.mp3` | Lower ripple/click |
| Mermaid | Eats food | `Audio/Mermaid/mermaid_eat_soft.mp3` | Small underwater nibble/pop |
| Mermaid | Plays with fish | `Audio/Mermaid/mermaid_fish_play.mp3` | Friendly bubble flourish |
| Mermaid | Scared/avoid danger | `Audio/Mermaid/mermaid_scared_swish.mp3` | Quick startled water swish |
| Mermaid | Given space/resting | `Audio/Mermaid/mermaid_rest_sigh.mp3` | Very soft underwater exhale |
| Egg | Tap warms egg | `Audio/Progression/egg_tap_warm.mp3` | Warm glassy tap |
| Egg | Crack threshold | `Audio/Progression/egg_crack_soft.mp3` | Delicate shell crack |
| Egg | Hatch | `Audio/Progression/hatch_birth_shimmer.mp3` | Birth shimmer, no melody |
| Growth | Evolution | `Audio/Progression/evolution_shimmer.mp3` | Larger magical shimmer |
| Food/objective | Rare food appears | `Audio/World/food_rare_shimmer.mp3` | Locator sparkle |
| Rewards | Pearls/conches awarded | `Audio/World/pearl_reward_chime.mp3` | Shell reward chime |
| Depth | New depth record | `Audio/World/depth_record_low_chime.mp3` | Low discovery cue |
| Depth | Layer unlocked | `Audio/World/zone_unlock_wave.mp3` | Broad wave unlock |
| Region | Region discovered | `Audio/World/region_discover_chime.mp3` | Discovery cue |
| Travel | Destination selected | `Audio/World/travel_start_current.mp3` | Current begins |
| Travel | Destination reached | `Audio/World/travel_arrive_chime.mp3` | Arrival reward |
| Environment | Bubble burst event | `Audio/World/bubble_burst_cluster.mp3` | Bubble cluster near mermaid |
| Environment | Current rush event | `Audio/World/current_rush_short.mp3` | Muffled current shove |
| Environment | Rare/special fish passes | `Audio/World/rare_fish_pass.mp3` | Fast shimmer/swim-by |
| Environment | Big shadow | `Audio/World/big_shadow_rumble.mp3` | Low distant rumble |
| Environment | Boat passing | `Audio/World/boat_muffled_pass.mp3` | Filtered hull/water pass |
| Environment | Falling object splash | `Audio/World/falling_object_splash.mp3` | Small underwater splash/impact |
| Refuge | Portal opens | `Audio/Refuge/refuge_portal_open.mp3` | Magical water vortex |
| Refuge | Mermaid enters portal | `Audio/Refuge/refuge_portal_enter.mp3` | Portal whoosh/soft pull |
| Tide minigame | Select tile | `Audio/Minigames/tide_select_shell.mp3` | Tiny shell click |
| Tide minigame | Swap tiles | `Audio/Minigames/tide_swap_water.mp3` | Short water slide |
| Tide minigame | Invalid swap | `Audio/Minigames/tide_invalid_soft.mp3` | Muted no-match thud |
| Tide minigame | Match | `Audio/Minigames/tide_match_pop.mp3` | Bubble/shell pop |
| Tide minigame | Cascade combo | `Audio/Minigames/tide_cascade_chime.mp3` | Bubble cluster feedback, non-musical |
| Tide minigame | Goal complete | `Audio/Minigames/tide_goal_complete.mp3` | Water drop/pop success cue, non-musical |
| Minigames | Challenge opens | `Audio/Minigames/challenge_open.mp3` | Soft water open cue |
| Minigames | Challenge success | `Audio/Minigames/challenge_success.mp3` | Short splash/bubble result cue, non-musical |
| Minigames | Challenge fail/partial | `Audio/Minigames/challenge_fail_soft.mp3` | Encouraging incomplete cue |
| Bubble climb | Start climb | `Audio/Minigames/climb_start_bubble.mp3` | Bubble lift start |
| Bubble climb | Land on bubble | `Audio/Minigames/climb_land_bubble.mp3` | Soft elastic bubble contact |
| Bubble climb | Bounce | `Audio/Minigames/climb_bounce_pop.mp3` | Rising bubble bounce |
| Bubble climb | Platform pops | `Audio/Minigames/climb_platform_pop.mp3` | Small bubble pop cluster |
| Bubble climb | Goal complete | `Audio/Minigames/climb_goal_complete.mp3` | Water drop/pop success cue, non-musical |
| Ambience | Clear/surface layer | `Audio/Ambience/ambient_clear_water.mp3` | Bright, airy underwater bed |
| Ambience | Shallow/reef layer | `Audio/Ambience/ambient_shallow_reef.mp3` | Gentle bubbles and reef texture |
| Ambience | Mid/blue layers | `Audio/Ambience/ambient_mid_water.mp3` | Deeper filtered water movement |
| Ambience | Deep layer | `Audio/Ambience/ambient_deep_sea.mp3` | Low pressure, sparse movement |
| Ambience | Abyss layer | `Audio/Ambience/ambient_abyss_hum.mp3` | Quiet dark-water hum |
| Ambience | Refuge | `Audio/Ambience/ambient_refuge_soft.mp3` | Safe pocket-dimension shimmer |

## Intentionally Silent

- Continuous mermaid swimming: omitted to avoid constant looping noise and fatigue.
- Generic offscreen fish/food spawning: omitted unless rare/objective-related.
- HUD message appearance: omitted because messages can chain after gameplay events.
- Region menu scrolling: omitted to keep map reading calm.
- Passive ambient particles and visual-only background life: covered by ambience loops.
