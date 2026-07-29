# DeepMine 픽셀 아트 에셋 프롬프트 팩

- 대상 파이프라인: ComfyUI (Illustrious XL / NoobAI XL) + Aseprite 후처리
- 문서 버전: v1.0 (Spec v0.2 기준)

---

# 0. 먼저 정직하게

SDXL 계열은 **진짜 픽셀 아트를 못 그립니다.** "pixel art" 태그를 넣어도 나오는 건 픽셀 아트처럼 보이는 안티에일리어싱된 일러스트입니다. 그리드가 안 맞고, 픽셀 크기가 제각각이고, 팔레트가 수백 색입니다.

따라서 용도를 나눕니다.

| 에셋 | 방식 | 이유 |
|---|---|---|
| 24pt 아이콘, 스프라이트 (DI/위젯) | **손으로 찍기 (Aseprite)** | 48×48px에서 AI는 무조건 진다. 30분이면 끝남 |
| 지역 배경, StandBy 배너, 스토어 아트 | **AI 생성 → 다운스케일 → 팔레트 양자화 → 손보정** | 큰 화면이라 AI 우위 |
| 컨셉 탐색 | **AI 대량 생성** | 방향 잡는 용도 |

아래 프롬프트는 그 전제로 씁니다.

---

# 1. 공통 팔레트 (모든 에셋 고정)

기존 하우스 스타일을 광산 테마로 확장했습니다.

```text
배경심연   #0e0e0f
암반농     #1a1a1e
암반중     #2e2e36
암반담     #4a4a58
금속       #6b6b7a
하이라이트 #b9b9c8
자수정     #7c6aff   (accent)
공명       #40e0c8   (accent2)
용암       #ff6b4a   (경고/붕괴)
램프광     #ffc857   (광부 조명)
```

**11색 고정.** 이 이상 늘리지 않습니다. 후처리 양자화의 목표 팔레트로 그대로 씁니다.

## 1.1 명도 규칙 — 가장 중요

StandBy Night Mode는 화면 전체를 **적색 단색**으로 바꿉니다. 색상 정보가 전부 사라집니다.

> **모든 에셋은 그레이스케일로 변환했을 때도 형태가 읽혀야 한다.**

작업 중 수시로 Aseprite의 그레이스케일 미리보기를 켜서 확인하세요. 자수정(#7c6aff)과 공명(#40e0c8)은 명도가 비슷해서, 둘을 인접시키면 Night Mode에서 한 덩어리로 뭉갭니다. 반드시 암반담(#4a4a58) 같은 중간 명도를 사이에 끼우세요.

---

# 2. 손으로 찍는 에셋 (AI 미사용)

AI에게 시키지 말고 직접 찍으세요. 사양만 정리합니다.

## 2.1 광부 스프라이트 — Dynamic Island Compact Leading

| 항목 | 값 |
|---|---|
| 논리 크기 | 24×24pt |
| 실제 파일 | 48×48px (@2x), 72×72px (@3x) |
| 픽셀 그리드 | 24×24 셀 (@2x에서 셀당 2px) |
| 사용 색 | 최대 5색 |
| 배경 | 투명 |

**형태 요구사항**: 24pt는 손톱만 합니다. 디테일을 넣지 말고 **실루엣으로 승부**하세요.
- 헬멧 램프 1픽셀 (램프광 #ffc857) — 유일한 밝은 점, 시선을 잡음
- 몸통은 단색 덩어리
- 곡괭이는 대각선 3~4픽셀

**변형 3종 (채굴 계획별)**
| 계획 | 차이 |
|---|---|
| 안전 갱도 | 램프광 노랑, 헬멧 있음 |
| 심층 갱도 | 램프 자수정(#7c6aff), 실루엣 약간 웅크림 |
| 탐사 갱도 | 램프 공명(#40e0c8), 손에 램프 추가 |

## 2.2 상태 아이콘 (24×24pt, 각 4색 이내)

| 상태 | 모티프 |
|---|---|
| 채굴 중 | 곡괭이 |
| 완료 | 광석 상자 |
| 붕괴 | 금 간 암반 + 용암색 1픽셀 |
| 광맥 발견 | 4방향 반짝임 |
| 스트릭 | 램프 불꽃 |

## 2.3 장비 아이콘 (32×32pt, 레벨 구간별 3단계)

드릴 / 카트 / 램프 각각 LV.1-7, LV.8-14, LV.15-20 구간에서 형태가 바뀝니다. 크기를 키우지 말고 **부품을 추가**하는 방식으로 성장을 표현하세요 (드릴에 톱니 추가, 카트에 바퀴 추가, 램프에 렌즈 추가).

---

# 3. AI 생성 에셋

## 3.1 ComfyUI 파이프라인

```text
1. SDXL 생성          1024×1024 또는 1344×768
2. Image Resize       nearest-neighbor, 목표 픽셀 해상도로 축소
                      (배경 128×72, 배너 192×64 등)
3. Image Quantize     §1 팔레트 11색 지정
4. Image Resize       nearest-neighbor로 정수배 확대
5. Aseprite           경계 정리, 디더링 수동 조정
```

축소 단계에서 lanczos/bilinear를 쓰면 픽셀이 뭉개집니다. **반드시 nearest**입니다.

권장 설정: CFG 5~6, Steps 28~32, Sampler `dpmpp_2m` + `karras`.

## 3.2 공통 프롬프트 접두/접미

**Positive 접두** (모든 프롬프트 앞에 붙임)
```text
pixel art, 16-bit era sprite, limited palette, dark background,
crisp pixel edges, no anti-aliasing, orthographic side view,
high value contrast, readable silhouette,
```

**Negative** (모든 프롬프트 공통)
```text
blurry, anti-aliased, gradient, soft shading, photorealistic,
3d render, text, watermark, signature, jpeg artifacts,
low contrast, muddy colors, glowing bloom, lens flare,
modern ui, realistic lighting, depth of field
```

---

## 3.3 지역 배경 5종 — 잠금화면 / StandBy 용

### 지역 1. 흙과 돌 (0~100m)

```text
pixel art, 16-bit era sprite, limited palette, dark background,
crisp pixel edges, no anti-aliasing, orthographic side view,
high value contrast, readable silhouette,
underground mine tunnel cross-section, packed earth and grey stone strata,
wooden support beams, a single hanging lantern casting warm yellow light,
scattered small rocks, dark void at center of composition,
muted grey and brown palette with one warm yellow accent,
side-scroller game background, empty center space for UI overlay
```

### 지역 2. 철광 갱도 (100~500m)

```text
[공통 접두]
underground iron ore mine, rusted metal rails running horizontally,
mine cart tracks, exposed iron veins with dull metallic sheen,
riveted steel support arches, cold grey and steel blue palette,
one warm lantern accent, dark void at center,
side-scroller game background, empty center space for UI overlay
```

### 지역 3. 푸른 수정층 (500~1,500m)

```text
[공통 접두]
underground crystal cavern, large violet and cyan crystal formations
growing from dark rock walls, faint inner glow within crystals,
deep purple and teal palette on near-black rock,
mid-tone grey rock separating the violet and cyan clusters,
dark void at center, side-scroller game background,
empty center space for UI overlay
```

> 자수정과 공명색이 붙지 않도록 프롬프트에 중간 명도 암석을 명시했습니다. Night Mode 대응.

### 지역 4. 고대 기계층 (1,500~5,000m)

```text
[공통 접두]
ancient buried machinery chamber, colossal rusted gears embedded in rock,
brass pipes and geometric mechanical patterns, dormant machine core,
faint violet energy lines tracing along metal seams,
dark bronze and gunmetal palette, dark void at center,
side-scroller game background, empty center space for UI overlay
```

### 지역 5. 검은 심연 (5,000m+)

```text
[공통 접두]
abyssal void chamber deep underground, almost entirely black,
faint outlines of impossibly large structures barely visible,
thin violet rim light defining edges only, oppressive emptiness,
near-monochrome black palette with minimal violet rim accent,
dark void at center, side-scroller game background,
empty center space for UI overlay
```

---

## 3.4 Dynamic Island Expanded 배너

- 논리 크기 371×144pt → 픽셀 캔버스 **192×72px** 작업 후 정수배 확대
- **중앙 상단은 반드시 비웁니다** (TrueDepth 카메라 영역)

```text
[공통 접두]
horizontal mine tunnel cross-section banner, very wide aspect ratio,
tunnel entrance on the left, deep dark shaft opening at center,
crystal vein visible on the right, tiny miner silhouette on the left,
strong horizontal composition, near-black background,
completely empty space at top center,
game hud banner art, ultrawide
```

## 3.5 StandBy 전체화면 아트

- 가로 전체화면. 픽셀 캔버스 **256×144px** 작업 후 확대
- 좌측 1/3은 UI(시간·심도·진행바)가 덮으므로 **정보 없는 어두운 영역**으로 비웁니다

```text
[공통 접두]
wide underground mine scene, deep vertical shaft descending into darkness
on the right side, layered rock strata visible in cross-section,
tiny miner with lantern standing at a ledge,
left third of the image is dark empty rock with no detail,
strong value contrast readable in grayscale,
night-mode friendly, monochrome-safe composition,
16:9 game background
```

## 3.6 광맥 아이콘 5종

64×64px 캔버스, 각 4색 이내. AI로 컨셉만 뽑고 손으로 다듬으세요.

| 광맥 | 프롬프트 코어 |
|---|---|
| 푸른 광맥 | `single violet crystal cluster icon, centered, black background` |
| 수정 광맥 | `single cyan gemstone icon, faceted, centered, black background` |
| 고대 금고 | `small ancient metal chest icon, brass fittings, centered, black background` |
| 공명층 | `concentric resonance rings icon, cyan, centered, black background` |
| 심연 균열 | `jagged dark fissure icon, violet rim light, centered, black background` |

각 프롬프트 앞에 공통 접두, 뒤에 `game item icon, 32x32 sprite, flat, no perspective`를 붙입니다.

---

## 3.7 앱 아이콘

```text
[공통 접두]
app icon, single mine shaft entrance viewed head-on,
perfect circular black void at center, stone arch framing it,
one small violet crystal at the top of the arch,
symmetrical composition, bold simple shapes,
extremely high contrast, readable at 40x40 pixels,
flat design, no text
```

앱 아이콘은 40×40pt에서도 읽혀야 합니다. 생성 후 **반드시 40×40으로 축소해서 확인**하세요. 안 읽히면 요소를 더 줄이세요.

---

# 4. 파일 산출 규격

```text
Assets.xcassets/
├─ Miner/
│  ├─ miner-safe.imageset      (48/72px, 투명)
│  ├─ miner-deep.imageset
│  └─ miner-survey.imageset
├─ Status/                      (5종, 48/72px)
├─ Equipment/                   (3장비 × 3단계 = 9종, 64/96px)
├─ Vein/                        (5종, 64/96px)
├─ Zone/
│  ├─ zone-1-lockscreen         (@2x/@3x)
│  ├─ zone-1-standby            (@2x/@3x)
│  └─ ... 5지역
└─ Banner/
   └─ di-expanded-zone-1..5
```

**위젯 익스텐션에 에셋을 내장**하고, Live Activity ContentState에는 `themeID` 문자열만 넘깁니다 (4KB 제한).

---

# 5. 체크리스트

에셋 하나를 완성으로 판정하기 전에:

- [ ] 그레이스케일 변환 후에도 형태가 읽히는가
- [ ] 팔레트가 11색 이내인가
- [ ] 픽셀 그리드가 균일한가 (확대해서 1px 셀 크기 일치 확인)
- [ ] 안티에일리어싱된 중간색이 남아있지 않은가
- [ ] 24pt 아이콘: 실기기 Dynamic Island에서 무엇인지 인지되는가
- [ ] 배너: 중앙 상단이 비어 있는가
- [ ] StandBy 아트: 좌측 1/3이 비어 있는가
