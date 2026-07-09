//
//  VendorScreen.swift
//  Ester
//
//  Shared presentation scaffold for the refuge vendor NPCs (the Loja seller and
//  the Sala do professor). Both screens follow the same composition: a large NPC
//  framed in a dedicated "booth" at the top, a counter panel that deliberately
//  overlaps the lower part of the NPC (so the character reads as standing behind
//  the merchandise), a header with the screen title, a short description and the
//  player's Shell balance, a scalable row of category tabs, and a natively
//  scrolling list of entries. Each entry carries its own title and description.
//
//  This type owns all of the vendor UI structure and behaviour so the concrete
//  overlays (`RefugeStoreOverlay`, `RefugeEnhancementsOverlay`) stay thin: they
//  only translate their domain models (shop items / upgrades) into `VendorEntry`
//  values and react to selections. New categories or entries can be added purely
//  as data, without touching the layout.
//

import SpriteKit
import UIKit

/// A single interactive row on a vendor screen. Every entry has a title and a
/// concise description; `makeIcon` is `nil` for entries that should not show an
/// icon (e.g. professor upgrades) and non-nil for entries that must (shop items).
struct VendorEntry {
    let id: String
    let title: String
    let subtitle: String
    /// Two-line action label rendered on the trailing button, e.g. "80\nconchas".
    let actionText: String
    let actionEnabled: Bool
    let tint: UIColor
    /// Optional 0...1 progress rendered as a small growing bar (no numbers). Used
    /// for leveled entries such as upgrades; `nil` for one-off purchases.
    let progress: CGFloat?
    /// Builds a centered icon node sized to roughly `diameter` points, or `nil`
    /// when the entry should not display an icon.
    let makeIcon: ((CGFloat) -> SKNode)?

    init(id: String,
         title: String,
         subtitle: String,
         actionText: String,
         actionEnabled: Bool,
         tint: UIColor,
         progress: CGFloat? = nil,
         makeIcon: ((CGFloat) -> SKNode)? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.actionText = actionText
        self.actionEnabled = actionEnabled
        self.tint = tint
        self.progress = progress
        self.makeIcon = makeIcon
    }
}

/// A named group of entries. Entries are provided lazily so prices, levels and
/// availability are re-read every time the list is reloaded.
struct VendorCategory {
    let id: String
    let title: String
    let entries: () -> [VendorEntry]
}

/// Subtle idle-breathing flavour applied to the NPC artwork.
enum VendorBreath {
    case gentle // slow vertical stretch/compress (octopus)
    case sway   // vertical breath plus a faint side-to-side lean (seller)
}

/// Static configuration for a vendor screen.
struct VendorScreenConfig {
    let title: String
    let description: String
    let npcAssetName: String
    let breath: VendorBreath
    let closeTitle: String
    let categories: [VendorCategory]
    /// Current Shell balance, re-read on every reload.
    let balance: () -> Int
}

final class VendorScreenNode: SKNode {

    // MARK: Configuration & callbacks

    private let screenSize: CGSize
    private let insets: UIEdgeInsets
    private let config: VendorScreenConfig
    private let onClose: () -> Void
    private let onSelect: (_ categoryId: String, _ entryId: String) -> Void

    // MARK: Layout metrics (computed once in build)

    private var contentWidth: CGFloat = 0
    private var viewportRect: CGRect = .zero
    private var viewportCenter: CGPoint = .zero
    private var viewportWidth: CGFloat = 0
    private var viewportHeight: CGFloat = 0

    // MARK: Persistent nodes

    private let tabLayer = SKNode()
    private let crop = SKCropNode()
    private var contentNode = SKNode()
    private var thumbNode: SKShapeNode?
    private var balanceLabel: SKLabelNode!
    private var balancePill: SKNode?
    /// The trailing action button per entry id, so a tap can pop the right one.
    private var actionButtons: [String: SKNode] = [:]

    // MARK: Dynamic state

    private var selectedCategoryIndex = 0
    private var scrollOffset: CGFloat = 0
    private var scrollMaxOffset: CGFloat = 0
    private var contentHeight: CGFloat = 0
    private var thumbTravel: CGFloat = 0
    /// The balance currently shown in the pill; used to animate changes.
    private var displayedBalance = 0
    private var hasShownBalance = false
    /// True while a tapped entry's press animation resolves, to avoid re-entrancy.
    private var isResolvingEntry = false

    // MARK: Touch tracking

    private var isScrolling = false
    private var lastTouchY: CGFloat = 0
    private var touchStartPoint: CGPoint?
    private var pendingTapName: String?
    private var didMoveTouch = false

    init(size: CGSize,
         insets: UIEdgeInsets,
         config: VendorScreenConfig,
         onClose: @escaping () -> Void,
         onSelect: @escaping (_ categoryId: String, _ entryId: String) -> Void) {
        self.screenSize = size
        self.insets = insets
        self.config = config
        self.onClose = onClose
        self.onSelect = onSelect
        super.init()
        isUserInteractionEnabled = true
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Public

    /// Re-reads the balance and the current category's entries and rebuilds the
    /// tab strip and the scrolling list, preserving the scroll position.
    func reload() {
        refreshBalance()
        renderTabs()
        renderEntries(resetScroll: false)
    }

    // MARK: - Construction

    private func build() {
        contentWidth = min(screenSize.width - 32, 460)

        let topEdge = screenSize.height / 2 - insets.top
        let bottomEdge = -screenSize.height / 2 + insets.bottom

        buildBackdrop()

        // Vertical regions ---------------------------------------------------
        let closeCenterY = bottomEdge + 30
        let panelBottom = closeCenterY + 34
        // The NPC occupies the top band; clamp so it stays generous but leaves
        // room for the header on short screens.
        let panelTop = topEdge - min(max(screenSize.height * 0.34, 200), screenSize.height * 0.44)
        let panelWidth = min(screenSize.width - 12, contentWidth + 30)

        buildNPCBooth(topEdge: topEdge,
                      panelTop: panelTop,
                      panelWidth: panelWidth)

        buildHeader(topEdge: topEdge)

        buildCounterPanel(top: panelTop, bottom: panelBottom, width: panelWidth)

        // Tabs (only when there is more than one category) -------------------
        let hasTabs = config.categories.count > 1
        let tabsCenterY = panelTop - 26
        tabLayer.position = CGPoint(x: 0, y: tabsCenterY)
        tabLayer.zPosition = 14
        addChild(tabLayer)

        // Scroll viewport ----------------------------------------------------
        let viewportTop = hasTabs ? (tabsCenterY - 17 - 10) : (panelTop - 16)
        let viewportBottom = panelBottom + 14
        viewportWidth = contentWidth - 4
        viewportHeight = max(120, viewportTop - viewportBottom)
        viewportCenter = CGPoint(x: 0, y: viewportBottom + viewportHeight / 2)
        viewportRect = CGRect(x: viewportCenter.x - viewportWidth / 2,
                              y: viewportCenter.y - viewportHeight / 2,
                              width: viewportWidth,
                              height: viewportHeight)

        crop.position = viewportCenter
        crop.zPosition = 13
        let mask = SKShapeNode(rectOf: CGSize(width: viewportWidth, height: viewportHeight),
                               cornerRadius: 8)
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        addChild(crop)

        buildCloseButton(centerY: closeCenterY)

        renderTabs()
        renderEntries(resetScroll: true)
    }

    private func buildBackdrop() {
        let backdropSize = CGSize(width: screenSize.width * 2, height: screenSize.height * 2)
        let backdrop = SKShapeNode(rectOf: backdropSize)
        backdrop.fillTexture = GameUI.gradientTexture(size: backdropSize,
                                                       colors: [UIColor(red: 0.07, green: 0.24, blue: 0.36, alpha: 1),
                                                                UIColor(red: 0.05, green: 0.16, blue: 0.27, alpha: 1),
                                                                UIColor(red: 0.03, green: 0.10, blue: 0.19, alpha: 1)])
        backdrop.fillColor = .white
        backdrop.strokeColor = .clear
        backdrop.zPosition = 0
        addChild(backdrop)

        // A few slow rising bubbles for gentle life; purely decorative.
        let resetY = -screenSize.height / 2
        for i in 0..<6 {
            let bubble = SKShapeNode(circleOfRadius: .random(in: 3...8))
            bubble.fillColor = UIColor.white.withAlphaComponent(0.05)
            bubble.strokeColor = UIColor.white.withAlphaComponent(0.12)
            bubble.lineWidth = 1
            bubble.position = CGPoint(x: .random(in: -screenSize.width / 2...screenSize.width / 2),
                                      y: .random(in: -screenSize.height / 2...0))
            bubble.zPosition = 0.5
            addChild(bubble)
            let rise = SKAction.repeatForever(.sequence([
                .moveBy(x: .random(in: -18...18), y: screenSize.height, duration: Double.random(in: 10...15)),
                .run { [weak bubble] in bubble?.position.y = resetY }
            ]))
            bubble.run(.sequence([.wait(forDuration: Double(i) * 1.4), rise]))
        }
    }

    private func buildNPCBooth(topEdge: CGFloat, panelTop: CGFloat, panelWidth: CGFloat) {
        // Dedicated framed area behind the NPC.
        let boothTop = topEdge - 70
        let boothBottom = panelTop - 26
        let boothHeight = max(160, boothTop - boothBottom)
        let boothCenterY = (boothTop + boothBottom) / 2

        let booth = SKShapeNode(rectOf: CGSize(width: panelWidth, height: boothHeight),
                                cornerRadius: 18)
        booth.position = CGPoint(x: 0, y: boothCenterY)
        booth.fillTexture = GameUI.gradientTexture(size: CGSize(width: panelWidth, height: boothHeight),
                                                   colors: [UIColor(red: 0.11, green: 0.30, blue: 0.40, alpha: 1),
                                                            UIColor(red: 0.06, green: 0.18, blue: 0.29, alpha: 1)])
        booth.fillColor = .white
        booth.strokeColor = GameUI.gold.withAlphaComponent(0.30)
        booth.lineWidth = 2
        booth.zPosition = 1
        addChild(booth)

        // Faint shelf lines to suggest a stocked booth without clutter.
        for i in 1...2 {
            let y = boothTop - CGFloat(i) * boothHeight / 3
            let shelf = SKShapeNode(rectOf: CGSize(width: panelWidth - 36, height: 2), cornerRadius: 1)
            shelf.fillColor = UIColor.white.withAlphaComponent(0.06)
            shelf.strokeColor = .clear
            shelf.position = CGPoint(x: 0, y: y)
            shelf.zPosition = 1.1
            addChild(shelf)
        }

        // Large NPC artwork, anchored at its base so the counter panel overlaps
        // the lower body and the breathing rises from a settled stance.
        let npcHeight = min(max(screenSize.height * 0.30, 180), 268)
        let npc = SKSpriteNode(imageNamed: config.npcAssetName)
        let textureSize = npc.texture?.size() ?? CGSize(width: 3, height: 4)
        let aspect = textureSize.width / max(1, textureSize.height)
        npc.size = CGSize(width: npcHeight * aspect, height: npcHeight)
        npc.anchorPoint = CGPoint(x: 0.5, y: 0)
        // Base sits below the counter's top edge so it is hidden behind the panel.
        npc.position = CGPoint(x: 0, y: panelTop - 46)
        npc.zPosition = 2
        addChild(npc)
        npc.run(VendorScreenNode.breathingAction(for: config.breath),
                withKey: "vendor_npc_idle_breath")

        // A soft floor shadow anchoring the character.
        let shadow = SKShapeNode(ellipseOf: CGSize(width: npc.size.width * 0.7, height: 16))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: panelTop - 42)
        shadow.zPosition = 1.5
        addChild(shadow)
    }

    private func buildHeader(topEdge: CGFloat) {
        let leftX = -contentWidth / 2

        let title = makeLabel(config.title, fontSize: 21, bold: true, color: .white)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: leftX, y: topEdge - 26)
        title.zPosition = 20
        addChild(title)

        let description = makeLabel(config.description, fontSize: 11.5, color: UIColor.white.withAlphaComponent(0.72))
        description.horizontalAlignmentMode = .left
        description.preferredMaxLayoutWidth = contentWidth * 0.62
        description.numberOfLines = 2
        description.lineBreakMode = .byWordWrapping
        description.position = CGPoint(x: leftX, y: topEdge - 50)
        description.zPosition = 20
        addChild(description)

        // Shell balance pill, top-right.
        let pillWidth: CGFloat = 122
        let pillHeight: CGFloat = 34
        let pill = SKShapeNode(rectOf: CGSize(width: pillWidth, height: pillHeight), cornerRadius: 17)
        pill.fillColor = UIColor(white: 0, alpha: 0.28)
        pill.strokeColor = GameUI.gold.withAlphaComponent(0.55)
        pill.lineWidth = 1.2
        pill.position = CGPoint(x: contentWidth / 2 - pillWidth / 2, y: topEdge - 30)
        pill.zPosition = 20
        addChild(pill)
        balancePill = pill

        let shell = SKShapeNode(ellipseOf: CGSize(width: 16, height: 13))
        shell.fillColor = GameUI.gold
        shell.strokeColor = UIColor.white.withAlphaComponent(0.5)
        shell.lineWidth = 0.8
        shell.position = CGPoint(x: -pillWidth / 2 + 18, y: 0)
        shell.zPosition = 1
        pill.addChild(shell)

        balanceLabel = makeLabel("", fontSize: 14, bold: true, color: .white)
        balanceLabel.horizontalAlignmentMode = .left
        balanceLabel.position = CGPoint(x: -pillWidth / 2 + 32, y: 0)
        balanceLabel.zPosition = 1
        pill.addChild(balanceLabel)

        refreshBalance()
    }

    private func buildCounterPanel(top: CGFloat, bottom: CGFloat, width: CGFloat) {
        let height = max(160, top - bottom)
        let centerY = (top + bottom) / 2

        let panel = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 18)
        panel.fillTexture = GameUI.gradientTexture(size: CGSize(width: width, height: height),
                                                   colors: [GameUI.palePaper,
                                                            UIColor(red: 0.86, green: 0.93, blue: 0.92, alpha: 1)])
        panel.fillColor = .white
        panel.strokeColor = GameUI.accent.withAlphaComponent(0.35)
        panel.lineWidth = 1.4
        panel.position = CGPoint(x: 0, y: centerY)
        panel.zPosition = 10
        addChild(panel)

        // Counter "lip" highlight along the top edge, reinforcing the sense that
        // the NPC stands behind the counter.
        let lip = SKShapeNode(rectOf: CGSize(width: width - 10, height: 6), cornerRadius: 3)
        lip.fillColor = GameUI.gold.withAlphaComponent(0.42)
        lip.strokeColor = .clear
        lip.position = CGPoint(x: 0, y: top - 6)
        lip.zPosition = 11
        addChild(lip)
    }

    private func buildCloseButton(centerY: CGFloat) {
        let width = min(220, contentWidth * 0.72)
        let button = SKNode()
        button.name = "vendor_close"
        button.position = CGPoint(x: 0, y: centerY)
        button.zPosition = 20
        addChild(button)

        let card = GameUI.card(size: CGSize(width: width, height: 44),
                               cornerRadius: 10,
                               tint: GameUI.accent)
        card.name = "vendor_close"
        button.addChild(card)

        let label = makeLabel(config.closeTitle, fontSize: 13, bold: true, color: GameUI.ink)
        label.name = "vendor_close"
        label.zPosition = 3
        button.addChild(label)
    }

    // MARK: - Tabs

    private func renderTabs() {
        tabLayer.removeAllChildren()
        let categories = config.categories
        guard categories.count > 1 else { return }

        let height: CGFloat = 34
        let gap: CGFloat = 8
        let totalGap = gap * CGFloat(categories.count - 1)
        let segmentWidth = (contentWidth - totalGap) / CGFloat(categories.count)

        for (index, category) in categories.enumerated() {
            let active = index == selectedCategoryIndex
            let centerX = -contentWidth / 2 + segmentWidth / 2 + CGFloat(index) * (segmentWidth + gap)
            let name = "vendor_tab_\(category.id)"

            let node = SKNode()
            node.name = name
            node.position = CGPoint(x: centerX, y: 0)
            tabLayer.addChild(node)

            let bg = SKShapeNode(rectOf: CGSize(width: segmentWidth, height: height), cornerRadius: 9)
            bg.fillColor = active ? GameUI.accent.withAlphaComponent(0.92) : UIColor.white.withAlphaComponent(0.55)
            bg.strokeColor = active ? GameUI.gold.withAlphaComponent(0.6) : GameUI.accent.withAlphaComponent(0.28)
            bg.lineWidth = active ? 1.4 : 1
            bg.name = name
            node.addChild(bg)

            let label = makeLabel(category.title,
                                  fontSize: 12.5,
                                  bold: true,
                                  color: active ? .white : GameUI.mutedInk)
            label.name = name
            label.preferredMaxLayoutWidth = segmentWidth - 10
            label.numberOfLines = 1
            label.zPosition = 1
            node.addChild(label)
        }
    }

    // MARK: - Entries / scrolling list

    private func renderEntries(resetScroll: Bool) {
        contentNode.removeFromParent()
        contentNode = SKNode()

        let categories = config.categories
        guard categories.indices.contains(selectedCategoryIndex) else { return }
        let entries = categories[selectedCategoryIndex].entries()
        actionButtons.removeAll()

        let rowGap: CGFloat = 10
        let rowHeight: CGFloat = 86
        let topPad: CGFloat = 6
        let bottomPad: CGFloat = 6
        let naturalHeight = entries.isEmpty
            ? viewportHeight
            : topPad + bottomPad + CGFloat(entries.count) * rowHeight + CGFloat(max(0, entries.count - 1)) * rowGap
        contentHeight = max(viewportHeight, naturalHeight)
        scrollMaxOffset = max(0, contentHeight - viewportHeight)

        if resetScroll {
            scrollOffset = 0
        } else {
            scrollOffset = min(max(scrollOffset, 0), scrollMaxOffset)
        }

        if entries.isEmpty {
            let empty = makeLabel("Nada disponível por aqui ainda.", fontSize: 13, color: GameUI.mutedInk)
            empty.position = CGPoint(x: 0, y: contentHeight / 2 - topPad - 20)
            contentNode.addChild(empty)
        } else {
            let firstCenter = contentHeight / 2 - topPad - rowHeight / 2
            for (index, entry) in entries.enumerated() {
                let centerY = firstCenter - CGFloat(index) * (rowHeight + rowGap)
                addRow(entry: entry, width: viewportWidth - 8, height: rowHeight, centerY: centerY)
            }
        }

        contentNode.position = CGPoint(x: 0, y: (viewportHeight - contentHeight) / 2 + scrollOffset)
        crop.addChild(contentNode)

        renderThumb()
    }

    private func addRow(entry: VendorEntry, width: CGFloat, height: CGFloat, centerY: CGFloat) {
        let name = "vendor_entry_\(entry.id)"
        let row = SKNode()
        row.name = name
        row.position = CGPoint(x: 0, y: centerY)
        contentNode.addChild(row)

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = UIColor.white.withAlphaComponent(0.85)
        bg.strokeColor = entry.tint.withAlphaComponent(0.32)
        bg.lineWidth = 1
        bg.name = name
        row.addChild(bg)

        let textLeftX: CGFloat

        if let makeIcon = entry.makeIcon {
            let ring = SKShapeNode(circleOfRadius: 22)
            ring.fillColor = entry.tint.withAlphaComponent(0.14)
            ring.strokeColor = entry.tint.withAlphaComponent(0.55)
            ring.lineWidth = 1
            ring.position = CGPoint(x: -width / 2 + 34, y: 6)
            ring.name = name
            row.addChild(ring)

            let icon = makeIcon(34)
            icon.position = ring.position
            icon.zPosition = 1
            icon.name = name
            row.addChild(icon)
            textLeftX = -width / 2 + 66
        } else {
            textLeftX = -width / 2 + 16
        }

        // Trailing action button.
        let buttonWidth: CGFloat = 96
        let buttonX = width / 2 - buttonWidth / 2 - 10
        let button = SKNode()
        button.name = name
        button.position = CGPoint(x: buttonX, y: 0)
        button.zPosition = 2
        row.addChild(button)
        actionButtons[entry.id] = button

        let buttonBg = GameUI.card(size: CGSize(width: buttonWidth, height: 50),
                                   cornerRadius: 9,
                                   tint: entry.actionEnabled ? entry.tint : GameUI.mutedInk)
        buttonBg.name = name
        buttonBg.alpha = entry.actionEnabled ? 1 : 0.8
        button.addChild(buttonBg)

        let buttonLabel = makeLabel(entry.actionText, fontSize: 10.5, bold: true, color: GameUI.ink)
        buttonLabel.name = name
        buttonLabel.numberOfLines = 2
        buttonLabel.zPosition = 1
        button.addChild(buttonLabel)

        // Title + description, kept clear of the icon and the button.
        let textWidth = (buttonX - buttonWidth / 2) - textLeftX - 12

        let title = makeLabel(entry.title, fontSize: 13.5, bold: true, color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .baseline
        title.preferredMaxLayoutWidth = max(60, textWidth)
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        title.position = CGPoint(x: textLeftX, y: height / 2 - 26)
        title.name = name
        row.addChild(title)

        // The description always wraps to its available width (same as the shop
        // rows). SKLabelNode only honours `preferredMaxLayoutWidth` when it is
        // allowed more than one line, so single-line labels would overflow behind
        // the action button — hence a minimum of two wrapped lines here too.
        let subtitle = makeLabel(entry.subtitle, fontSize: 10.5, color: GameUI.mutedInk)
        subtitle.horizontalAlignmentMode = .left
        subtitle.verticalAlignmentMode = .top
        subtitle.preferredMaxLayoutWidth = max(60, textWidth)
        subtitle.numberOfLines = 2
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.position = CGPoint(x: textLeftX, y: height / 2 - 34)
        subtitle.name = name
        row.addChild(subtitle)

        if let progress = entry.progress {
            let bar = makeProgressBar(width: max(60, textWidth),
                                      progress: progress,
                                      tint: entry.tint)
            bar.position = CGPoint(x: textLeftX, y: -height / 2 + 14)
            bar.zPosition = 1
            bar.name = name
            row.addChild(bar)
        }
    }

    /// A slim, numberless bar whose fill grows with `progress` (0...1). The value
    /// and any maximum are intentionally hidden — the fill communicates progress
    /// on its own. The returned node's origin is the bar's leading (left) edge.
    private func makeProgressBar(width: CGFloat, progress: CGFloat, tint: UIColor) -> SKNode {
        let node = SKNode()
        let barHeight: CGFloat = 5
        let clamped = min(max(progress, 0), 1)

        let track = SKShapeNode(rectOf: CGSize(width: width, height: barHeight), cornerRadius: barHeight / 2)
        track.fillColor = GameUI.line.withAlphaComponent(0.16)
        track.strokeColor = tint.withAlphaComponent(0.22)
        track.lineWidth = 0.8
        track.position = CGPoint(x: width / 2, y: 0)
        node.addChild(track)

        if clamped > 0 {
            let fillWidth = max(barHeight, width * clamped)
            let fill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: barHeight), cornerRadius: barHeight / 2)
            fill.fillColor = tint.withAlphaComponent(0.9)
            fill.strokeColor = .clear
            fill.position = CGPoint(x: fillWidth / 2, y: 0)
            fill.zPosition = 1
            node.addChild(fill)
        }

        return node
    }

    private func renderThumb() {
        // Clear any previous scrollbar nodes (track + thumb) before rebuilding.
        childNode(withName: "vendor_scroll_track")?.removeFromParent()
        thumbNode?.removeFromParent()
        thumbNode = nil
        guard scrollMaxOffset > 1 else { return }

        let trackHeight = max(30, viewportHeight - 12)
        let thumbHeight = max(26, trackHeight * min(1, viewportHeight / contentHeight))
        thumbTravel = max(0, trackHeight - thumbHeight)
        let progress = scrollMaxOffset > 0 ? scrollOffset / scrollMaxOffset : 0
        let trackX = viewportCenter.x + viewportWidth / 2 - 6

        let track = SKShapeNode(rectOf: CGSize(width: 4, height: trackHeight), cornerRadius: 2)
        track.name = "vendor_scroll_track"
        track.fillColor = GameUI.line.withAlphaComponent(0.12)
        track.strokeColor = .clear
        track.position = CGPoint(x: trackX, y: viewportCenter.y)
        track.zPosition = 15
        addChild(track)

        let thumb = SKShapeNode(rectOf: CGSize(width: 4, height: thumbHeight), cornerRadius: 2)
        thumb.fillColor = GameUI.accent.withAlphaComponent(0.55)
        thumb.strokeColor = .clear
        thumb.position = CGPoint(x: trackX,
                                 y: viewportCenter.y + thumbTravel / 2 - progress * thumbTravel)
        thumb.zPosition = 16
        addChild(thumb)
        thumbNode = thumb
    }

    private func repositionScroll() {
        contentNode.position = CGPoint(x: 0, y: (viewportHeight - contentHeight) / 2 + scrollOffset)
        if let thumb = thumbNode, thumbTravel > 0 {
            let progress = scrollMaxOffset > 0 ? scrollOffset / scrollMaxOffset : 0
            thumb.position = CGPoint(x: thumb.position.x,
                                     y: viewportCenter.y + thumbTravel / 2 - progress * thumbTravel)
        }
    }

    // MARK: - Balance

    private func refreshBalance() {
        guard let balanceLabel = balanceLabel else { return }
        let target = config.balance()

        // First paint: no animation, just show the current amount.
        guard hasShownBalance else {
            displayedBalance = target
            balanceLabel.text = GameUI.shellAmountText(target)
            hasShownBalance = true
            return
        }
        guard target != displayedBalance else { return }

        animateBalance(from: displayedBalance, to: target)
        displayedBalance = target
    }

    /// Counts the balance from `from` to `to`, pulses the pill and, when the
    /// amount drops, floats a small "-N" so the spend is clearly felt.
    private func animateBalance(from: Int, to: Int) {
        guard let balanceLabel = balanceLabel else { return }
        let delta = to - from
        let duration = 0.35

        balanceLabel.removeAction(forKey: "balance_count")
        let count = SKAction.customAction(withDuration: duration) { node, elapsed in
            let t = min(1, CGFloat(elapsed) / CGFloat(duration))
            let value = Int(round(CGFloat(from) + CGFloat(delta) * t))
            (node as? SKLabelNode)?.text = GameUI.shellAmountText(value)
        }
        count.timingMode = .easeOut
        balanceLabel.run(.sequence([count,
                                    .run { [weak balanceLabel] in
                                        balanceLabel?.text = GameUI.shellAmountText(to)
                                    }]),
                         withKey: "balance_count")

        if let pill = balancePill {
            pill.removeAction(forKey: "balance_pulse")
            pill.run(.sequence([.scale(to: 1.12, duration: 0.09),
                                .scale(to: 1.0, duration: 0.16)]),
                     withKey: "balance_pulse")
        }

        guard delta < 0, let pill = balancePill else { return }
        let float = makeLabel("\(delta)", fontSize: 13, bold: true, color: GameUI.coral)
        float.position = CGPoint(x: pill.position.x, y: pill.position.y - 24)
        float.zPosition = 21
        addChild(float)
        float.run(.sequence([
            .group([.moveBy(x: 0, y: 26, duration: 0.7),
                    .sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.35)])]),
            .removeFromParent()
        ]))
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        isScrolling = viewportRect.contains(point) && scrollMaxOffset > 1
        lastTouchY = point.y
        touchStartPoint = point
        pendingTapName = actionableName(at: point)
        didMoveTouch = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if let start = touchStartPoint, point.distance(to: start) > 8 {
            didMoveTouch = true
            pendingTapName = nil
        }
        guard isScrolling, scrollMaxOffset > 1 else { return }
        let deltaY = point.y - lastTouchY
        guard abs(deltaY) > 0.5 else { return }
        // Content follows the finger: dragging up reveals lower entries.
        let next = min(max(scrollOffset + deltaY, 0), scrollMaxOffset)
        lastTouchY = point.y
        guard abs(next - scrollOffset) > 0.1 else { return }
        scrollOffset = next
        repositionScroll()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !didMoveTouch, let name = pendingTapName {
            handleTap(named: name)
        }
        resetTouchState()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetTouchState()
    }

    private func resetTouchState() {
        isScrolling = false
        touchStartPoint = nil
        pendingTapName = nil
        didMoveTouch = false
    }

    private func handleTap(named name: String) {
        if name == "vendor_close" {
            onClose()
            return
        }
        if name.hasPrefix("vendor_tab_") {
            let categoryId = String(name.dropFirst("vendor_tab_".count))
            guard let index = config.categories.firstIndex(where: { $0.id == categoryId }),
                  index != selectedCategoryIndex else { return }
            selectedCategoryIndex = index
            GameAudio.shared.play(.uiOpenPanel)
            renderTabs()
            renderEntries(resetScroll: true)
            return
        }
        if name.hasPrefix("vendor_entry_") {
            guard !isResolvingEntry else { return }
            let entryId = String(name.dropFirst("vendor_entry_".count))
            let categoryId = config.categories.indices.contains(selectedCategoryIndex)
                ? config.categories[selectedCategoryIndex].id
                : ""
            resolveEntryTap(entryId: entryId, categoryId: categoryId)
        }
    }

    /// Pops the tapped action button, then hands off to the owner. Running the
    /// selection after the pop keeps the press feedback visible even though the
    /// owner rebuilds the list (and animates the balance) on a successful buy.
    private func resolveEntryTap(entryId: String, categoryId: String) {
        isResolvingEntry = true
        GameAudio.shared.play(.uiTap)

        let resolve = SKAction.run { [weak self] in
            self?.isResolvingEntry = false
            self?.onSelect(categoryId, entryId)
        }

        if let button = actionButtons[entryId] {
            button.removeAction(forKey: "entry_press")
            button.run(.sequence([.scale(to: 1.14, duration: 0.09),
                                  .scale(to: 1.0, duration: 0.11),
                                  resolve]),
                       withKey: "entry_press")
        } else {
            run(.sequence([.wait(forDuration: 0.18), resolve]))
        }
    }

    private func actionableName(at point: CGPoint) -> String? {
        var node: SKNode? = atPoint(point)
        while let current = node {
            if let name = current.name,
               name == "vendor_close"
                || name.hasPrefix("vendor_tab_")
                || name.hasPrefix("vendor_entry_") {
                return name
            }
            node = current.parent
        }
        return nil
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String,
                           fontSize: CGFloat,
                           bold: Bool = false,
                           color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    static func breathingAction(for breath: VendorBreath) -> SKAction {
        let expand: SKAction
        let contract: SKAction
        let settle: SKAction
        switch breath {
        case .gentle:
            expand = .group([.scaleX(to: 1.018, duration: 1.6), .scaleY(to: 0.982, duration: 1.6)])
            contract = .group([.scaleX(to: 0.986, duration: 1.6), .scaleY(to: 1.022, duration: 1.6)])
            settle = .group([.scaleX(to: 1, duration: 0.9), .scaleY(to: 1, duration: 0.9)])
        case .sway:
            expand = .group([.rotate(toAngle: 0.02, duration: 1.4),
                             .scaleX(to: 1.014, duration: 1.4),
                             .scaleY(to: 0.99, duration: 1.4)])
            contract = .group([.rotate(toAngle: -0.02, duration: 1.4),
                               .scaleX(to: 0.99, duration: 1.4),
                               .scaleY(to: 1.016, duration: 1.4)])
            settle = .group([.rotate(toAngle: 0, duration: 0.7),
                             .scaleX(to: 1, duration: 0.7),
                             .scaleY(to: 1, duration: 0.7)])
        }
        expand.timingMode = .easeInEaseOut
        contract.timingMode = .easeInEaseOut
        settle.timingMode = .easeInEaseOut
        return .repeatForever(.sequence([expand, contract, settle]))
    }
}
