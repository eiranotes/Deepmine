import SwiftUI

struct ProbeHeader: View {
    let activeActivityCount: Int
    let passedProbeCount: Int

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(spacing: 0) {
            hero
            briefing
        }
        .background(ProbePalette.shale, in: RoundedRectangle(cornerRadius: 9))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(
                    contrast == .increased ? ProbePalette.limestone : ProbePalette.rockLight,
                    lineWidth: contrast == .increased ? 2 : 1
                )
        }
    }

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            Image("MineEntryHero")
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .frame(height: 192)
                .clipped()

            HStack(spacing: 8) {
                Text("DEEPMINE")
                    .font(.headline.weight(.black))
                    .lineLimit(1)
                Text("출정 준비")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ProbePalette.brass)
                    .lineLimit(1)
            }
            .probeTechnicalTextSize()
            .padding(.horizontal, 11)
            .frame(minHeight: 36)
            .background(ProbePalette.coal.opacity(0.92), in: RoundedRectangle(cornerRadius: 4))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(ProbePalette.brass.opacity(0.46), lineWidth: 1)
            }
            .padding(12)
        }
        .accessibilityLabel("닫힌 갱도 문 앞에서 장비를 점검하는 픽셀 광부")
    }

    private var briefing: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 12) {
                PixelMinerIcon(size: 40, lampColor: ProbePalette.brass)
                    .frame(width: 48, height: 48)
                    .background(ProbePalette.coal, in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ProbePalette.rockLight, lineWidth: 1)
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text("광산 문을 열기 전에")
                        .font(.title3.weight(.bold))
                    Text("아래 네 구역을 한 번씩 시험하면 첫 집중 채굴을 시작할 준비가 끝나요.")
                        .font(.subheadline)
                        .foregroundStyle(ProbePalette.highlight)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("장비 준비")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(passedProbeCount) / 5")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundStyle(ProbePalette.brass)
                }

                HStack(spacing: 5) {
                    ForEach(0..<5, id: \.self) { index in
                        Rectangle()
                            .fill(index < passedProbeCount ? ProbePalette.brass : ProbePalette.rockMid)
                            .frame(height: 9)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("장비 다섯 개 중 \(passedProbeCount)개 준비 완료")
            }

            if activeActivityCount > 0 {
                Label("잠금화면 표지 \(activeActivityCount)개 작동 중", systemImage: "rectangle.on.rectangle.badge.person.crop")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ProbePalette.brass)
            }
        }
        .padding(17)
    }
}

struct ProbeDeviceGateNotice: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) { gear; copy }
            VStack(alignment: .leading, spacing: 10) { gear; copy }
        }
        .padding(16)
        .background(ProbePalette.shale, in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(ProbePalette.rockLight, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var gear: some View {
        Image("ExpeditionGear")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 104, height: 104)
            .accessibilityHidden(true)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("마지막 관문은 아이폰에서", systemImage: "iphone")
                .font(.headline.weight(.bold))
                .foregroundStyle(ProbePalette.brass)
            Text("잠금화면, 종료 알람, 앱 차단은 실제 기기에서 한 번 더 확인해야 해요.")
                .font(.subheadline)
                .foregroundStyle(ProbePalette.highlight)
                .fixedSize(horizontal: false, vertical: true)
            Text("지금은 출정 전 준비 훈련 중")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ProbePalette.chalk)
        }
    }
}
