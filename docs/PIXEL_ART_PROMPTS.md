# DeepMine 픽셀 아트 프롬프트 및 산출 규격

- 문서 버전: v2.0
- 제품 기준: `docs/SPEC_v0.2.md`, `DESIGN.md` D-013
- 생성 모드: Codex 내장 ImageGen
- 산출 형식: PNG only
- 생성/검증 매니페스트: `artifacts/imagegen/game-assets-v1/manifest.json`

## 1. 고정 팔레트

모든 최종 픽셀은 아래 네 안료 중 하나여야 한다. 투명 스프라이트는
RGB 네 안료와 알파 0/255만 허용한다.

| 안료 | Hex | 역할 |
|---|---|---|
| 석탄 | `#10100F` | 배경, 가장 깊은 그림자 |
| 셰일 | `#373630` | 암반, 금속 중간 명도 |
| 석회암 | `#E7E0CF` | 형태를 읽히게 하는 하이라이트 |
| 램프 브라스 | `#C58C39` | 초점과 상태 강조 |

브라스는 각 에셋의 불투명 픽셀 중 10% 미만이어야 한다. 색으로만 정보를
전달하지 않으며, 그레이스케일과 StandBy 적색 단색에서도 실루엣이 읽혀야
한다.

## 2. 공통 생성 규칙

### 아이콘/스프라이트

```text
Square canvas, centered with generous padding.
Chunky 16-bit pixel-art game asset, hard stair-step edges,
no antialiasing, no gradients, no glow, no soft shadow,
no text, no letters, no numbers, no border, no UI frame.
Use only the visual roles of coal black #10100F,
shale gray #373630, limestone #E7E0CF,
and a tiny lamp-brass highlight #C58C39 under 10% of pixels.
Strong grayscale readability. PNG output.
```

투명 스프라이트는 내장 ImageGen에서 균일한 `#00FF00` 크로마 배경으로
생성하고, 공식 `remove_chroma_key.py` 도구로 배경을 제거한다. 최종 단계에서
알파를 0/255로 고정한다.

### 장면

```text
Chunky 16-bit pixel-art environment, strict hard stair-step edges,
no antialiasing, no gradients, no glow, no soft shadow,
no text, no letters, no numbers, no border, no UI frame.
Use only the visual roles of coal black #10100F,
shale gray #373630, limestone #E7E0CF,
and sparse lamp-brass #C58C39 under 10% of scene pixels.
Strong grayscale and red-monochrome readability.
Opaque PNG output.
```

채굴 중 장면은 phase-neutral이어야 한다. 광부가 발견하지 않은 희귀 광맥,
보물, 완료 보상을 미리 보여주지 않는다.

## 3. 전체 에셋 목록

### 광맥 5종

| ID | 모티프 |
|---|---|
| `Vein_blue` | 각진 광석 결정 세 개 |
| `Vein_crystal` | 단일 면체 수정과 작은 파편 |
| `Vein_vault` | 브라스 모서리의 고대 금고 |
| `Vein_resonance` | 중심석 주위의 각진 공명 고리 |
| `Vein_abyss` | 암반을 가르는 수직 심연 균열 |

논리 크기 32×32, 불투명.

### 장비 9종

드릴, 카트, 램프에 아래 티어를 각각 적용한다.

| 티어 | 레벨 | 형태 규칙 |
|---|---:|---|
| 1 | 1–20 | 기본 몸체와 최소 부품 |
| 2 | 21–40 | 보강재, 렌즈, 기어 또는 바퀴 추가 |
| 3 | 41–60 | 중장비 실루엣과 복수 핵심 부품 |

ID는 `Equipment_{drill,cart,lamp}_tier{1,2,3}`. 논리 크기 32×32, 불투명.

### 테마 장면 4종

| ID | 구조 |
|---|---|
| `ThemeScene_entry` | 층상 암반, 목재 지지대, 휴면 수직갱 |
| `ThemeScene_crystal` | 셰일 속 밝은 결정 지질, 사각 보강재 |
| `ThemeScene_ruins` | 매몰 기계, 부서진 기어, 고대 기둥 |
| `ThemeScene_abyss` | 거대한 암흑 공백, 희박한 절벽 모서리 |

논리 크기 192×108, 불투명. 화면 중앙과 하단은 텍스트를 위해 절제한다.

### 장식 4종

`Decoration_marker`, `Decoration_rail`, `Decoration_lamp`,
`Decoration_cart`. 논리 크기 32×32, 이진 투명.

### 광부 계획 변형 2종

- `MinerPlan_deep`: 웅크린 실루엣, 짧은 대각선 곡괭이.
- `MinerPlan_survey`: 선 자세, 전방 탐사 램프.

논리 크기 24×24, 이진 투명. 안전 계획은 기존 `MinerSprite`를 유지한다.

### Dynamic Island 배너 4종

`DIBanner_{entry,crystal,ruins,abyss}`. 논리 크기 192×72, 불투명.
최종 크롭 기준 상단 중앙 너비 36%, 높이 45%는 카메라 영역으로 비운다.

### StandBy 배경 4종

`StandBy_{entry,crystal,ruins,abyss}`. 논리 크기 256×144, 불투명.
좌측 1/3은 시간·진행 UI를 위한 저정보 석탄 영역, 우측 1/4은 상태 텍스트를
위한 절제 영역으로 유지한다.

### 자원 3종

`Resource_ore`, `Resource_crystal`, `Resource_coreShard`.
논리 크기 32×32, 불투명.

### 영구 업그레이드 3종

| ID | 모티프 |
|---|---|
| `PermanentUpgrade_excavationMemory` | 광부 헬멧과 층상 기억판 |
| `PermanentUpgrade_resonanceDetection` | 수정 위의 각진 튜닝 포크 |
| `PermanentUpgrade_compressedTime` | 암반판 사이에 압축된 모래시계 |

논리 크기 32×32, 불투명.

### 온보딩 2종

- `Onboarding_blocks`: 네 개의 집중 블록으로 쌓은 갱도 벽.
- `Onboarding_sessions`: 세 갱도 구간을 순차 통과하는 광부.

논리 크기 96×96, 불투명.

## 4. 후처리 및 검증

모든 리사이즈는 nearest-neighbor로 수행한다. 에셋 카탈로그에는 논리 크기의
1x, 2x, 3x PNG를 넣고 `Contents.json`에서 각 파일과 배율을 명시한다.

```bash
/Users/tofu/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  scripts/process_game_assets.py

/Users/tofu/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  scripts/process_game_assets.py --validate-only
```

검증기는 다음을 실패 처리한다.

- 40개 ID 또는 고유 원본 SHA 누락
- PNG가 아닌 원본/산출물
- 선언된 1x/2x/3x 크기 불일치
- 네 안료 밖의 RGB
- 브라스 10% 이상
- 투명 스프라이트의 부분 알파 또는 불투명 장면의 알파
- 불완전한 `Contents.json`

시각 검증 산출물:

- `artifacts/imagegen/game-assets-v1/contact-sheet-compact.png`
- `artifacts/imagegen/game-assets-v1/contact-sheet-scenes.png`
- `artifacts/imagegen/game-assets-v1/safe-zone-overlays.png`

실제 Dynamic Island와 StandBy Night Mode 가독성은 실기기 확인 전까지
`미검증(실기기 필요)`로 기록한다.
