# Rock Face Art Prompts

- 목적: 클리커의 중심 객체인 암반과 파괴 연출 24종을 외부 이미지 생성기로 만들기 위한 프롬프트
- 출력 형식: **PNG only. SVG 금지.**
- 기준 문서: `DESIGN.md` (네 안료), `docs/PIXEL_ART_PROMPTS.md`, `docs/ACHIEVEMENT_ART_PROMPTS.md`
- 후처리: `scripts/process_game_assets.py` (양자화 → 최근접 리사이즈 → 팔레트 검증)
- 코드 연결: `DeepMineProbe/Shared/GameArtCatalog.swift`

## 0. 지금 어떻게 동작하는가

**이 문서의 이미지가 하나도 없어도 게임은 돌아간다.** 각 슬롯은 자산이 없으면 절차적
플레이스홀더를 그리고, 자산 카탈로그에 해당 이름의 imageset이 들어오는 순간 실제 이미지로
바뀐다.

교체 절차는 이것뿐이다:

1. 아래 표의 `Asset` 이름으로 imageset을 `SharedAssets.xcassets`에 추가
2. 다시 실행

**코드 수정은 없다.** `GameArtCatalog`가 이름을 소유하고 `GameArtView`가 설치 여부를
확인하므로, 특정 자산 이름을 아는 뷰가 하나도 없다.

`ID`는 이 문서의 프롬프트와 코드의 슬롯을 잇는 열쇠이며 `GameArtEntry.promptID`와
정확히 일치한다. `GameArtCatalogTests`가 양쪽이 어긋나면 실패한다.

---

## 1. 공통 스타일 블록

**모든 프롬프트 앞에 이 블록을 그대로 붙인다.**

```
A single game art sprite, 1:1 square, centered subject on a solid flat background.

Strict palette — use ONLY these four colors, no other hues, no gradients
between different hues:
  coal black    #10100F  (background, outlines, shadow, deep cavities)
  shale grey    #373630  (mid tone, the body of stone)
  limestone     #E7E0CF  (highlight, freshly broken surface, light)
  lamp brass    #C58C39  (the single accent — use sparingly, on one focal element only)

Style: chunky pixel art, hand-placed pixels, hard 1-pixel edges, no
anti-aliasing, no soft shadows, no glow, no bloom, no bevel, no gloss.
Readable as a silhouette at 64x64 pixels. Bold simple shapes, thick forms,
heavy weight. Flat 2D, straight-on front view, no perspective, no 3/4 view,
no isometric.

Background: solid #10100F, completely flat, no texture, no vignette, no border
frame, no ring, no medallion.

Do NOT include: text, letters, numbers, watermarks, signatures, UI chrome,
drop shadows, gradients, neon, cyan, magenta, purple, green, red, blue, teal,
glass, chrome, plastic, 3D render, photorealism, cel shading, anime, sticker
outline, white border, cracks glowing with light.

Mood: dense cold rock underground. Heavy, tactile, silent. Stone that has never
seen the sun.
```

---

## 2. 단계 표현 규칙

암반 4단계는 **같은 바위 + 손실 누적**이다. 새 바위를 그리는 것이 아니라 같은 바위가
부서져 가는 것이며, 실루엣이 단계마다 확실히 달라야 한다.

| 단계 | 남은 내구도 | 표현 |
|---|---|---|
| 1 | 100–75% | 온전한 덩어리. 균열 없음 |
| 2 | 75–50% | 표면 균열, 모서리 한 곳 결손 |
| 3 | 50–25% | 깊은 균열이 관통, 큰 조각 두 곳 결손, 석회석 단면 노출 |
| 4 | 25–0% | 반쯤 무너진 잔해. 원형 실루엣 붕괴, 석회석 단면이 가장 넓게 노출 |

**결정적으로**: 단계가 올라갈수록 `limestone`(갓 부서진 단면)이 늘어난다. 이것이 진행을
읽는 단서다. 색을 바꾸지 말고 면적을 늘린다.

지역 4종은 **같은 4단계 구조에 암질만 다르다.**

| 지역 | 암질 축 |
|---|---|
| entry | 평범한 퇴적암. 층리가 수평으로 보임 |
| crystal | 결정이 박힌 암반. 각진 석회석 결정면이 표면에 돌출 |
| ruins | 가공된 석재. 인공적인 직선 모서리와 놋쇠 리벳 |
| abyss | 공허에 가까운 흑암. 표면이 거의 석탄색, 균열 속이 완전한 무 |

---

## 3. 개별 프롬프트

각 항목의 문장을 §1 블록 **뒤에** `Subject:` 로 붙인다.

### 3.1 입구 암반 (entry)

| ID | Asset | Subject |
|---|---|---|
| `rockface-entry-1` | `RockFace_entry_stage1` | `Subject: a single massive boulder of layered sedimentary rock, roughly round, filling the frame. Horizontal shale grey strata bands across its face. Surface unbroken, no cracks. A few limestone flecks in the upper bands.` |
| `rockface-entry-2` | `RockFace_entry_stage2` | `Subject: the same layered sedimentary boulder, now with a network of thin surface cracks across the upper half and one corner chipped away, exposing a small patch of pale limestone interior.` |
| `rockface-entry-3` | `RockFace_entry_stage3` | `Subject: the same layered boulder, now split by one deep crack running fully through it, with two large chunks missing from opposite edges. Broad pale limestone fracture surfaces exposed where the chunks broke away.` |
| `rockface-entry-4` | `RockFace_entry_stage4` | `Subject: the same boulder collapsed into a low heap of broken layered fragments, the round silhouette gone. Wide pale limestone fracture faces on every piece, coal black gaps between them.` |

### 3.2 결정 암반 (crystal)

| ID | Asset | Subject |
|---|---|---|
| `rockface-crystal-1` | `RockFace_crystal_stage1` | `Subject: a massive shale grey boulder with angular limestone crystals embedded in and protruding from its surface, filling the frame. Surface unbroken. One crystal tipped with brass.` |
| `rockface-crystal-2` | `RockFace_crystal_stage2` | `Subject: the same crystal-studded boulder, now with surface cracks radiating from the crystal clusters and one corner broken off, exposing more embedded crystal cross-sections.` |
| `rockface-crystal-3` | `RockFace_crystal_stage3` | `Subject: the same crystal-studded boulder, split by a deep crack that runs through a crystal cluster, two large chunks missing, dense limestone crystal cross-sections exposed across the broken faces.` |
| `rockface-crystal-4` | `RockFace_crystal_stage4` | `Subject: the same boulder collapsed into a heap of broken fragments with loose angular limestone crystals scattered among them, one crystal brass-tipped. Coal black gaps between the pieces.` |

### 3.3 유적 암반 (ruins)

| ID | Asset | Subject |
|---|---|---|
| `rockface-ruins-1` | `RockFace_ruins_stage1` | `Subject: a large block of worked masonry, straight cut edges and a flat face, shale grey, with four brass rivets set in a square pattern. Surface intact, faint tool marks.` |
| `rockface-ruins-2` | `RockFace_ruins_stage2` | `Subject: the same masonry block, now cracked across its flat face along the mortar line, one squared corner broken off exposing pale limestone core, one brass rivet loose and tilted.` |
| `rockface-ruins-3` | `RockFace_ruins_stage3` | `Subject: the same masonry block, deeply fractured through the middle, two large squared chunks missing, broad limestone fracture faces exposed, two brass rivets gone leaving empty holes.` |
| `rockface-ruins-4` | `RockFace_ruins_stage4` | `Subject: the same masonry block collapsed into a pile of squared rubble, the straight silhouette destroyed, limestone fracture faces on every piece, a single bent brass rivet lying on top.` |

### 3.4 심연 암반 (abyss)

| ID | Asset | Subject |
|---|---|---|
| `rockface-abyss-1` | `RockFace_abyss_stage1` | `Subject: a massive boulder of near-black stone, almost the same value as the background, its form defined only by a thin limestone rim light along the upper edge. Surface unbroken and utterly smooth.` |
| `rockface-abyss-2` | `RockFace_abyss_stage2` | `Subject: the same near-black boulder, now with thin cracks across it whose interiors are pure void black, darker than the stone itself. One corner missing, its fracture face a stark pale limestone against the blackness.` |
| `rockface-abyss-3` | `RockFace_abyss_stage3` | `Subject: the same near-black boulder split by a deep crack opening into complete emptiness, two large chunks missing, their pale limestone fracture faces the brightest thing in the frame.` |
| `rockface-abyss-4` | `RockFace_abyss_stage4` | `Subject: the same boulder collapsed into scattered near-black fragments with wide pale limestone fracture faces, the gaps between the pieces reading as bottomless void rather than shadow.` |

### 3.5 균열 오버레이 (fracture)

암반 위에 합성되는 투명 배경 오버레이다. **배경은 완전 투명**이며 §1 블록의 배경 지시를
`Background: fully transparent, alpha zero, no background fill at all.` 로 바꾼다.

| ID | Asset | Subject |
|---|---|---|
| `fracture-light` | `Fracture_light` | `Subject: a single thin jagged crack line running from top to bottom, slightly branching once near the middle, drawn in coal black with a one-pixel limestone highlight on its left side. Nothing else in the frame.` |
| `fracture-medium` | `Fracture_medium` | `Subject: three jagged crack lines radiating from a shared point slightly above center, each branching once, drawn in coal black with one-pixel limestone highlights. Nothing else in the frame.` |
| `fracture-heavy` | `Fracture_heavy` | `Subject: a dense web of five jagged cracks radiating from a shattered point at center, heavily branched, the center opening into a small coal black hole. One-pixel limestone highlights along the crack edges. Nothing else in the frame.` |

### 3.6 약점과 파편 (target and debris)

| ID | Asset | Subject |
|---|---|---|
| `weakpoint-idle` | `WeakPoint_idle` | `Subject: a brass targeting ring, a thick open circle with four short tick marks at the compass points and a small solid brass dot at its center. Nothing inside the ring but background.` |
| `weakpoint-hit` | `WeakPoint_hit` | `Subject: a brass targeting ring struck and breaking outward, the circle fractured into four arc segments pushed apart, a solid brass burst filling the center, short limestone impact spikes radiating outward.` |
| `debris-small` | `Debris_small` | `Subject: three small angular stone chips of different shapes, shale grey with pale limestone fracture faces, arranged loosely as if mid-flight, not touching each other.` |
| `debris-large` | `Debris_large` | `Subject: two large angular stone chunks and two small chips, shale grey with broad pale limestone fracture faces, arranged loosely as if mid-flight, not touching each other.` |

### 3.7 공명 결절 (resonance node)

클리커의 golden cookie에 해당한다. 화면에서 유일하게 "지금 눌러라"라고 말하는 물체이므로
놋쇠를 다른 어떤 자산보다 넓게 쓴다.

| ID | Asset | Subject |
|---|---|---|
| `resonance-node` | `ResonanceNode` | `Subject: a fist-sized brass geode hovering above a small shale plinth, its faceted brass surface catching flat limestone highlights on the upper facets, three concentric brass rings orbiting it at different angles. The brightest and most brass-heavy object possible within the four-color limit.` |

---

## 4. 후처리와 검증

`docs/ACHIEVEMENT_ART_PROMPTS.md` §4와 동일하다.

1. 생성된 PNG를 `artifacts/art/raw/`에 원본 그대로 보관
2. `scripts/process_game_assets.py`로 네 안료 양자화 → 64×64 최근접 축소 → `@2x`, `@3x` 생성
3. 팔레트 검증이 위반 0을 보고해야 편입한다. 237장이 이 관문을 통과했고 예외는 없었다

균열 오버레이 3종은 알파를 보존해야 하므로 양자화 시 투명 채널을 별도 처리한다.

---

## 5. 진행 상황 확인

설치되지 않은 슬롯은 `GameArtAvailability.missingEntries`가 돌려준다.

**아직 이것을 보여주는 화면은 없다.** 디버거나 테스트 로그에서 확인하는 API이고, 진단
화면에 노출하는 것은 별도 작업이다. 24장이 전부 비어 있는 동안에는 화면 자체가 플레이스홀더
투성이라 목록이 필요 없고, 절반쯤 채워졌을 때 넣는 것이 맞다.
