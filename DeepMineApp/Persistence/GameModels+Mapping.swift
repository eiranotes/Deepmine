import DeepMineCore
import Foundation

extension PlayerStateEntity {
    func apply(_ state: PlayerState) {
        ore = state.resources.ore.doubleValue
        oreMantissa = state.resources.ore.mantissa
        oreExponent = state.resources.ore.exponent
        crystals = state.resources.crystals
        coreShards = state.resources.coreShards
        runFocusCredits = state.runFocusCredits
        lifetimeFocusCredits = state.lifetimeFocusCredits
        completedSessionCount = state.completedSessionCount
        bonusDepthMeters = state.bonusDepthMeters
        dailyGoalMinutes = state.dailyGoalMinutes
        streakDays = state.streakDays
        latestDayYear = state.latestDayKey?.year
        latestDayMonth = state.latestDayKey?.month
        latestDayDay = state.latestDayKey?.day
        consecutiveVeinMisses = state.consecutiveVeinMisses
        permanentResonanceLevel = state.permanentResonanceLevel
        selectedThemeRawValue = state.selectedTheme.rawValue
        resonanceBoostPending = state.resonanceBoostPending
        excavationMemoryLevel = state.excavationMemoryLevel
        compressedTimeLevel = state.compressedTimeLevel
        prestigeIndex = state.prestigeIndex
        onboardingStageRawValue = state.onboardingStage.rawValue
        demoStartedAt = state.demoStartedAt
        demoCompletedAt = state.demoCompletedAt
        demoRewardReceiptID = state.demoRewardReceiptID
        demoUpgradePurchaseID = state.demoUpgradePurchaseID
        focusProtectionPermissionRawValue = state.focusProtectionPermission.rawValue
        endAlertPermissionRawValue = state.endAlertPermission.rawValue
        returnReminderPermissionRawValue = state.returnReminderPermission.rawValue
        lastSelectedPlanRawValue = state.lastSelectedPlan.rawValue
        lastSelectedDurationRawValue = state.lastSelectedDuration.rawValue
        mineFaceSegmentIndex = state.mineFace.segmentIndex
        mineFaceRemainingIntegrityData =
            (try? JSONEncoder().encode(state.mineFace.remainingIntegrity)) ?? Data()
        mineFaceImpact = state.mineFace.impact.value
        mineFaceLifetimeSegmentsBroken = state.mineFace.lifetimeSegmentsBroken
        mineFaceLifetimeSeamsBroken = state.mineFace.lifetimeSeamsBroken
        equipmentModificationsData =
            (try? JSONEncoder().encode(state.equipmentModifications)) ?? Data()
        mineFaceBoreHistoryData =
            (try? JSONEncoder().encode(state.mineFace.boreHistory)) ?? Data()
        deepestSegmentIndex = state.deepestSegmentIndex
        runSegmentsBroken = state.runSegmentsBroken
        lastSettledAt = state.lastSettledAt
    }

    /// Rebuilds the face. An empty or unreadable integrity blob falls back to a full
    /// segment rather than throwing: losing progress inside one rock is recoverable,
    /// refusing to open the save is not.
    func storedMineFace() -> MineFaceState {
        MineFaceState(
            segmentIndex: mineFaceSegmentIndex,
            remainingIntegrity: mineFaceRemainingIntegrityData.isEmpty
                ? nil
                : try? JSONDecoder().decode(BigNumber.self, from: mineFaceRemainingIntegrityData),
            impact: ImpactMeter(value: mineFaceImpact),
            lifetimeSegmentsBroken: mineFaceLifetimeSegmentsBroken,
            lifetimeSeamsBroken: mineFaceLifetimeSeamsBroken,
            boreHistory: mineFaceBoreHistoryData.isEmpty
                ? []
                : (try? JSONDecoder().decode(
                    [BoreRecord].self,
                    from: mineFaceBoreHistoryData
                )) ?? []
        )
    }

    func storedEquipmentModifications() -> EquipmentModifications {
        guard !equipmentModificationsData.isEmpty else { return .empty }
        return (try? JSONDecoder().decode(
            EquipmentModifications.self,
            from: equipmentModificationsData
        )) ?? .empty
    }

    func latestDayKey() throws -> DayKey? {
        let parts = [latestDayYear, latestDayMonth, latestDayDay]
        guard parts.contains(where: { $0 != nil }) else { return nil }
        guard let year = latestDayYear, let month = latestDayMonth, let day = latestDayDay else {
            throw GamePersistenceError.invalidStoredValue(
                field: "latestDayKey",
                value: "incomplete"
            )
        }
        return DayKey(year: year, month: month, day: day)
    }
}

extension SessionRecordEntity {
    func apply(_ record: SessionHistoryEntry, sortIndex: Int) {
        endedAt = record.endedAt
        focusedMinutes = record.focusedMinutes
        focusCredits = record.focusCredits
        planRawValue = record.plan.rawValue
        verificationGradeRawValue = record.verificationGrade.rawValue
        oreEarned = record.oreEarned
        veinRawValue = record.vein?.rawValue
        depthAfter = record.depthAfter
        completed = record.completed
        self.sortIndex = sortIndex
    }

    func coreRecord() throws -> SessionHistoryEntry {
        guard let plan = MinePlan(rawValue: planRawValue) else {
            throw GamePersistenceError.invalidStoredValue(field: "plan", value: planRawValue)
        }
        guard let grade = VerificationGrade(rawValue: verificationGradeRawValue) else {
            throw GamePersistenceError.invalidStoredValue(
                field: "verificationGrade",
                value: verificationGradeRawValue
            )
        }
        let vein: VeinKind?
        if let veinRawValue {
            guard let parsed = VeinKind(rawValue: veinRawValue) else {
                throw GamePersistenceError.invalidStoredValue(field: "vein", value: veinRawValue)
            }
            vein = parsed
        } else {
            vein = nil
        }
        return SessionHistoryEntry(
            completionID: completionID,
            endedAt: endedAt,
            focusedMinutes: focusedMinutes,
            focusCredits: focusCredits,
            plan: plan,
            verificationGrade: grade,
            oreEarned: oreEarned,
            vein: vein,
            depthAfter: depthAfter,
            completed: completed
        )
    }
}

extension PlayerStateEntity {
    /// Reads the wallet, preferring the `BigNumber` columns and falling back to the legacy
    /// `Double` for stores written before unbounded growth (D-069).
    var storedOre: BigNumber {
        guard oreMantissa != 0 || oreExponent != 0 else { return BigNumber(ore) }
        return BigNumber(mantissa: oreMantissa, exponent: oreExponent)
    }
}
