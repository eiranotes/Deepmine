import DeepMineCore
import SwiftUI

extension ShaftView {
    func show(_ gain: FloatingGain) {
        floatingGains.append(gain)
        guard !reduceMotion else {
            Task {
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.linear(duration: 0.18)) {
                    if let index = floatingGains.firstIndex(where: { $0.id == gain.id }) {
                        floatingGains[index].opacity = 0
                    }
                }
                try? await Task.sleep(for: .milliseconds(200))
                floatingGains.removeAll { $0.id == gain.id }
            }
            return
        }
        withAnimation(.easeOut(duration: 0.7)) {
            if let index = floatingGains.firstIndex(where: { $0.id == gain.id }) {
                floatingGains[index].offsetY = -90
                floatingGains[index].opacity = 0
            }
        }
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            floatingGains.removeAll { $0.id == gain.id }
        }
    }

    func showDebris(isLarge: Bool, densityOverride: Int? = nil) {
        let tier = EquipmentEngine.visualTier(level: player.equipment.drill)
        let wideBonus = player.equipmentModifications.drill == .drillWide ? 2 : 0
        let impactBonus = player.equipmentModifications.drill == .drillImpact ? 1 : 0
        let burst = DebrisBurst(
            isLarge: isLarge,
            density: densityOverride ?? (3 + tier * 2 + wideBonus + impactBonus)
        )
        debrisBursts.append(burst)
        guard !reduceMotion else {
            Task {
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.linear(duration: 0.16)) {
                    if let index = debrisBursts.firstIndex(where: { $0.id == burst.id }) {
                        debrisBursts[index].opacity = 0
                    }
                }
                try? await Task.sleep(for: .milliseconds(180))
                debrisBursts.removeAll { $0.id == burst.id }
            }
            return
        }
        withAnimation(.easeOut(duration: 0.42)) {
            if let index = debrisBursts.firstIndex(where: { $0.id == burst.id }) {
                debrisBursts[index].progress = 1
                debrisBursts[index].opacity = 0
            }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(480))
            debrisBursts.removeAll { $0.id == burst.id }
        }
    }

    func showGroundCollapse(region: String) {
        let collapse = GroundCollapseBurst(region: region)
        groundCollapses.append(collapse)
        if reduceMotion {
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.linear(duration: 0.16)) {
                    if let index = groundCollapses.firstIndex(where: {
                        $0.id == collapse.id
                    }) {
                        groundCollapses[index].opacity = 0
                    }
                }
                try? await Task.sleep(for: .milliseconds(180))
                groundCollapses.removeAll { $0.id == collapse.id }
            }
            return
        }
        withAnimation(.easeIn(duration: 0.34)) {
            if let index = groundCollapses.firstIndex(where: { $0.id == collapse.id }) {
                groundCollapses[index].progress = 1
            }
        }
        Task {
            try? await Task.sleep(for: .milliseconds(320))
            withAnimation(.easeOut(duration: 0.18)) {
                if let index = groundCollapses.firstIndex(where: { $0.id == collapse.id }) {
                    groundCollapses[index].opacity = 0
                }
            }
            try? await Task.sleep(for: .milliseconds(210))
            groundCollapses.removeAll { $0.id == collapse.id }
        }
    }
}
