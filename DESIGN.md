---
name: DeepMine
description: 암반을 부수고 내려가는 깊이를 위치로 보여주는 iOS 방치형 채굴 인터페이스
colors:
  coal: "#10100F"
  shale: "#373630"
  limestone: "#E7E0CF"
  lamp-brass: "#C58C39"
typography:
  display:
    fontFamily: "SF Pro Display, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "20pt"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "normal"
  headline:
    fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "17pt"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "normal"
  body:
    fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "15pt"
    fontWeight: 400
    lineHeight: 1.35
    letterSpacing: "normal"
  label:
    fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
    fontSize: "12pt"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
rounded:
  badge: "5pt"
  control: "6pt"
  panel: "9pt"
spacing:
  xxs: "3pt"
  xs: "5pt"
  sm: "8pt"
  md: "12pt"
  lg: "17pt"
components:
  button-primary:
    backgroundColor: "{colors.lamp-brass}"
    textColor: "{colors.coal}"
    typography: "{typography.headline}"
    rounded: "{rounded.control}"
    padding: "0 16pt"
    height: "50pt"
  button-secondary:
    backgroundColor: "{colors.shale}"
    textColor: "{colors.limestone}"
    typography: "{typography.headline}"
    rounded: "{rounded.control}"
    padding: "0 16pt"
    height: "50pt"
  mission-panel:
    backgroundColor: "{colors.shale}"
    textColor: "{colors.limestone}"
    rounded: "{rounded.panel}"
    padding: "17pt"
  status-chip:
    backgroundColor: "{colors.coal}"
    textColor: "{colors.lamp-brass}"
    typography: "{typography.label}"
    rounded: "{rounded.badge}"
    padding: "7pt 10pt"
  mine-toggle:
    backgroundColor: "{colors.coal}"
    textColor: "{colors.limestone}"
    rounded: "{rounded.badge}"
    height: "28pt"
    width: "52pt"
---

# Design System: DeepMine

## Overview

**Creative North Star: "램프 아래의 갱도 장비판"**

DeepMine은 짧게 탭하고 내려놓아도 스스로 움직이는 광산 작업 장비다. 화면은 어두운 갱도
속에서 램프 하나로 막장과 필요한 계기만 읽는 장면처럼 보여야 한다. 집중 출정은 필요할 때
붙이는 증폭기다. 게임의 성격은 픽셀 장면, 광부 실루엣, 황동 표찰에서 나오고 조작 방식은
iOS 사용자가 즉시 이해하는 버튼, Toggle, Live Activity 규칙을 유지한다.

시각적 흥분보다 집중을 우선한다. 네온 사이버펑크, SaaS 대시보드, 유리 카드, 지표 격자, 장식용 애니메이션을 거부한다. 하나의 화면에는 하나의 황동 주 동작만 두고 나머지는 혈암과 석탄으로 물린다.

**Key Characteristics:**

- 네 가지 안료만 사용하는 램프 중심의 어두운 광산 팔레트
- 리벳, 금속 하단 깊이, 각진 레버로 이어지는 장비형 조작
- 한국어 행동 목적이 먼저 읽히고 내부 프레임워크명은 진단 영역에만 남는 정보 구조
- 24pt 픽셀 실루엣과 명도 대비로 앱, 잠금화면, Dynamic Island까지 이어지는 정체성
- 상태를 색이 아니라 문양, 문구, 채움 방식으로 중복 전달하는 체계

**The Shaft-First Rule.** 앱의 주역은 세로 갱도와 막장이다. 집중 세션 중 시스템 표면은 남은
시간과 현재 계획만 조용히 확인시키며 증폭 보상 공개는 귀환 이후에만 허용한다.

## Colors

네 가지 안료가 실제 광산 재료처럼 역할을 나눈다. 새 기능은 새 색을 요구할 수 없다.

### Primary

- **램프 황동:** 주 동작, 현재 진행, 작은 표찰, 광부 램프에만 쓴다. 한 화면에서 차지하는 면적은 10%를 넘기지 않는다.

### Neutral

- **석탄:** 전체 배경, 버튼 하단 깊이, 반전 텍스트의 바탕이다.
- **혈암:** 패널과 보조 버튼의 구조를 만든다.
- **석회:** 주 텍스트, 고대비 경계, 픽셀 하이라이트다. 낮은 위계는 이 안료의 불투명도로만 만든다.

**The Four-Pigment Rule.** 보라, 청록, 경고 빨강을 포함한 다섯 번째 기본색은 금지한다. 투명도는 허용하지만 새로운 RGB 값은 추가하지 않는다.

**The Brass Rarity Rule.** 황동 채움은 가장 중요한 현재 행동 하나에만 쓴다. 경고와 오류는 아이콘 및 문구를 먼저 바꾸고 황동 외곽선으로 보조한다.

## Typography

**Display Font:** SF Pro Display
**Body Font:** SF Pro Text
**Label/Mono Font:** SF Pro Text, 숫자에만 monospaced digit 적용

**Character:** 하나의 시스템 글꼴이 모든 표면을 잇는다. 픽셀 글꼴이나 장식 서체는 작은 iOS 표면의 판독성을 해치므로 사용하지 않는다.

### Hierarchy

- **Display** (800, 20pt 기본값): 출정 안내의 한 번뿐인 브랜드 제목에 사용한다.
- **Headline** (700, 17pt 기본값): 모듈 목적, 버튼 제목, 잠금화면의 세션 상태에 사용한다.
- **Body** (400, 15pt 기본값): 결과와 행동 이유를 설명한다.
- **Label** (700, 12pt 기본값): 단계, 상태 표찰, Live Activity의 보조 정보에 사용한다.

실제 구현은 SwiftUI의 `title3`, `headline`, `subheadline`, `caption`, `caption2`를 사용해 Dynamic Type을 따른다. 카운트다운과 시간만 `monospacedDigit()`를 허용한다.

**The Player-Language Rule.** `ActivityKit`, `AlarmKit`, `ManagedSettings` 같은 구현명은 플레이어 표면에 제목으로 노출하지 않는다. `귀환 신호`, `갱도 문`, `보급 상자`처럼 행동과 결과를 먼저 쓴다.

## Elevation

DeepMine은 흐린 그림자를 사용하지 않는다. 계층은 석탄과 혈암의 명도 차이, 1pt 석회 외곽선, 버튼 아래 4pt의 단단한 금속 단면으로 만든다. 눌림 상태에서는 버튼이 아래로 3pt 이동해 단면이 줄어들며, Reduce Motion에서는 위치 이동 없이 명암 변화만 남긴다.

**The No-Glow Rule.** 광산의 빛은 황동 안료로 표현한다. 네온 글로우, 8pt를 넘는 블러 그림자, 유리 재질은 금지한다.

**The Structural-Depth Rule.** 깊이는 장식이 아니라 누를 수 있음을 설명해야 한다. 정적인 패널에는 버튼용 하단 단면을 붙이지 않는다.

## Components

### Buttons

- **Shape:** 6pt 모서리, 최소 높이 50pt, 네 귀퉁이 3pt 리벳을 사용한다.
- **Primary:** 황동 채움과 석탄 텍스트. 한 화면에 하나만 둔다.
- **Secondary:** 혈암 채움과 석회 텍스트, 낮은 석회 외곽선.
- **Warning:** 혈암 채움과 황동 텍스트·외곽선. 빨간색 없이 경고 심볼과 구체적 문구를 함께 사용한다.
- **Safety:** 석탄 채움, 석회 텍스트, 황동 외곽선과 하단 단면. `비상 해제`처럼 결과를 명시한다.
- **Press:** 터치 즉시 3pt 아래로 이동하며 `interactiveSpring(response: 0.18, dampingFraction: 1)`로 복귀한다. 최소 터치 영역은 44×44pt다.

### Chips

- **Style:** 5pt 모서리의 작은 금속 표찰이다. 기본 상태는 석탄 배경과 낮은 석회 외곽선이다.
- **State:** `circle.dashed`, `hourglass`, `checkmark.seal`, `exclamationmark.triangle`, `xmark.octagon` 문양과 한국어 상태를 함께 쓴다. 진행과 오류만 황동으로 채울 수 있다.

### Cards / Containers

- **Corner Style:** 9pt 모서리.
- **Background:** 혈암 바탕, 석탄 전체 캔버스.
- **Shadow Strategy:** 그림자 없음. 1pt 외곽선과 작은 리벳으로 구조를 만든다.
- **Border:** 기본은 낮은 석회 외곽선, Increase Contrast에서 불투명 석회 2pt.
- **Internal Padding:** 17pt.

### Mine Toggle

SwiftUI `Toggle`의 의미와 접근성 상태를 유지하면서 52×28pt 사각 레일로 그린다. 손잡이는 20pt 금속판이며 켜짐은 황동, 꺼짐은 낮은 석회로 표현한다. 원형 iOS 스위치처럼 보이게 모방하지 않고 광산 레버라는 제품 표정을 부여하되 탭 동작은 표준 Toggle과 같아야 한다.

### Shaft Column

광산 화면의 주역이다. 갱도를 세로 단면으로 그려 심도를 숫자가 아니라 위치로 읽게 한다.

- **밴드 높이:** 부순 갱도 30pt, 작업 중인 막장 128pt, 미개척 암반 44pt.
- **막장 고정:** 막장의 화면 위치는 상단에서 90pt로 고정한다. 층이 깨지면 기둥 전체가 위로
  올라간다. 탭하는 바위가 손가락 밑에서 움직이면 안 된다.
- **전환:** 막장 위치는 고정하고 기둥에 critically damped interactive spring을 적용한다.
  Reduce Motion에서는 위치 이동을 생략하고 보상·파편을 제자리 교차 페이드로 대체한다.
- **텍스처:** 지역별 320×128 `ShaftRock_*` 와이드 벽면을 밴드 폭에 맞춰 채운다. 정사각
  암반 조각을 반복·반전하지 않는다. 작업면에는 `ShaftGantry`를 겹쳐 탭 대상의 무대를
  만들고 광맥층에만 `SeamVein`을 겹친다. 지표의 빈 공간은 `ShaftSurface` 캐노피가 맡는다.
  일곱 자산은 배경·구조·상태로 역할이 분리된다 (D-048).
- **파괴 표현:** 남은 내구를 위에서부터 석탄으로 덮고 경계에 1.5pt 황동 선을 둔다. 파괴가
  진행되는 방향과 플레이어가 가는 방향을 일치시킨다.
- **타격 계기:** 작업면 위에 탭/자동 데미지, 내구, 충격 배율, 다음 광맥층을 둔다. 일반
  타격은 데미지 숫자, 층 파괴는 황동 광석 수치와 파편으로 구분한다. `+0` 보상은 표시하지 않는다.
- **어둠:** 막장 아래는 램프가 닿는 만큼만 보인다. 조도는 석탄 오버레이의 불투명도로만
  표현하고 색을 바꾸지 않는다.
- **벽면:** 모든 밴드에 7pt 혈암 벽을 겹쳐 그려 기둥이 하나의 구멍으로 읽히게 한다.
- **눈금:** 좌측 44pt 열에 20m마다, 그리고 막장에는 항상 심도를 적는다. 4m마다 적으면
  숫자 벽이 된다.
- **명판:** 지역이 바뀌는 첫 층에만 황동 캡슐로 지역명을 단다.
- **약점:** 보이는 표식은 36pt, 실제 조작 영역은 48×48pt다. 탭 대상의 최소 크기를
  장식 크기에 종속시키지 않는다.

### Live Activity Surfaces

- **Compact:** 24pt 광부 실루엣과 자동 카운트다운만 남긴다.
- **Expanded:** 144pt 안에서 상태·타이머, 진행·자원, 행동의 3단 구조를 사용한다.
- **Lock Screen:** 160pt 안에서 세션명, 남은 시간, 진행, 깊이·예상 광석·연속 일수를 표시한다.

## Do's and Don'ts

### Do:

- **Do** 석탄, 혈암, 석회, 램프 황동 네 안료만 사용한다.
- **Do** 주 동작 하나만 황동으로 채우고 나머지 행동은 중립 금속판으로 낮춘다.
- **Do** 상태를 한국어 문구, SF Symbol, 채움 방식으로 동시에 전달한다.
- **Do** 생성 원본을 24×24 논리 그리드로 최근접 축소하고 네 안료·이진 투명도로 정리한 뒤 실제 Dynamic Island에서 판독성을 확인한다.
- **Do** 잠금화면 160pt, Dynamic Island Expanded 144pt, Compact 52–62×37pt 제약을 먼저 검증한다.
- **Do** 세션 중에는 자동 타이머와 진행만 보여주고 보상·광맥 공개는 귀환 이후로 미룬다.

### Don't:

- **Don't** 보라·청록·빨강 등 상태별 네온색을 다시 추가한다.
- **Don't** SaaS 대시보드처럼 동일 카드 격자, 영문 계측명, 큰 지표 숫자를 화면의 주인공으로 만든다.
- **Don't** 글로우, 그라디언트 텍스트, 유리 카드, 장식용 격자, 넓게 흐린 그림자를 사용한다.
- **Don't** 모든 버튼을 pill로 만들거나 패널 모서리를 16pt보다 크게 둥글린다.
- **Don't** 성공·경고·오류를 색만으로 구분한다.
- **Don't** 백그라운드 갱신을 흉내 내기 위해 세션 중 알림이나 반복 애니메이션을 추가한다.
- **Don't** 제품 UI에 픽셀 폰트를 사용하거나 SF Symbols와 외부 웹 아이콘 세트를 섞는다.
