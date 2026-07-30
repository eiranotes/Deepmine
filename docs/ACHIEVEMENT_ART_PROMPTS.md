# Achievement Badge Art Prompts

- 목적: 도전과제 35종의 배지 이미지를 외부 이미지 생성기(ChatGPT)로 만들기 위한 프롬프트
- 출력 형식: **PNG only. SVG 금지.**
- 기준 문서: `DESIGN.md` (네 안료), `docs/PIXEL_ART_PROMPTS.md` (기존 픽셀 아트 규칙)
- 후처리: 생성 후 아래 §4의 양자화·리사이즈를 거쳐 Asset Catalog에 편입한다

---

## 1. 공통 스타일 블록

**모든 프롬프트 앞에 이 블록을 그대로 붙인다.** 개별 프롬프트는 이 블록의 피사체만 바꾼다.

```
A single game achievement badge icon, 1:1 square, centered subject on a solid
flat background.

Strict palette — use ONLY these four colors, no other hues, no gradients
between different hues:
  coal black    #10100F  (background, outlines, shadow)
  shale grey    #373630  (mid tone, stone, metal body)
  limestone     #E7E0CF  (highlight, light, bright surface)
  lamp brass    #C58C39  (the single accent — use sparingly, on one focal element only)

Style: chunky pixel art, hand-placed pixels, hard 1-pixel edges, no
anti-aliasing, no soft shadows, no glow, no bloom, no bevel, no gloss.
Readable as a silhouette at 48x48 pixels. Bold simple shapes, thick forms,
generous negative space. Flat 2D, straight-on front view, no perspective,
no 3/4 view, no isometric.

Background: solid #10100F, completely flat, no texture, no vignette,
no border frame, no ring, no circular medallion shape unless the subject
itself is a ring.

Do NOT include: text, letters, numbers, roman numerals, watermarks, signatures,
UI chrome, drop shadows, gradients, neon, cyan, magenta, purple, green, red,
blue, teal, glass, chrome, plastic, 3D render, photorealism, cel shading,
anime, sticker outline, white border.

Mood: worn industrial mining equipment. Heavy, tactile, quiet. Like a stamped
brass tool tag that has been in a coal mine for decades.
```

**왜 이 제약인가**: 앱·위젯·Live Activity가 D-013의 네 안료만 쓴다. 배지가 다른 색을 들고
오면 화면에서 유일하게 튀는 요소가 되고, StandBy Night Mode의 적색 단색에서 형태가
무너진다. 48px 판독성은 목록 행에서 실제로 쓰이는 크기다.

---

## 2. 계열별 시각 언어

같은 계열은 한눈에 묶여 보여야 하고, 계열 간에는 구분돼야 한다. 티어(동일 계열의 단계)는
**같은 피사체 + 복잡도 증가**로 표현한다. 색을 바꾸지 않는다.

| 계열 | 피사체 축 | 티어 표현 |
|---|---|---|
| 첫 걸음 | 광부의 첫 도구 | 도구 종류가 다름 |
| 쌓인 집중 | 광석 더미 / 광차 | 더미가 커짐 |
| 심도 | 수직 갱도 단면 | 갱도가 길어짐 |
| 꾸준함 | 램프 불꽃 | 불꽃이 커지고 램프가 정교해짐 |
| 광맥 도감 | 결정 원석 | 결정 수가 늘어남 |
| 장비 장인 | 드릴 비트 | 톱니·부품이 늘어남 |
| 갱도 문 | 봉인된 문 | 자물쇠·리벳이 늘어남 |

---

## 3. 개별 프롬프트

각 항목의 문장을 §1 블록 **뒤에** `Subject:` 로 붙인다.

### 첫 걸음 (firstSteps)

| ID | Subject |
|---|---|
| `first.return` | `Subject: a single miner's pickaxe standing upright, blade planted in a small pile of rubble. The pickaxe head is brass, the handle is shale grey. One small limestone highlight on the blade edge.` |
| `first.deep` | `Subject: a narrow vertical mine shaft opening seen head-on, framed by two heavy timber posts. Deep coal-black void in the center. A single brass warning wedge at the top of the frame.` |
| `first.survey` | `Subject: a surveyor's hand lantern with a wide flared glass, casting a flat limestone cone of light downward. Lantern body shale grey, brass ring at the top.` |
| `first.prestige` | `Subject: a brass core fragment, an angular broken shard with faceted edges, floating above a small shale pedestal. The shard is the only brass element.` |

### 쌓인 집중 (accumulation)

| ID | Subject |
|---|---|
| `focus.10h` | `Subject: three small chunks of ore stacked in a low pile. Shale grey stones with one brass-flecked stone on top.` |
| `focus.50h` | `Subject: a knee-high mound of ore chunks, roughly a dozen stones, two of them brass-flecked.` |
| `focus.100h` | `Subject: a wooden mine cart, side view, filled level with ore chunks. Cart body shale grey with brass corner brackets, iron wheels below.` |
| `focus.250h` | `Subject: two stacked mine carts overflowing with ore, the upper cart tilted. Brass brackets on both carts.` |
| `focus.500h` | `Subject: a tall ore silo built of riveted metal plates, brass rivets in vertical rows, a chute at the base spilling a few ore chunks.` |
| `sessions.25` | `Subject: a row of five short tally marks carved into a stone slab, deep chiselled grooves. The fifth groove is brass-filled.` |
| `sessions.100` | `Subject: a stone slab densely covered in carved tally grooves in four neat rows, a few grooves brass-filled.` |
| `sessions.500` | `Subject: a thick stone tablet worn smooth at the edges, its whole face covered in tally grooves, a heavy brass corner cap.` |

### 심도 (depth)

| ID | Subject |
|---|---|
| `depth.crystal` | `Subject: a vertical cross-section of a mine shaft, two levels deep, with a cluster of angular crystals embedded in the shale wall of the lower level. Crystals are limestone with brass tips.` |
| `depth.ruins` | `Subject: a vertical cross-section of a mine shaft, three levels deep, the lowest level opening into a buried stone archway with carved blocks. One brass keystone in the arch.` |
| `depth.abyss` | `Subject: a vertical cross-section of a mine shaft, four levels deep, the lowest level opening into an enormous black void with no floor. A single brass lamp hangs at the edge of the void.` |
| `depth.5000` | `Subject: a plumb line on a brass reel, its cord dropping straight down past five stacked rock strata layers, the cord vanishing into darkness at the bottom.` |
| `depth.20000` | `Subject: a brass depth gauge dial, a heavy circular instrument with a single needle pointing straight down at the bottom of its arc, mounted on a shale plate with rivets.` |

### 꾸준함 (discipline)

| ID | Subject |
|---|---|
| `streak.3` | `Subject: a small oil lamp with a single short brass flame, body shale grey. The flame is the only brass element.` |
| `streak.7` | `Subject: a miner's safety lamp with a wire cage around a taller brass flame, brass base, shale cage.` |
| `streak.14` | `Subject: a large hanging pit lamp on a hook, a broad brass flame inside a riveted glass housing, casting a flat limestone glow.` |
| `streak.30` | `Subject: a monumental brass beacon lamp on a riveted stone pedestal, a wide steady brass flame, limestone light spilling in a flat fan across the base.` |
| `goal.30days` | `Subject: a paper work tally card pinned to a shale board, punched with a neat grid of small holes, one brass pin in the corner.` |
| `goal.100days` | `Subject: a thick stack of punched work tally cards bound with a brass clip, edges worn and curling.` |

### 광맥 도감 (codex)

| ID | Subject |
|---|---|
| `vein.first` | `Subject: a single angular crystal shard embedded in a broken chunk of shale rock, the crystal limestone with one brass facet.` |
| `vein.all5` | `Subject: five distinct angular crystal shards of different shapes arranged in a row on a shale display slab, each shard limestone, brass tips varying in size.` |
| `vein.25` | `Subject: an open field notebook lying flat, its two pages showing pressed crystal specimens held by brass corner tabs. No writing, no text, only specimen shapes.` |
| `vein.100` | `Subject: a heavy specimen cabinet with nine open square drawers in a 3x3 grid, each drawer holding one angular crystal. Brass drawer pulls, shale cabinet body.` |

### 장비 장인 (craft)

| ID | Subject |
|---|---|
| `drill.10` | `Subject: a single spiral drill bit standing upright, shale steel with a brass collar at the base.` |
| `drill.20` | `Subject: a hand drill assembly, a spiral bit joined to a geared crank housing, two visible brass gear teeth rings.` |
| `drill.40` | `Subject: a heavy pneumatic rock drill with a thick spiral bit, a riveted body and two brass pressure valves.` |
| `drill.60` | `Subject: an enormous industrial tunnel boring head seen head-on, a broad circular plate studded with radial cutting teeth, brass hub at the center, shale teeth.` |
| `crew.balanced20` | `Subject: three mining tools crossed together in a fan, a pickaxe, a spiral drill bit and a lantern, bound at the crossing point by a brass band.` |

### 갱도 문 (sealed)

| ID | Subject |
|---|---|
| `sealed.25` | `Subject: a closed timber mine door set in a stone frame, a single brass latch across the middle.` |
| `sealed.100` | `Subject: a heavy riveted metal mine door, closed, with three horizontal brass bars across it and rivets along the edges.` |
| `sealed.300` | `Subject: a massive vault-like mine door, closed, with a central brass wheel lock and concentric riveted rings, deeply worn shale metal.` |

---

## 4. 후처리 (필수)

생성 원본은 그대로 쓰지 않는다. `docs/PIXEL_ART_PROMPTS.md`의 기존 파이프라인과 동일하게
처리한다.

1. **양자화**: 네 안료 hex로 정확히 양자화한다. 생성기는 반드시 중간색을 만들므로 이 단계가
   없으면 D-013 팔레트 계약이 깨진다.
2. **리사이즈**: 96×96 논리 그리드로 최근접(nearest neighbor) 축소한 뒤 48/96/144 PNG 3종을
   내보낸다. 부드러운 보간을 쓰면 픽셀 아트가 아니게 된다.
3. **알파**: 배경 `#10100F`를 투명으로 뺄지 유지할지는 목록 행 배경과 같으므로 **유지**한다.
   투명 처리하면 다크 이외 환경에서 테두리가 드러난다.
4. **판독 검증**: 48×48로 축소한 상태에서 계열이 구분되는지, 브래스 초점이 하나인지 확인한다.
   실패하면 프롬프트의 피사체를 더 단순하게 바꾼다.
5. **편입**: `SharedAssets.xcassets`에 `AchievementBadge_<id>` 이름으로 넣고
   `.interpolation(.none)`으로 렌더한다.

## 5. 검수 체크리스트

- [ ] 네 안료 외 색이 없다 (스크립트로 hex 검사)
- [ ] 브래스가 한 요소에만 쓰였다
- [ ] 텍스트·숫자·로마숫자가 없다
- [ ] 48px에서 계열이 구분된다
- [ ] 같은 계열의 티어가 색이 아니라 복잡도로 구분된다
- [ ] 원형 메달 프레임이 강제로 씌워지지 않았다
- [ ] SVG가 아니라 PNG다
